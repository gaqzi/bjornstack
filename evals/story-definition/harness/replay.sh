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
# between lines, so the TUI takes it as typed, not pasted), then at each turn
# end asks a claude -p matcher whether the turn asks the owner anything and which
# unused recorded segment (a numerically labelled line,
# or a paragraph of an owner message of R) answers each question. The matcher
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
# nothing pre-filled. Every pull-in prints to this tab, for each matched part
# and each refused near-match, the segment and the recorded turn it answered;
# nothing is written to a file. A turn that asks nothing ends the run with
# /exit. When the owner types in the session tab after a turn ends and before
# the driver types, the driver types nothing for that turn and decides on the
# next turn.
# The plugin sits inside the session's working directory: the whole frozen
# copy is copied to live/<run-name>/.bjornstack and the session loads
# --plugin-dir live/<run-name>/.bjornstack/plugin. Read is allowed and
# Write/Edit denied on that copy.
# Output: $EVALS_DIR/runs/<run-name>/ with transcript.jsonl, plugin-commit.txt,
#         replay.jsonl (one line per owner message on the session's final
#         chain: n, source, and the segment ids typed when replayed),
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
SEGMENTS="$(jq_r -c "$INC segments" "$R")"

mkdir -p "$E/live" "$E/runs"
mkdir "$LIVE" "$RUN"
cp "$COPY.commit" "$RUN/plugin-commit.txt"
mkdir "$LIVE/.bjornstack"
cp -R "$COPY/." "$LIVE/.bjornstack/"
printf '%s\n' "$R" > "$RUN/replayed-from.txt"
: > "$RUN/replay.jsonl"
TF=
TYPED='[]'   # [{text, segments, uuid}]: what the driver typed as answers, in order (uuid: its record in the session, set when it appears)

UUID="$(uuidgen | tr A-Z a-z)"
CREATED="$(rex window new bjornstack-evals-session --keep-open --json --focus=false --shell=none -s "$S" -c "$LIVE" -- \
  env -u ANTHROPIC_API_KEY "PATH=$PATH" "HOME=$HOME" \
  claude --session-id "$UUID" --restricted --plugin-dir "$LIVE/.bjornstack/plugin" --tools Read,Write,Edit \
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
  log="$(complete_lines "$TF" | jq -sc --argjson typed "$TYPED" "$INC replay_log(\$typed)[]" 2> /dev/null)" || return 0
  if [ -n "$log" ]; then printf '%s\n' "$log" > "$RUN/replay.jsonl"; fi
  return 0
}

# On any exit: write replay.jsonl, close the session tab and stop the
# background wait, keeping the exit status. Never fails, so it cannot change
# the status under set -e.
cleanup() {
  local status=$?
  trap - EXIT
  write_replay_log || true
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
  local line first=1
  while IFS= read -r line || [ -n "$line" ]; do
    [ "$first" = 1 ] || rex send-key -s "$S" -b "$BLOCK" ctrl+j
    first=0
    if [ -z "$line" ]; then continue; fi
    if [ "${line:0:1}" = "-" ]; then
      rex send -s "$S" -b "$BLOCK" -- "$line"
    else
      rex send -s "$S" -b "$BLOCK" "$line"
    fi
  done <<< "$1"
}

type_text() { # one message into the session tab, then enter
  type_lines "$1"
  rex send-key -s "$S" -b "$BLOCK" enter
}

sleep "$STARTUP"
type_text "$FIRST_TEXT"
STARTED="$(date +%s)"

complete_lines() { # the file without a last line that has no newline yet
  if [ -n "$(tail -c1 "$1")" ]; then sed '$d' "$1"; else cat "$1"; fi
}

# ask_matcher <turn text>: prints the matcher's JSON answer. Returns
# a non-zero status when the matcher fails, after printing the reason to
# stderr: claude -p exited non-zero, or its output is not the JSON asked for:
# {"asks": bool, "questions": [{"number": int|letter|null, "segment": id|null,
# "refused": [id, ...] (optional)}, ...]}.
# It never prints the matcher's output.
ask_matcher() {
  local unused prompt dir out result status=0
  unused="$(printf '%s' "$SEGMENTS" | jq -c --argjson used "$USED" \
    '[.[] | select(.id as $i | $used | index($i) | not) | {id, label, segment, session_turn}]')"
  prompt="$(printf 'You are matching a live session to a recorded one. Below is THIS TURN, the text the session has just shown the owner, and RECORDED SEGMENTS, each a part of a recorded owner message (a line that starts with its label, or a paragraph; only a numeric label such as "4:", "4." or "4)" is kept apart in the label field, any other words stay in the segment text) with the session turn it answered.\n\nSay whether this turn asks the owner anything. If it does, list every question of this turn, in the order the turn asks them, with the label the turn gives the question (a number or a single letter; null when it has none) and the id of the one recorded segment that answers it (null when none does). List every question, a question no segment answers with segment null.\n\nA segment matches a question only when (a) its recorded session turn asked the same decision about the same design and (b), read against this turn alone, it means what it meant against its recorded turn: everything it names, accepts or rejects must be in this turn. A "yes" or praise matches only the same proposal. A segment that names, accepts or rejects something this turn does not hold does not match. A bare option letter (such as "B" or "a + b") matches only with the same options under the same letters. A segment answers at most one question.\n\nWhen a segment nearly matches a question but fails the test above, name its id in that question'"'"'s "refused" list.\n\nReply with only JSON: {"asks": true or false, "questions": [{"number": <integer, a single letter, or null>, "segment": "<segment id>" or null, "refused": ["<segment id>", ...]}, ...]} ("refused" may be left out).\n\nTHIS TURN:\n%s\n\nRECORDED SEGMENTS (JSON):\n%s' "$1" "$unused")"
  dir="$(mktemp -d "${TMPDIR:-/tmp}/replay-matcher.XXXXXX")"
  out="$(cd "$dir" && env -u ANTHROPIC_API_KEY claude -p "$prompt" --restricted --tools "" --output-format json --no-session-persistence < /dev/null 2> /dev/null)" || status=$?
  rm -rf "$dir"
  if [ "$status" != 0 ]; then echo "replay.sh: the matcher (claude -p) exited $status" >&2; return 1; fi
  result="$(printf '%s' "$out" | jq -er 'select(type == "object" and .is_error != true and (.result | type) == "string") | .result' 2> /dev/null | sed '/^```/d')" || { echo "replay.sh: the matcher's output is not the expected JSON" >&2; return 1; }
  printf '%s' "$result" | jq -ce 'select(type == "object" and (.asks | type) == "boolean"
      and (.questions == null or ((.questions | type) == "array"
        and (.questions | all(type == "object" and (.number == null or (.number | type) == "number" or (.number | type) == "string")
                              and (.segment == null or (.segment | type) == "string")
                              and (.refused == null or ((.refused | type) == "array" and (.refused | all(type == "string")))))))))' 2> /dev/null || { echo "replay.sh: the matcher's output is not the expected JSON" >&2; return 1; }
}

USED='[]'
EXPECT=
EXPECTING=0
WAITING=0
EXIT_SEEN=0
TURN=
DONE_EVENTS=0

# True when the transcript shows an owner or exit event after the events
# handled so far: the owner typed while the driver was deciding.
owner_acted() {
  complete_lines "$TF" | jq -sce --argjson done "$DONE_EVENTS" \
    "$INC [session_events] | .[\$done:] | any(.kind == \"owner\" or .kind == \"exit\")" > /dev/null
}

pull_owner_in() {
  rex window rename -s "$S" "$WINDOW" "bjornstack-evals-session: your answer" > /dev/null
  rex window focus -s "$S" "$WINDOW" > /dev/null
  WAITING=1
}

# answer_plan <answer> <turn text>: prints one JSON object
# {kind, lines, ids, display}; lines is [{label, id}], id null for an empty marker.
# A question's label is a whole positive integer (a JSON integer or a digit
# string) or a single ASCII letter. The answer is labelled when every question
# has a label, all of one kind, distinct (letters ignoring case) and each
# starting a line of the turn text (after optional spaces, "*", "-", ">" or
# "(", then "." ":" or ")", a letter also a space or the end of the line).
# kind "full": every question has a distinct unused segment of R and the
# answer is labelled or no question has a label; message is the segments typed
# as one message, each prefixed "<label>: " (the turn's labels, else 1, 2, ...,
# none for a single question: label ""), ids the segments used.
# kind "partial": at least one question has such a segment, and either some
# do not (segment id null is uncovered) or all do but the labelling is mixed
# or bad (any id that is unknown, used or repeated makes the kind "pull");
# ids the segments pre-filled; lines is the pre-fill: "<label>: <segment>"
# or "<label>: " for each question, or just the covered segments (label "")
# when not labelled.
# kind "pull": anything else. display describes the matched segments and the
# refused near-matches the answer names.
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
    | ($ans.questions // []) as $qs
    | ($qs | length) as $n
    | [$qs[].segment | select(. != null)] as $got
    | ($got | all(. as $s | ($known | index($s)) != null and ($used | index($s)) == null)
       and ($got | unique | length) == ($got | length)) as $idsok
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
      ([$matched[] | part("matched answer"; .)] + [$refused[] | part("refused near-match"; .)] | join("")) as $display
    | def lines($withmarkers):
        [$qs | to_entries[]
         | (if $labelled then $labs[.key].v elif $n == 1 then "" else (.key + 1 | tostring) end) as $l
         | select(.value.segment != null or $withmarkers)
         | {label: $l, id: .value.segment}];
      if $n == 0 or ($got | length) == 0 or ($idsok | not) then {kind: "pull", display: $display}
      elif ($got | length) == $n and ($labelled or $unlabelled)
      then {kind: "full", lines: lines(false), ids: $got, display: $display}
      else
        {kind: "partial", display: $display, ids: $got,
            lines: (if $labelled then lines(true) else [lines(false)[] | .label = ""] end)}
      end'
}

# decide <turn text>: type the chosen segments as one message when every
# question has a usable segment; when only some do, pre-fill the session's
# input box (no enter) and pull the owner in; else pull the owner in. A pull-in
# prints the matched segments and refused near-matches (see answer_plan).
decide() {
  local answer plan kind label id seg message= ids
  local matched=0
  answer="$(ask_matcher "$1")" || matched=1
  # The owner typed while the matcher ran: type nothing, decide on the next turn.
  if owner_acted; then return; fi
  if [ "$matched" = 1 ]; then pull_owner_in; return; fi
  if [ "$(printf '%s' "$answer" | jq -r '.asks')" = false ]; then
    EXITING=1
    type_text /exit
    return
  fi
  plan="$(answer_plan "$answer" "$1")"
  kind="$(printf '%s' "$plan" | jq -r '.kind')"
  while IFS='|' read -r label id; do
    [ -n "$label$id" ] || continue
    if [ "$id" = null ]; then
      seg=
    else
      seg="$(printf '%s' "$SEGMENTS" | jq -j --arg id "$id" '.[] | select(.id == $id) | .segment'; printf x)"
      seg="${seg%x}"
    fi
    [ -z "$label" ] || seg="$label: $seg"
    message="${message:+$message

}$seg"
  done <<< "$(printf '%s' "$plan" | jq -r '(.lines // [])[] | .label + "|" + (.id // "null")')"
  case "$kind" in
    full)
      if [ -z "$message" ]; then pull_owner_in; return; fi
      if owner_acted; then return; fi
      ids="$(printf '%s' "$plan" | jq -c '.ids')"
      USED="$(printf '%s' "$USED" | jq -c --argjson s "$ids" '. + $s')"
      TYPED="$(printf '%s' "$TYPED" | jq -c --arg t "$message" --argjson s "$ids" '. + [{text: $t, segments: $s}]')"
      EXPECT="$message"
      EXPECTING=1
      type_text "$message"
      ;;
    partial)
      if owner_acted; then return; fi
      ids="$(printf '%s' "$plan" | jq -c '.ids')"
      USED="$(printf '%s' "$USED" | jq -c --argjson s "$ids" '. + $s')"
      [ -z "$message" ] || type_lines "$message"
      printf '%s' "$plan" | jq -j '.display'
      pull_owner_in
      ;;
    *)
      printf '%s' "$plan" | jq -j '.display'
      pull_owner_in
      ;;
  esac
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
      [ "$content" = "$FIRST_CONTENT" ] || fail "the session's first message differs from the recorded first message: $FIRST_TEXT"
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
  elif [ $(($(date +%s) - STARTED)) -ge "$FIRST_TIMEOUT" ]; then
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
