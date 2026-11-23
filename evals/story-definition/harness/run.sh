#!/usr/bin/env bash
# Run bjornstack:story-definition once on the briefkasten spec.
#
# Usage: run.sh <run-name> [--owner-away] [--arm <arm>] [--prompt <file> [--stand-in <file>]]
#   --owner-away   append "The owner is away for this session"
#   --arm          config dir under tmp/evals/config/ (default bjornstack-arm);
#                  ignored with --prompt
#   --prompt       run any first prompt as claude -p --restricted --plugin-dir
#                  <frozen copy> on the normal config (needs CLAUDE_CODE_OAUTH_TOKEN)
#   --stand-in     with --prompt: a second claude -p answers each question
#                  as the owner, from this file's instruction, until DONE or 20
# Output: tmp/evals/runs/<run-name>/ with transcript.jsonl, stderr.log,
#         prompt.txt, model.txt, workdir/ and workdir-path.txt, and
#         standin.jsonl with --stand-in.
# Needs setup.sh first, and `claude auth login` for the arm without --prompt.
# With --prompt, the Keychain item bjornstack-evals (from claude setup-token)
# supplies CLAUDE_CODE_OAUTH_TOKEN to run.sh's claude calls only.
set -euo pipefail

USAGE="usage: run.sh <run-name> [--owner-away] [--arm <arm>] [--prompt <file> [--stand-in <file>]]"
NAME="${1:?$USAGE}"
shift
AWAY=0
ARM=bjornstack-arm
PROMPT_FILE=
STAND_IN_FILE=
while [ $# -gt 0 ]; do
  case "$1" in
    --owner-away) AWAY=1 ;;
    --arm) ARM="${2:?--arm needs a value}"; shift ;;
    --prompt) PROMPT_FILE="${2:?--prompt needs a file}"; shift ;;
    --stand-in) STAND_IN_FILE="${2:?--stand-in needs a file}"; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done
if [ -n "$STAND_IN_FILE" ] && { [ -z "$PROMPT_FILE" ] || [ "$AWAY" = 1 ]; }; then
  echo "$USAGE" >&2
  echo "--stand-in needs --prompt and cannot go with --owner-away" >&2
  exit 2
fi

REPO="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
E="${EVALS_DIR:-$REPO/tmp/evals}"
OUT="$E/runs/$NAME"
[ ! -e "$OUT" ] || { echo "$OUT exists; pick a new run name" >&2; exit 1; }

# Empty working directory outside any repo, so no CLAUDE.md or beads load.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/story-eval.XXXXXX")"

if [ -n "$PROMPT_FILE" ]; then
  # Any first prompt: claude -p --restricted on the owner's normal config,
  # loading only the frozen bjornstack plugin. Unattended runs use the
  # token from `claude setup-token`, read from the Keychain, never an API key.
  FROZEN="$E/config/sources/bjornstack/plugin"
  ACCOUNT="${USER:-$(id -un)}"
  TOKEN="$(security find-generic-password -a "$ACCOUNT" -s bjornstack-evals -w 2>/dev/null)" || TOKEN=""
  [ -n "$TOKEN" ] || {
    echo "no token in the Keychain for service bjornstack-evals, account $ACCOUNT; run claude setup-token, then security add-generic-password -a \"$ACCOUNT\" -s bjornstack-evals -w (it prompts for the token)" >&2
    exit 1
  }
  [ -d "$FROZEN" ] || { echo "no frozen plugin at $FROZEN; run setup.sh first" >&2; exit 1; }
  [ -r "$PROMPT_FILE" ] || { echo "cannot read $PROMPT_FILE" >&2; exit 1; }
  [ -z "$STAND_IN_FILE" ] || [ -r "$STAND_IN_FILE" ] || { echo "cannot read $STAND_IN_FILE" >&2; exit 1; }
  mkdir -p "$OUT"
  cd "$WORK"

  PROMPT="/bjornstack:story-definition $(cat "$PROMPT_FILE")"
  if [ "$AWAY" = 1 ]; then
    PROMPT="$PROMPT

The owner is away for this session"
  fi
  printf '%s\n' "$PROMPT" > "$OUT/prompt.txt"

  # Read on the frozen copy (a rule's // prefix marks an absolute path);
  # Write and Edit stay in the working directory.
  # The token is set on each claude call only, never exported, and no
  # API key reaches the call.
  claude_tok() { env -u ANTHROPIC_API_KEY "CLAUDE_CODE_OAUTH_TOKEN=$TOKEN" claude "$@"; }
  session() {
    claude_tok -p "$@" --restricted --plugin-dir "$FROZEN" \
      --tools "Read,Write,Edit" --permission-mode acceptEdits \
      --allowedTools "Read(/$FROZEN/**)" \
      --output-format stream-json --verbose
  }
  # The session's last turn: the text of the final result event.
  last_text() { jq -rs '[.[] | select(.type=="result")] | last | .result // ""' "$1"; }

  TURN="$OUT/turn.tmp"
  session "$PROMPT" > "$TURN" 2>> "$OUT/stderr.log"
  cat "$TURN" > "$OUT/transcript.jsonl"

  # Only builtins and the frozen plugin may be loaded.
  if ! jq -e 'select(.type=="system" and .subtype=="init")
      | [.plugins[] | (if type=="object" then (.name // .id // tostring) else tostring end)
         | select(test("^(bjornstack@inline|builtins?)$") | not)] | length == 0' \
      "$OUT/transcript.jsonl" > /dev/null; then
    echo "init event lists a plugin besides bjornstack@inline and builtins" >&2
    exit 1
  fi

  if [ -n "$STAND_IN_FILE" ]; then
    : > "$OUT/standin.jsonl"
    STAND_WORK="$(mktemp -d "${TMPDIR:-/tmp}/story-eval-standin.XXXXXX")"
    SID="$(jq -rs '[.[] | select(.type=="result")] | last | .session_id' "$TURN")"
    ANSWERS=0
    while [ "$ANSWERS" -lt 20 ]; do
      ASK="$(cat "$STAND_IN_FILE")

You answer a Claude session's questions as the owner. Reply with only your
answer. If the session's last turn asks the owner nothing, reply with the
single word DONE.

The prompt the session started from:
$(cat "$PROMPT_FILE")

The session's last turn:
$(last_text "$TURN")"
      # The stand-in sees only the above: no tools, its own empty directory,
      # not the session's (which holds what the session wrote).
      (cd "$STAND_WORK" && claude_tok -p "$ASK" --restricted --tools "" \
        --output-format stream-json --verbose) \
        > "$OUT/standin.turn" 2>> "$OUT/stderr.log"
      cat "$OUT/standin.turn" >> "$OUT/standin.jsonl"
      ANSWER="$(last_text "$OUT/standin.turn")"
      [ "$(printf '%s' "$ANSWER" | tr -d '[:space:]')" != DONE ] || break
      ANSWERS=$((ANSWERS + 1))
      session "$ANSWER" --resume "$SID" > "$TURN" 2>> "$OUT/stderr.log"
      cat "$TURN" >> "$OUT/transcript.jsonl"
    done
    rm -f "$OUT/standin.turn"
  fi
  rm -f "$TURN"
else
  mkdir -p "$OUT"
  export CLAUDE_CONFIG_DIR="$E/config/$ARM"
  cd "$WORK"

  PROMPT="/bjornstack:story-definition $(cat "$E/specs/briefkasten.md")"
  if [ "$AWAY" = 1 ]; then
    PROMPT="$PROMPT

The owner is away for this session"
  fi
  printf '%s\n' "$PROMPT" > "$OUT/prompt.txt"

  # Read is allowed on the frozen plugin copies only; Bash stays denied.
  claude -p "$PROMPT" \
    --output-format stream-json --verbose \
    --permission-mode acceptEdits \
    --allowedTools "Read($E/config/sources/**)" \
    > "$OUT/transcript.jsonl" 2> "$OUT/stderr.log"
fi

# The model the CLI picked by default, from the init event.
jq -r 'select(.type=="system" and .subtype=="init") | .model' \
  "$OUT/transcript.jsonl" | head -n 1 > "$OUT/model.txt"

# Keep whatever the session wrote in its working directory.
cp -R "$WORK" "$OUT/workdir"
echo "$WORK" > "$OUT/workdir-path.txt"
