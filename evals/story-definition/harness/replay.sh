#!/usr/bin/env bash
# Replay a recorded run's owner messages into a new interactive
# bjornstack:story-definition session, in the tab rex-run.sh --replay opens.
#
# Usage: replay.sh <run-name> <transcript>   (transcript: absolute path of the recorded run R)
# Env:   EVALS_DIR (the eval home), REX_SESSION, PATH, HOME. For tests:
#        REPLAY_POLL_SECONDS (1), REPLAY_STARTUP_SECONDS (8, wait for the TUI
#        before the first message), REPLAY_FIRST_TIMEOUT (60, seconds to see
#        the session's transcript after the first message).
# Types R's first message into a new session tab (line by line with ctrl+j
# between lines, so the TUI takes it as typed, not pasted; control characters
# below 0x20 other than newline are stripped from anything typed), then at each turn
# end asks a claude -p matcher whether the turn asks the owner anything and which
# unused recorded segment (a numerically labelled line,
# or a paragraph of an owner message) answers each question. The segments are
# those of corpus.sh segments: every answer the owner gave any run of R's spec,
# less the ones the owner settled away, each kept with its run and record. The matcher
# matches a segment to a question only if, read against the turn alone, it
# means what it meant against its recorded turn (a yes or praise matches only
# the same proposal), and may name refused near-matches in "refused". When
# every question has a segment, the segments are typed as one message (see
# answer_plan). When some questions have a segment (null is uncovered) and some
# not, the session's input box is pre-filled (no enter) with the covered
# segments, each with the turn's number or letter label and an empty marker
# for each uncovered question (unlabelled paragraphs when the turn's labelling
# is mixed or absent), and the owner is pulled in (tab renamed and focused, no
# time limit) to finish and send; that line is the owner's, the pre-filled
# segments are marked used. Questions all covered but labelled mixed or badly
# are pre-filled the same way, as unlabelled paragraphs. When no question is
# covered, or an answer is unusable (unknown, used or repeated id), the owner is pulled in with
# nothing pre-filled. The matcher may also give a question a "clash" list: two
# or more segments that each answer it but disagree. That question is uncovered,
# nothing of it is typed, the pull-in shows each clashing answer with its run
# and record, and the clash is written to clashes.jsonl for the owner to settle
# after the run (the driver never picks between clashing answers). Before that,
# within a clash list only the answers of the highest record order of each run
# stay (the later answer of a run stands); when one answer is left there is no
# clash and it is typed like any matched answer. An unknown id skips this. Every pull-in prints to this tab, for each matched part
# and each refused near-match and each clashing answer, the segment and the
# recorded turn it answered. A turn that asks nothing ends the run with
# /exit. When the owner types in the session tab after a turn ends and before
# the driver types, the driver types nothing for that turn and decides on the
# next turn.
# The plugin sits inside the session's working directory: the whole frozen
# copy is copied to live/<run-name>/.bjornstack and the session loads
# --plugin-dir live/<run-name>/.bjornstack/plugin. Read is allowed and
# Write/Edit denied on that copy.
# A text the TUI would take for a command is never typed: R's first text, or an
# answer segment, whose first line starts with "!", "/" or "#" (R's own
# /bjornstack:story-definition command is the one exception). The owner is
# pulled in and shown it, and types it. A failed settle (see settle_picks) is
# named in unsettled.txt in the run directory and on stdout.
# Output: $EVALS_DIR/runs/<run-name>/ with transcript.jsonl, plugin-commit.txt,
#         replay.jsonl (one line per owner message on the session's final
#         chain: n, source, and when replayed the segment ids typed and, for
#         each, the run and record it came from),
#         clashes.jsonl (only when a clash was met: {question: the turn's
#         text, answers: [segment ids]} per clash),
#         unsettled.txt (only when a settle failed: the unsettled ids and why),
#         replayed-from.txt and workdir/ (the working directory without
#         .bjornstack). The session's working directory is
#         $EVALS_DIR/live/<run-name>, which keeps .bjornstack. Nothing else
#         is written; the matcher's prompt and output are kept nowhere.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
USAGE="usage: replay.sh <run-name> <transcript>"
NAME="${1:?$USAGE}"
R="${2:?$USAGE}"
E="${EVALS_DIR:?EVALS_DIR is not set}"
S="${REX_SESSION:?REX_SESSION is not set}"
POLL="${REPLAY_POLL_SECONDS:-1}"
STARTUP="${REPLAY_STARTUP_SECONDS:-8}"
FIRST_TIMEOUT="${REPLAY_FIRST_TIMEOUT:-60}"
COPY="$E/config/sources/bjornstack"
LIVE="$E/live/$NAME"
RUN="$E/runs/$NAME"

[ -r "$COPY.commit" ] || { echo "replay.sh: $COPY.commit is not readable; run rex-run.sh --freeze first" >&2; exit 1; }
[ -d "$COPY/plugin" ] || { echo "replay.sh: $COPY/plugin is not a directory; run rex-run.sh --freeze first" >&2; exit 1; }
[ -r "$R" ] || { echo "replay.sh: recorded transcript $R is not readable" >&2; exit 1; }
[ ! -e "$RUN" ] || { echo "replay.sh: $RUN exists" >&2; exit 1; }
[ ! -e "$LIVE" ] || { echo "replay.sh: $LIVE exists" >&2; exit 1; }

# jq finds a replay.jq in the working directory before one on -L, and this
# script runs in the eval home: name the harness directory in the include.
INC="include \"replay\" {search: \"$HERE\"};"
jq_r() { jq -s "$@"; }
FIRST_TEXT="$(jq_r -j "$INC first_message_text" "$R"; printf x)"
FIRST_TEXT="${FIRST_TEXT%x}"
FIRST_CONTENT="$(jq_r -j "$INC first_user_content" "$R"; printf x)"
FIRST_CONTENT="${FIRST_CONTENT%x}"
# Every answer the owner gave any run of R's spec, less the settled drops.
SEGMENTS="$(bash "$HERE/corpus.sh" segments "$R")" || { echo "replay.sh: the corpus of $R's spec could not be read" >&2; exit 1; }

mkdir -p "$E/live" "$E/runs"
mkdir "$LIVE" "$RUN"
cp "$COPY.commit" "$RUN/plugin-commit.txt"
mkdir "$LIVE/.bjornstack"
cp -R "$COPY/." "$LIVE/.bjornstack/"
printf '%s\n' "$R" > "$RUN/replayed-from.txt"
: > "$RUN/replay.jsonl"
TF=
TYPED='[]'   # [{text, segments, from, uuid}]: what the driver typed as answers, in order (from: [{run, record}] per segment; uuid: its record in the session, set when it appears)
CLASHES='[]'   # [{question, answers}]: the clashes met, one per set of answer ids
SETTLES='[]'   # [{ids, uuid}]: clashes on a one-question turn to settle at exit by dropping ids; uuid: the owner's first record after the pull-in, null until it appears
SETTLE_PENDING=0
WAITING=0
UNSETTLED=   # lines "<ids>: <why>" of the clashes whose settle failed

UUID="$(uuidgen | tr A-Z a-z)"
CREATED="$(rex window new bjornstack-evals-session --keep-open --json --focus=false --shell=none -s "$S" -c "$LIVE" -- \
  env -u ANTHROPIC_API_KEY "PATH=$PATH" "HOME=$HOME" \
  claude --session-id "$UUID" --restricted --strict-mcp-config --plugin-dir "$LIVE/.bjornstack/plugin" --tools Read,Write,Edit \
  --permission-mode acceptEdits --allowedTools "Read(/$LIVE/.bjornstack/**)" \
  --disallowedTools "Write(/$LIVE/.bjornstack/**),Edit(/$LIVE/.bjornstack/**)")" \
  || { echo "replay.sh: rex window new failed; no session tab was started" >&2; exit 1; }
WINDOW="$(printf '%s' "$CREATED" | jq -r '.window_id // empty')"
BLOCK="$(printf '%s' "$CREATED" | jq -r '.block_ids[0] // empty')"
[ -n "$WINDOW" ] && [ -n "$BLOCK" ] || { echo "replay.sh: rex named no window or block for the session tab: $CREATED" >&2; exit 1; }

rex wait -s "$S" "$BLOCK" > /dev/null 2>&1 &
WAITER=$!

# replay.jsonl: one line per owner message on the session transcript's final
# chain (a rewound draft is not on it); replayed when its record is one the driver typed (matched by uuid).
write_replay_log() {
  local log
  [ -d "$RUN" ] && [ -n "$TF" ] && [ -r "$TF" ] || return 0
  if ! log="$(complete_lines "$TF" | jq -sc --argjson typed "$TYPED" "$INC replay_log(\$typed)[]" 2>&1)"; then
    echo "replay.sh: replay.jsonl could not be written: $log" >&2
    return 0
  fi
  if [ -n "$log" ]; then printf '%s\n' "$log" > "$RUN/replay.jsonl"; fi
  return 0
}

# clashes.jsonl: the clashes met during the replay, only when one was met.
write_clashes() {
  [ -d "$RUN" ] || return 0
  if [ "$(printf '%s' "$CLASHES" | jq 'length')" -gt 0 ]; then
    printf '%s' "$CLASHES" | jq -c '.[]' > "$RUN/clashes.jsonl" || true
  fi
  return 0
}

# settle_picks: for each clash settled by the owner's answer whose record is on
# the session transcript's final chain, drop the clash's answers
# (corpus.sh settle --drop). A settle that fails (corpus.sh exits non-zero, or
# the chain cannot be read) does not change the run's exit status: its ids and
# why are written to unsettled.txt in the run directory and to stdout.
settle_picks() {
  local on ids id idlist why
  [ -n "$TF" ] && [ -r "$TF" ] || return 0
  if ! on="$(complete_lines "$TF" | jq -sc "$INC [owner_messages | .[].uuid]" 2>&1)"; then
    while IFS= read -r ids; do
      [ -n "$ids" ] && add_unsettled "$ids" "the session transcript's chain could not be read: $on"
    done < <(printf '%s' "$SETTLES" | jq -c '.[] | select(.uuid != null) | .ids')
    report_unsettled
    return 0
  fi
  while IFS= read -r ids; do
    [ -n "$ids" ] || continue
    idlist=()
    while IFS= read -r id; do idlist+=("$id"); done < <(printf '%s' "$ids" | jq -r '.[]')
    if ! why="$(EVALS_DIR="$E" bash "$HERE/corpus.sh" settle "$R" --drop "${idlist[@]}" 2>&1 > /dev/null)"; then
      add_unsettled "$ids" "corpus.sh settle failed: $why"
    fi
  done < <(printf '%s' "$SETTLES" | jq -c --argjson on "$on" '.[] | select(.uuid as $u | $u != null and ($on | index($u)) != null) | .ids')
  report_unsettled
  return 0
}

# add_unsettled <ids as a JSON array> <why>
add_unsettled() {
  UNSETTLED="${UNSETTLED:+$UNSETTLED
}$(printf '%s' "$1" | jq -r 'join(" ")'): $2"
}

report_unsettled() {
  [ -n "$UNSETTLED" ] || return 0
  [ ! -d "$RUN" ] || printf '%s\n' "$UNSETTLED" > "$RUN/unsettled.txt"
  printf 'replay.sh: not settled, drop these by hand with corpus.sh settle:\n%s\n' "$UNSETTLED"
}

# On any exit: write replay.jsonl and clashes.jsonl, close the session tab and stop the
# background wait, keeping the exit status. Never fails, so it cannot change
# the status under set -e.
cleanup() {
  local status=$?
  trap - EXIT
  write_replay_log || true
  write_clashes || true
  settle_picks || true
  rex window close -s "$S" "$WINDOW" > /dev/null 2>&1 || true
  kill "$WAITER" 2> /dev/null || true
  exit "$status"
}
trap cleanup EXIT

fail() {
  echo "replay.sh: $1" >&2
  rex capture -s "$S" -b "$BLOCK" --trim | tail -n 20 >&2 || true
  exit 1
}

type_lines() { # a text into the session tab, line by line, without the final enter
  # A multi-line rex send reaches the TUI as a paste, so a slash command in it
  # never runs. Each line is sent alone with ctrl+j (a newline that does not
  # submit) between lines. An empty line sends nothing, only its ctrl+j. rex
  # reads a text starting with '-' as a flag, so such a line follows `--`.
  local line first=1 text
  text="$(printf '%s' "$1" | strip_control; printf x)"
  text="${text%x}"
  while IFS= read -r line || [ -n "$line" ]; do
    [ "$first" = 1 ] || rex send-key -s "$S" -b "$BLOCK" ctrl+j
    first=0
    if [ -z "$line" ]; then continue; fi
    if [ "${line:0:1}" = "-" ]; then
      rex send -s "$S" -b "$BLOCK" -- "$line"
    else
      rex send -s "$S" -b "$BLOCK" "$line"
    fi
  done <<< "$text"
}

type_text() { # one message into the session tab, then enter
  type_lines "$1"
  rex send-key -s "$S" -b "$BLOCK" enter
}

pull_owner_in() {
  rex window rename -s "$S" "$WINDOW" "bjornstack-evals-session: your answer" > /dev/null
  rex window focus -s "$S" "$WINDOW" > /dev/null
  WAITING=1
}

# strip_control: stdin to stdout without the control characters below 0x20
# other than newline.
strip_control() { LC_ALL=C tr -d '\000-\011\013-\037'; }

# starts_command <text>: true when the first line of the text starts with "!",
# "/" or "#", which the TUI takes for a command.
starts_command() {
  case "${1%%$'\n'*}" in '!'* | '/'* | '#'*) return 0 ;; *) return 1 ;; esac
}

sleep "$STARTUP"
OWNER_FIRST=0   # 1 when the owner, not the driver, types the first message
FIRST_LINE="${FIRST_TEXT%%$'\n'*}"
if [ "$FIRST_LINE" = /bjornstack:story-definition ] || [ "${FIRST_LINE#/bjornstack:story-definition }" != "$FIRST_LINE" ] || ! starts_command "$FIRST_TEXT"; then
  type_text "$FIRST_TEXT"
else
  OWNER_FIRST=1
  printf 'replay.sh: the first message starts with !, / or #, so it is not typed; type it yourself:\n%s\n' "$(printf '%s' "$FIRST_TEXT" | strip_control)"
  pull_owner_in
fi
STARTED="$(date +%s)"

complete_lines() { # the file without a last line that has no newline yet
  if [ -n "$(tail -c1 "$1")" ]; then sed '$d' "$1"; else cat "$1"; fi
}

# run_matcher <prompt>: asks the matcher (claude -p, no tools, in an empty temp
# dir) and prints its result text with any code-fence lines removed. When
# claude exits non-zero, or its output is not the JSON envelope with a string
# result, it prints the reason to stderr, with what claude printed to stderr,
# and returns 1. It never prints the raw output.
run_matcher() {
  local dir out err result status=0
  dir="$(mktemp -d "${TMPDIR:-/tmp}/replay-matcher.XXXXXX")"
  out="$(cd "$dir" && env -u ANTHROPIC_API_KEY claude -p "$1" --restricted --strict-mcp-config --tools "" --output-format json --no-session-persistence < /dev/null 2> "$dir.err")" || status=$?
  err="$(cat "$dir.err")"
  rm -rf "$dir" "$dir.err"
  if [ "$status" != 0 ]; then echo "replay.sh: the matcher (claude -p) exited $status${err:+: $err}" >&2; return 1; fi
  result="$(printf '%s' "$out" | jq -er 'select(type == "object" and .is_error != true and (.result | type) == "string") | .result' 2> /dev/null | sed '/^```/d')" \
    || { echo "replay.sh: the matcher's output is not the expected JSON${err:+: $err}" >&2; return 1; }
  printf '%s' "$result"
}

# ask_matcher <turn text>: prints the matcher's JSON answer. Returns
# a non-zero status when the matcher fails, after printing the reason to
# stderr: claude -p exited non-zero, or its output is not the JSON asked for:
# {"asks": bool, "questions": [{"number": int|letter|null, "segment": id|null,
# "refused": [id, ...] and "clash": [id, id, ...] (both optional)}, ...]}.
# It never prints the matcher's output.
ask_matcher() {
  local unused prompt result
  unused="$(printf '%s' "$SEGMENTS" | jq -c --argjson used "$USED" \
    '[.[] | select(.id as $i | $used | index($i) | not) | {id, label, segment, session_turn, run, order}]')"
  prompt="$(printf 'You are matching a live session to a recorded one. Below is THIS TURN, the text the session has just shown the owner, and RECORDED SEGMENTS, each a part of a recorded owner message (a line that starts with its label, or a paragraph; only a numeric label such as "4:", "4." or "4)" is kept apart in the label field, any other words stay in the segment text) with the session turn it answered.\n\nSay whether this turn asks the owner anything. If it does, list every question of this turn, in the order the turn asks them, with the label the turn gives the question (a number or a single letter; null when it has none) and the id of the one recorded segment that answers it (null when none does). List every question, a question no segment answers with segment null.\n\nA segment matches a question only when (a) its recorded session turn asked the same decision about the same design and (b), read against this turn alone, it means what it meant against its recorded turn: everything it names, accepts or rejects must be in this turn. A "yes" or praise matches only the same proposal. A segment that names, accepts or rejects something this turn does not hold does not match. A bare option letter (such as "B" or "a + b") matches only with the same options under the same letters. A segment answers at most one question.\n\nWhen a segment nearly matches a question but fails the test above, name its id in that question'"'"'s "refused" list.\n\nWhen two or more segments each answer a question under the test above but say different things, so that they cannot both stand, the question is a clash: give segment null and list their ids in that question'"'"'s "clash" list. Each segment carries its run and its order (the place of its owner message in that run). List every answer of the same run that answers a question in "clash" too, so that the driver can let the later one of a run stand.\n\nReply with only JSON: {"asks": true or false, "questions": [{"number": <integer, a single letter, or null>, "segment": "<segment id>" or null, "refused": ["<segment id>", ...], "clash": ["<segment id>", "<segment id>", ...]}, ...]} ("refused" and "clash" may be left out).\n\nTHIS TURN:\n%s\n\nRECORDED SEGMENTS (JSON):\n%s' "$1" "$unused")"
  result="$(run_matcher "$prompt")" || return 1
  printf '%s' "$result" | jq -ce 'select(type == "object" and (.asks | type) == "boolean"
      and (.questions == null or ((.questions | type) == "array"
        and (.questions | all(type == "object" and (.number == null or (.number | type) == "number" or (.number | type) == "string")
                              and (.segment == null or (.segment | type) == "string")
                              and (.refused == null or ((.refused | type) == "array" and (.refused | all(type == "string"))))
                              and (.clash == null or ((.clash | type) == "array" and (.clash | all(type == "string")))))))))' 2> /dev/null || { echo "replay.sh: the matcher's output is not the expected JSON" >&2; return 1; }
}

USED='[]'
EXPECT=
EXPECTING=0
EXIT_SEEN=0
TURN=
DONE_EVENTS=0

# True when the transcript shows an owner or exit event after the events
# handled so far: the owner typed while the driver was deciding.
owner_acted() {
  complete_lines "$TF" | jq -sce --argjson done "$DONE_EVENTS" \
    "$INC [session_events] | .[\$done:] | any(.kind == \"owner\" or .kind == \"exit\")" > /dev/null
}

# answer_plan <answer> <turn text>: prints one JSON object
# {kind, message, lines, ids, display, clashes, settle, superseded}.
#   kind: "full", "partial" or "pull" (below).
#   message: the text to type or pre-fill, the lines joined by a blank line,
#     each "<label>: <segment>" (just the segment when the label is ""); absent
#     for "pull".
#   lines: [{label, id}], id null for an empty marker.
#   ids: the segments typed or pre-filled.
#   display: the matched segments and refused near-matches, and the clashing
#     answers, each with the recorded turn it answered.
#   clashes: [[segment id, ...]] the clashes the owner settles after the run.
#   settle: the ids of a clash on a one-question turn, which the owner's answer
#     settles by dropping them; [] otherwise.
#   superseded: the ids of answers that a later answer of the same run replaced
#     within a clash list; they are used with the plan's ids.
# A question's label is a whole positive integer (a JSON integer or a digit
# string) or a single ASCII letter. The answer is labelled when every question
# has a label, all of one kind, distinct (letters ignoring case) and each
# starting a line of the turn text (after optional spaces, "*", "-", ">" or
# "(", then "." ":" or ")", a letter also a space or the end of the line).
# kind "full": every question has a distinct unused segment of R and the
# answer is labelled or no question has a label; the message is each segment
# prefixed "<label>: " (the turn's labels, else 1, 2, ...; none for a single
# question: label "").
# kind "partial": at least one question has such a segment, and either some
# do not (segment id null is uncovered) or all do but the labelling is mixed
# or bad (any id that is unknown, used or repeated makes the kind "pull");
# the message is the pre-fill: "<label>: <segment>" or "<label>: " for each
# question, or just the covered segments (label "") when not labelled.
# kind "pull": anything else.
answer_plan() {
  printf '%s' "$SEGMENTS" | jq -c --argjson used "$USED" --argjson ans "$1" --arg turn "$2" '
    def whole:
      if type == "number" then (if . == floor and . >= 1 then floor else null end)
      elif type == "string" then (if test("^[0-9]+$") then (tonumber | if . >= 1 then . else null end) else null end)
      else null end;
    def letter: if type == "string" and test("^[A-Za-z]$") then . else null end;
    def qlabel:
      (whole | if . != null then {k: "n", v: tostring} else null end)
      // (letter | if . != null then {k: "l", v: .} else null end);
    def dedup: reduce .[] as $x ([]; if index($x) != null then . else . + [$x] end);
    . as $segs
    | [.[].id] as $known
    | def later_only($ids):
        if ($ids | all(. as $id | any($segs[]; .id == $id))) then
          [$ids[] as $id | ($segs[] | select(.id == $id)) as $s | {id: $id, run: $s.run, order: $s.order}] as $c
          | [$c[] | . as $x | select($x.order == ([$c[] | select(.run == $x.run) | .order] | max)) | .id]
        else $ids end;
      ($ans.questions // [] | map(if .clash != null then .clash as $all | later_only($all) as $left
          | if ($left | length) == 1 then .segment = $left[0] | .superseded = ($all - $left) | .clash = null
            else .clash = $left | .unpruned = $all end
          else . end)) as $asked
    | ($asked | map(if .clash != null then .segment = null else . end)) as $qs
    | [$asked[] | select(.clash != null) | .clash] as $clashes
    | [$asked[] | (.superseded // [])[]] as $superseded
    | ($qs | length) as $n
    | [$qs[].segment | select(. != null)] as $got
    | (($got + ($clashes | add // [])) | all(. as $s | ($known | index($s)) != null and ($used | index($s)) == null)
       and ($got | unique | length) == ($got | length)
       and ($clashes | all(length >= 2))) as $idsok
    | (if $n == 1 and ($clashes | length) == 1 and $idsok then $asked[0].unpruned else [] end) as $settle
    | ($turn | split("\n")) as $lines
    | [$lines[] | capture("^[ *>(-]*(?<d>[0-9]+)[.:)]")? | .d | tonumber | tostring] as $in_numbers
    | [$lines[] | capture("^[ *>(-]*(?<d>[A-Za-z])[.:)]( |$)")? | .d | ascii_downcase] as $in_letters
    | ($qs | map(.number | qlabel)) as $labs
    | ($n > 0 and ($labs | all(. != null))
       and ($labs | map(.k) | unique | length) == 1
       and ($labs | map(.v | ascii_downcase) | unique | length) == $n
       and ($labs | all(. as $l | if $l.k == "n" then ($in_numbers | index($l.v)) != null
                                  else ($in_letters | index($l.v | ascii_downcase)) != null end))) as $labelled
    | ($qs | all(.number == null)) as $unlabelled
    | ($got | map(select(. as $s | ($known | index($s)) != null and ($used | index($s)) == null)) | dedup) as $matched
    | ([$qs[] | (.refused // [])[]] | map(select(. as $s | ($known | index($s)) != null and ($matched | index($s)) == null)) | dedup) as $refused
    | def part($word; $id):
        ($segs[] | select(.id == $id)) as $s
        | "\($word) \($id):\n\($s.segment)\nrecorded turn it answered:\n\($s.session_turn)\n\n";
      def clashing($id):
        ($segs[] | select(.id == $id)) as $s
        | "clashing answer \($id) (run \($s.run), record \($s.record)):\n\($s.segment)\nrecorded turn it answered:\n\($s.session_turn)\n\n";
      ([$matched[] | part("matched answer"; .)] + [$refused[] | part("refused near-match"; .)]
       + (if $idsok then [$clashes[][] | clashing(.)] else [] end) | join("")) as $display
    | def lines($withmarkers):
        [$qs | to_entries[]
         | (if $labelled then $labs[.key].v elif $n == 1 then "" else (.key + 1 | tostring) end) as $l
         | select(.value.segment != null or $withmarkers)
         | {label: $l, id: .value.segment}];
      def text($ls):
        [$ls[] | . as $l | (if $l.label == "" then "" else $l.label + ": " end)
                 + (if $l.id == null then "" else ($segs[] | select(.id == $l.id) | .segment) end)] | join("\n\n");
      if $n == 0 or ($got | length) == 0 or ($idsok | not) then {kind: "pull", display: $display, clashes: (if $idsok then $clashes else [] end), settle: $settle, superseded: $superseded}
      elif ($got | length) == $n and ($labelled or $unlabelled)
      then lines(false) as $ls | {kind: "full", message: text($ls), lines: $ls, ids: $got, display: $display, clashes: [], settle: [], superseded: $superseded}
      else
        (if $labelled then lines(true) else [lines(false)[] | .label = ""] end) as $ls
        | {kind: "partial", message: text($ls), display: $display, ids: $got, clashes: $clashes, settle: $settle, superseded: $superseded, lines: $ls}
      end'
}

# record_clashes <plan> <turn text>: adds the plan's clashes, each as the turn
# text and its answer ids, unless one with the same set of ids is there.
record_clashes() {
  CLASHES="$(printf '%s' "$1" | jq -c --argjson have "$CLASHES" --arg turn "$2" \
    'reduce (.clashes // [])[] as $ids ($have; if any(.[]; (.answers | sort) == ($ids | sort)) then . else . + [{question: $turn, answers: $ids}] end)')"
}

# remember_settle <plan>: a clash on a one-question turn is settled by the
# owner's answer; the owner's first record after the pull-in fixes which.
remember_settle() {
  local ids
  ids="$(printf '%s' "$1" | jq -c '.settle // []')"
  [ "$ids" != '[]' ] || return 0
  SETTLES="$(printf '%s' "$SETTLES" | jq -c --argjson ids "$ids" '. + [{ids: $ids, uuid: null}]')"
  SETTLE_PENDING=1
}

# decide <turn text>: type the chosen segments as one message when every
# question has a usable segment; when only some do, pre-fill the session's
# input box (no enter) and pull the owner in; else pull the owner in. A pull-in
# prints the matched segments and refused near-matches (see answer_plan).
decide() {
  local answer plan kind message matcher_failed=0
  answer="$(ask_matcher "$1")" || matcher_failed=1
  # The owner typed while the matcher ran: type nothing, decide on the next turn.
  if owner_acted; then return; fi
  if [ "$matcher_failed" = 1 ]; then pull_owner_in; return; fi
  if [ "$(printf '%s' "$answer" | jq -r '.asks')" = false ]; then
    EXITING=1
    type_text /exit
    return
  fi
  plan="$(answer_plan "$answer" "$1")"
  kind="$(printf '%s' "$plan" | jq -r '.kind')"
  # A segment the TUI would take for a command is shown, never typed.
  if [ "$kind" != pull ] && plan_starts_command "$plan"; then kind=pull; fi
  message="$(printf '%s' "$plan" | jq -j '.message // ""' | strip_control; printf x)"
  message="${message%x}"
  case "$kind" in
    full)
      if [ -z "$message" ]; then pull_owner_in; return; fi
      if owner_acted; then return; fi
      use_plan "$plan" "$message"
      EXPECT="$message"
      EXPECTING=1
      type_text "$message"
      ;;
    partial)
      if owner_acted; then return; fi
      use_plan "$plan"
      [ -z "$message" ] || type_lines "$message"
      show_plan "$plan" "$1"
      ;;
    *)
      show_plan "$plan" "$1"
      ;;
  esac
}

# plan_starts_command <plan>: true when a segment the plan would type starts
# with a command character (see starts_command).
plan_starts_command() {
  local id seg
  while IFS= read -r id; do
    seg="$(printf '%s' "$SEGMENTS" | jq -j --arg id "$id" '.[] | select(.id == $id) | .segment'; printf x)"
    if starts_command "${seg%x}"; then return 0; fi
  done < <(printf '%s' "$1" | jq -r '(.ids // [])[]')
  return 1
}

# use_plan <plan> [<typed message>]: marks the plan's segments used and, with a
# message, records it as typed.
use_plan() {
  USED="$(printf '%s' "$USED" | jq -c --argjson p "$1" '. + $p.ids + $p.superseded')"
  [ -n "${2:-}" ] || return 0
  TYPED="$(printf '%s' "$TYPED" | jq -c --arg t "$2" --argjson p "$1" --argjson all "$SEGMENTS" \
    '. + [{text: $t, segments: $p.ids, from: [$p.ids[] as $i | $all[] | select(.id == $i) | {run, record}]}]')"
}

# show_plan <plan> <turn text>: prints what the plan shows the owner, records
# its clashes and pulls the owner in.
show_plan() {
  printf '%s' "$1" | jq -j '.display' | strip_control
  record_clashes "$1" "$2"
  remember_settle "$1"
  pull_owner_in
}

fail_pending() {
  fail "the replayed answer never appeared in the session unchanged: it differs from, or is missing in, the transcript; typed: $EXPECT"
}

handle_event() {
  local kind content
  kind="$(printf '%s' "$1" | jq -r '.kind')"
  case "$kind" in
    first)
      content="$(printf '%s' "$1" | jq -j '.content'; printf x)"
      content="${content%x}"
      if [ "$OWNER_FIRST" = 1 ]; then
        WAITING=0
        rex window rename -s "$S" "$WINDOW" bjornstack-evals-session > /dev/null
      else
        [ "$content" = "$FIRST_CONTENT" ] || fail "the session's first message differs from the recorded first message: $FIRST_TEXT"
      fi
      ;;
    owner)
      content="$(printf '%s' "$1" | jq -j '.content'; printf x)"
      content="${content%x}"
      TURN=
      if [ "$EXPECTING" = 1 ]; then
        # The replayed answer is on the transcript, unchanged, or the run fails.
        [ "$content" = "$EXPECT" ] || fail_pending
        EXPECTING=0
        TYPED="$(printf '%s' "$TYPED" | jq -c --arg u "$(printf '%s' "$1" | jq -r '.uuid')" '.[-1].uuid = $u')"
      else
        if [ "$WAITING" = 1 ]; then
          WAITING=0
          if [ "$SETTLE_PENDING" = 1 ]; then
            SETTLE_PENDING=0
            SETTLES="$(printf '%s' "$SETTLES" | jq -c --arg u "$(printf '%s' "$1" | jq -r '.uuid')" '.[-1].uuid = $u')"
          fi
          rex window rename -s "$S" "$WINDOW" bjornstack-evals-session > /dev/null
        fi
      fi
      ;;
    assistant)
      TURN="${TURN:+$TURN

}$(printf '%s' "$1" | jq -j '.text')"
      ;;
    turn_end)
      if [ "$EXPECTING" = 1 ]; then
        fail_pending
      fi
      if [ "$WAITING" = 0 ] && [ "$EXITING" = 0 ] && [ -n "$TURN" ]; then
        local text="$TURN"
        TURN=
        decide "$text"
      fi
      ;;
    exit)
      [ "$EXPECTING" = 0 ] || fail_pending
      EXIT_SEEN=1
      ;;
  esac
}

EXITING=0
while :; do
  ENDED=0
  kill -0 "$WAITER" 2> /dev/null || ENDED=1
  if [ -z "$TF" ]; then
    TF="$(find "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects" -name "$UUID.jsonl" 2> /dev/null | head -n 1)" || TF=  # not there yet is not an error
  fi
  if [ -n "$TF" ]; then
    NEW="$(complete_lines "$TF" | jq -sc "$INC session_events" | tail -n +$((DONE_EVENTS + 1)))"
    while IFS= read -r EV; do
      [ -n "$EV" ] || continue
      DONE_EVENTS=$((DONE_EVENTS + 1))
      handle_event "$EV"
    done <<< "$NEW"
  elif [ "$OWNER_FIRST" = 0 ] && [ $(($(date +%s) - STARTED)) -ge "$FIRST_TIMEOUT" ]; then
    fail "no session transcript $UUID.jsonl appeared within ${FIRST_TIMEOUT}s of the first message"
  fi
  if [ "$ENDED" = 1 ]; then
    [ "$EXIT_SEEN" = 1 ] || fail "the session ended without /exit (session id $UUID)"
    break
  fi
  sleep "$POLL"
done

cp "$TF" "$RUN/transcript.jsonl"
cp -R "$LIVE" "$RUN/workdir"
rm -rf "$RUN/workdir/.bjornstack"
