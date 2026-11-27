#!/usr/bin/env bash
# The corpus of a spec: every answer the owner has given any run of it.
#
# Usage: corpus.sh settle <run-dir|transcript> --keep <id> --drop <id>...
#        corpus.sh settle <run-dir|transcript> --drop <id>...
#        corpus.sh segments <run-dir|transcript>
#        corpus.sh clashes <run-dir|transcript>
# Env:   EVALS_DIR (the eval home), PATH, HOME.
# A spec is its text (the first message of the run), not a run's name; its
# corpus is the segments (see corpus.jq) of every $EVALS_DIR/runs/*/ run of
# that text, plus the transcript on the command line when it is not one of
# them. Answers of a stand-in run are not the owner's and are left out; a
# replay's copies of earlier answers are left out (its replay.jsonl says
# which lines are copies).
# segments prints the effective corpus as a JSON array: the segments less every
# id the owner dropped when settling (the latest settled line naming an id
# decides it). settle records a choice in
# $EVALS_DIR/corpus/<sha256 of the spec>/settled.jsonl, nothing in any run
# directory. Nothing here runs a matcher or calls claude: it reads and writes
# files only. clashes prints the clashes in the target run directory's own
# clashes.jsonl, less what settling removed, ready to settle (nothing when
# there are none or the target is a transcript without a run directory).
# Exit: 0 done, 2 usage, an unknown subcommand (check is one: it
# is removed), a spec-less run, or an id that is not in the corpus.
# A run directory holding replayed-from.txt also counts the recorded transcript
# it names.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
USAGE="usage: corpus.sh segments <run-dir|transcript> | corpus.sh clashes <run-dir|transcript> | corpus.sh settle <run-dir|transcript> --keep <id> --drop <id>... | corpus.sh settle <run-dir|transcript> --drop <id>..."
E="${EVALS_DIR:?EVALS_DIR is not set}"

# jq finds a corpus.jq in the working directory before one on -L, and this
# script runs in the eval home: name the harness directory in the include.
INC="include \"corpus\" {search: \"$HERE\"};"

# spec_of <transcript> <prompt.txt or empty>: prints the spec text of a run,
# exits 1 when the run has none. The transcript says first; a headless run has
# no user record, so its prompt.txt does.
spec_of() {
  local spec
  if spec="$(jq -sje "$INC spec_text // empty" "$1"; printf x)" && [ "$spec" != x ]; then
    printf '%s' "${spec%x}"; return 0
  fi
  [ -r "$2" ] || return 1
  spec="$(jq -Rsje "$INC spec_of_prompt // empty" "$2"; printf x)" && [ "$spec" != x ] || return 1
  printf '%s' "${spec%x}"
}

# run_segments <name> <transcript> <run dir or empty>: the owner segments of
# one run as a JSON array. A run directory with standin.jsonl has none; one
# with replay.jsonl counts only the lines the owner typed.
run_segments() {
  local name="$1" transcript="$2" dir="$3"
  if [ -n "$dir" ] && [ -e "$dir/standin.jsonl" ]; then echo '[]'; return 0; fi
  if [ -n "$dir" ] && [ -r "$dir/replay.jsonl" ]; then
    jq -sc --arg run "$name" --slurpfile log <(jq -sc . "$dir/replay.jsonl") "$INC owner_segments(\$run; \$log[0])" "$transcript"
  else
    jq -sc --arg run "$name" "$INC owner_segments(\$run; null)" "$transcript"
  fi
}

# The run named on the command line: a run directory, or a transcript file
# (the transcript.jsonl of a run directory, or a recorded one named for the run).
TARGET="${2:-}"
[ -n "$TARGET" ] || { echo "$USAGE" >&2; exit 2; }
CMD="$1"
case "$CMD" in settle | segments | clashes) ;; *) echo "corpus.sh: unknown subcommand; $USAGE" >&2; exit 2 ;; esac
shift 2
if [ -d "$TARGET" ]; then TARGET="$TARGET/transcript.jsonl"; fi
[ -r "$TARGET" ] || { echo "corpus.sh: $TARGET is not readable" >&2; exit 2; }
TARGET="$(cd "$(dirname "$TARGET")" && pwd -P)/$(basename "$TARGET")"
if [ "$(basename "$TARGET")" = transcript.jsonl ]; then
  TARGET_NAME="$(basename "$(dirname "$TARGET")")"; TARGET_DIR="$(dirname "$TARGET")"
else
  TARGET_NAME="$(basename "$TARGET" .jsonl)"; TARGET_DIR=
fi

if ! SPEC="$(spec_of "$TARGET" "${TARGET_DIR:+$TARGET_DIR/prompt.txt}")"; then
  echo "corpus.sh: $TARGET_NAME has no spec; it is in no corpus" >&2
  exit 2
fi

# The runs of the spec: those under runs/, then the command line's own
# transcript, then the recorded transcript a replay's directory names in
# replayed-from.txt; each counts once, by real path.
SEGMENTS='[]'
COUNTED=
# add_run <name> <transcript> <run dir or empty>: adds the run's segments unless its transcript was counted.
add_run() {
  case "$COUNTED" in *"|$2|"*) return 0 ;; esac
  COUNTED="$COUNTED|$2|"
  SEGMENTS="$(jq -c --argjson more "$(run_segments "$1" "$2" "$3")" '. + $more' <<< "$SEGMENTS")"
}
for dir in "$E"/runs/*/; do
  [ -r "${dir}transcript.jsonl" ] || continue
  dir="$(cd "$dir" && pwd -P)"
  run_spec="$(spec_of "$dir/transcript.jsonl" "$dir/prompt.txt")" || continue
  [ "$run_spec" = "$SPEC" ] || continue
  add_run "$(basename "$dir")" "$dir/transcript.jsonl" "$dir"
done
add_run "$TARGET_NAME" "$TARGET" "$TARGET_DIR"
if [ -n "$TARGET_DIR" ] && [ -r "$TARGET_DIR/replayed-from.txt" ]; then
  RECORDED="$(head -n 1 "$TARGET_DIR/replayed-from.txt")"
  if [ -f "$RECORDED" ] && [ -r "$RECORDED" ]; then
    RECORDED="$(cd "$(dirname "$RECORDED")" && pwd -P)/$(basename "$RECORDED")"
    if [ "$(basename "$RECORDED")" = transcript.jsonl ]; then
      add_run "$(basename "$(dirname "$RECORDED")")" "$RECORDED" "$(dirname "$RECORDED")"
    else
      add_run "$(basename "$RECORDED" .jsonl)" "$RECORDED" ""
    fi
  fi
fi

SETTLED_DIR="$E/corpus/$(printf '%s' "$SPEC" | shasum -a 256 | cut -d' ' -f1)"
# load_settled: sets SETTLED (the lines of settled.jsonl) and EFFECTIVE (the corpus less what they drop).
load_settled() {
  SETTLED='[]'
  if [ -r "$SETTLED_DIR/settled.jsonl" ]; then SETTLED="$(jq -sc . "$SETTLED_DIR/settled.jsonl")"; fi
  EFFECTIVE="$(jq -nc --argjson s "$SEGMENTS" --argjson settled "$SETTLED" "$INC effective(\$s; \$settled)")"
}
load_settled

case "$CMD" in
segments)
  printf '%s\n' "$EFFECTIVE"
  ;;

clashes)
  if [ -n "$TARGET_DIR" ] && [ -r "$TARGET_DIR/clashes.jsonl" ]; then
    MET="$(jq -sc . "$TARGET_DIR/clashes.jsonl")"
    LISTING="$(jq -nr --argjson met "$MET" --argjson segs "$EFFECTIVE" \
      "$INC clash_listing(merge_clashes(\$met; \$segs); \$segs)")"
    [ -z "$LISTING" ] || printf '%s\n' "$LISTING"
  fi
  ;;

settle)
  KEEP=; DROP=(); MODE=
  while [ $# -gt 0 ]; do
    case "$1" in
      --keep) KEEP="${2:-}"; MODE=keep; shift 2 || { echo "corpus.sh: --keep needs an id" >&2; exit 2; } ;;
      --drop) MODE=drop; shift ;;
      *) [ "$MODE" = drop ] || { echo "corpus.sh: unexpected argument $1; $USAGE" >&2; exit 2; }
         DROP+=("$1"); shift ;;
    esac
  done
  [ "${#DROP[@]}" -gt 0 ] || { echo "$USAGE" >&2; exit 2; }
  [ "$MODE" != keep ] || [ -n "$KEEP" ] || { echo "$USAGE" >&2; exit 2; }
  for id in "${DROP[@]}"; do
    [ -z "$KEEP" ] || [ "$id" != "$KEEP" ] || { echo "corpus.sh: $id is both kept and dropped" >&2; exit 2; }
  done
  for id in ${KEEP:+"$KEEP"} "${DROP[@]}"; do
    jq -e --arg id "$id" 'any(.[]; .id == $id)' <<< "$SEGMENTS" > /dev/null \
      || { echo "corpus.sh: $id is not a segment of the corpus of $TARGET_NAME's spec" >&2; exit 2; }
  done
  mkdir -p "$SETTLED_DIR"
  if [ -n "$KEEP" ]; then
    jq -nc --arg keep "$KEEP" '{keep: $keep, drop: $ARGS.positional}' --args -- "${DROP[@]}" >> "$SETTLED_DIR/settled.jsonl"
  else
    jq -nc '{drop: $ARGS.positional}' --args -- "${DROP[@]}" >> "$SETTLED_DIR/settled.jsonl"
  fi
  ;;
esac
