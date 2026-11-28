#!/usr/bin/env bash
# Black-box checks for replay.sh, the driver of rex-run.sh --replay, with a
# stub rex and a stub claude on PATH. replay.sh, replay.jq,
# corpus.sh and corpus.jq are copied beside each other into a temp harness directory and run directly, as
# rex-run.sh runs them. No real rex or claude runs.
#
# Why only black-box cases: replay.sh is glue between a transcript file, rex
# and claude -p. The rules it applies (which recorded segment answers which
# question of a turn) are decided by the matcher model, not by code here; the
# code's own rules are "type only when the matcher covers every question of
# the turn with a distinct unused segment of R", "accept a question number
# only when it is a whole positive integer, distinct from the turn's other
# numbers and used in the turn's text as a question number", "label each typed
# segment with the turn's own question number, or 1, 2, ..." and "log an owner
# message as replayed exactly when the driver matched that record to the text
# it typed", and those are observable only through the typed text, the
# matcher's prompt and replay.jsonl, so they are checked here. The jq definitions of an owner message, a segment and a session
# event are exercised through the runs below; rex-run.sh's refusals are in
# check-rex-run.sh.
#
# The corpus: the segments the matcher is offered are those of corpus.sh
# (every answer the owner gave any run of R's spec, less the ones the owner
# settled away), not only R's. The cases that use it put other runs of R's
# spec (same first message) under $EV/runs, built with recorded_start and its
# companions, a replay's replay.jsonl beside them, and a settled.jsonl in
# $EV/corpus/<sha256 of the spec>/. A clash the matcher reports for a question
# ("clash": [ids] in its answer) is handled by the driver as the owner's call:
# nothing is typed, and clashes.jsonl in the run directory records it. When
# the turn asked one question and the owner's own line lands on the session's
# final chain, replay.sh settles the clash at exit (corpus.sh settle --drop
# with every id the matcher listed), so a later replay offers the owner's line
# and never the dropped answers. The corpus itself is covered in check-corpus.sh.
#
# The session is interactive, so the stubs model it:
#  - stub rex: `window new` for the session tab starts the stub session in
#    the background in the -c directory; `send` of a text without a newline
#    appends it to a buffer, `send` of a text with a newline is taken as a
#    paste (the buffer gets a pasted_content block, as the real Claude TUI
#    makes of it), `send-key ctrl+j` appends a newline to the buffer, `send-key
#    enter` submits the buffer to the session as one message (and logs it as
#    typed); `wait` blocks until the session ends and returns its status;
#    `capture` prints a canned tab; rename, focus and close are logged. These
#    switches are files in $SIDE: rename-fails makes `window rename` exit 1,
#    wait-hangs makes `wait` record its pid and run until a release file exists
#    (both wait loops and the session loop end at once when $SIDE is gone, so a
#    case's stubs never outlive it), exit-on-enter (holding n) makes the n-th
#    enter submit "/exit" to the session instead of the buffer (the typed log
#    still gets the buffer), and record-differs makes the session record each
#    answer typed to it with " (altered)" appended, as a session that changed
#    part of the text would. `send` of a text starting with - exits 1 unless
#    the argument before it is --, as the real rex reads such a text as a flag.
#    A matcher answer row with an .err file prints its text to stderr, as the
#    claude CLI does when it fails. The stub jq exits 5 on a call whose
#    arguments hold the text in $SIDE/jq-fails-on.
#    The stub claude as the matcher takes as long as the number of seconds in
#    $SIDE/matcher-sleep to answer, when that file exists.
#  - stub jq (in $T/bin, passing through to the real jq): when $SIDE/owner-at-lookup
#    exists and its arguments hold `--arg id` (the lookup of a chosen segment's
#    text in decide: replay.sh must make such a call), it removes the file, submits an owner message to the session,
#    waits (3 s at most) until it is on the transcript, then runs the real jq.
#    This puts an owner message between the decision and typing, exactly.
#  - replay.sh is started from the eval home, the directory rex-run.sh's tab
#    starts it in; a case may leave a decoy replay.jq there, which jq's include
#    would find before the harness directory's.
#
# The rule checked for owner input: after a turn ends, if an owner message or
# the session's /exit is on the transcript before the driver types, the driver
# types nothing for that turn (the matcher's result is discarded, whatever it
# says) and does not pull the owner in for it; the owner's message is recorded
# and the next turn is decided fresh. A typed replayed answer (the chosen
# segments, each labelled, joined by a blank line) must be the next owner
# record, byte for byte, or the run fails.
#  - stub claude as the session (no -p): writes its transcript to
#    $HOME/.claude/projects/<slug>/<--session-id>.jsonl and plays scripted
#    replies, one turn per submitted message. The test's owner() submits a
#    message to it as if typed in the tab, without going through rex send.
#  - stub claude as the matcher (-p): no default answer; its output comes from
#    a per-test table of (turn substring -> answer), looked up on the section
#    of the prompt between the lines THIS TURN: and RECORDED SEGMENTS (JSON):.
#    An answer is {"asks": bool, "questions": [{"number", "segment"}, ...]}.
#  - a matcher answer may name a question's label as a number or a single
#    letter, and the segments it considered and rejected as "refused" ids; the
#    stub rex keeps the session's input box as $SIDE/buffer (filled by send and
#    ctrl+j, emptied by enter or by the owner's send), so a pre-fill without enter can be compared.
#  - the stub session writes parentUuid on every record it writes, each
#    chained to the previous one. A message "@rewind" submitted to it is no
#    record: the next user record takes the parent of the previous user record
#    (an abandoned sibling), as a rewound draft does in the real session.
# Test-side files (typed texts, matcher prompts and arguments, the rex log)
# live in $SIDE, outside the eval home and TMPDIR, so the checks that nothing
# is left behind stay meaningful.
# Usage: check-replay.sh
set -uo pipefail

# `git rebase --exec` exports GIT_DIR and friends; clear them as the other checks do.
unset $(git rev-parse --local-env-vars)

HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/replay-check.XXXXXX")"
T="$(cd "$T" && pwd -P)"
trap 'touch "$T"/side.*/kill "$T"/side.*/release 2>/dev/null; [ -z "${DRV:-}" ] || kill "$DRV" 2>/dev/null; rm -rf "$T"' EXIT
FAILED=0

H="$T/harness"
EV="$T/home/workspace/bjornstack-evals"
COPY="$EV/config/sources/bjornstack"
R="$T/recorded/R.jsonl"
PATHX="$T/bin:$PATH"
mkdir -p "$T/bin" "$H" "$T/recorded"
REAL_JQ="$(command -v jq)"; export REAL_JQ
cp "$HERE/replay.sh" "$H/replay.sh"
cp "$HERE/replay.jq" "$H/replay.jq"
cp "$HERE/corpus.sh" "$H/corpus.sh"
cp "$HERE/corpus.jq" "$H/corpus.jq"

P1="11111111-1111-4111-8111-111111111111"
P2="22222222-2222-4222-8222-222222222222"
FIRST_TEXT=$'/bjornstack:story-definition spec first line\nsecond line <ol><li>a</li></ol>'
P1_TURN="Which folders should a refresh read?"
P1_MSG="only the ones I ticked"
P2_TURN="How many items should a page hold, and should drafts show?"
P2_MSG=$'50 per page\n\n  and hide the drafts \n- keep the drafts hidden'
T1="I can draft the refresh. Which folders should a refresh read?"
T1_AGAIN="Sorry, asking again: Which folders should a refresh read?"
T2="Should prune run daily or weekly?"
T3="How many items should a page hold, and should drafts show? Say how many."
# P2's message is two paragraph segments; P1's is one.
P1S="$P1#0"; P2S0="$P2#0"; P2S1="$P2#1"
T_MID="Noted. Anything else to settle?"
T_DONE="Here is the story. Nothing more to ask."

# The recorded transcript R: the first message (a line break and <ol> in the
# spec), an abandoned draft (a rewound sibling of P1), pair P1, pair P2, then
# the isMeta caveat and /exit records. Records chain by parentUuid, as real
# transcripts do: rec links each record to the previous one, rec_abandoned
# links a record to the previous one but leaves the chain where it was.
DRAFT_MSG="a draft I then rewound"
RF="$R"; PREV=
rec() {
  jq -nc "$@" | jq -c --arg p "$PREV" '. + {parentUuid: (if $p == "" then null else $p end)}' >> "$RF"
  PREV="$(tail -n 1 "$RF" | jq -r .uuid)"
}
rec_abandoned() { local keep="$PREV"; rec "$@"; PREV="$keep"; }
rec --arg a $'spec first line\nsecond line <ol><li>a</li></ol>' \
  '{type:"user",uuid:"00000000-0000-4000-8000-000000000000",message:{role:"user",content:("<command-message>bjornstack:story-definition</command-message>\n<command-name>/bjornstack:story-definition</command-name>\n<command-args>"+$a+"</command-args>")}}'
rec '{type:"user",isMeta:true,uuid:"00000000-0000-4000-8000-000000000001",message:{role:"user",content:[{type:"text",text:"skill text"}]}}'
rec '{type:"assistant",uuid:"a0000000-0000-4000-8000-000000000001",message:{role:"assistant",content:[{type:"thinking",thinking:"hm"}]}}'
rec --arg t "$P1_TURN" '{type:"assistant",uuid:"a0000000-0000-4000-8000-000000000002",message:{role:"assistant",content:[{type:"text",text:$t}]}}'
rec '{type:"system",subtype:"turn_duration",uuid:"b0000000-0000-4000-8000-000000000001"}'
rec_abandoned --arg m "$DRAFT_MSG" '{type:"user",uuid:"d0000000-0000-4000-8000-000000000001",message:{role:"user",content:$m}}'
rec --arg u "$P1" --arg m "$P1_MSG" '{type:"user",uuid:$u,message:{role:"user",content:$m}}'
rec --arg t "$P2_TURN" '{type:"assistant",uuid:"a0000000-0000-4000-8000-000000000003",message:{role:"assistant",content:[{type:"text",text:$t}]}}'
rec '{type:"system",subtype:"turn_duration",uuid:"b0000000-0000-4000-8000-000000000002"}'
rec --arg u "$P2" --arg m "$P2_MSG" '{type:"user",uuid:$u,message:{role:"user",content:$m}}'
rec '{type:"assistant",uuid:"a0000000-0000-4000-8000-000000000004",message:{role:"assistant",content:[{type:"text",text:"Done. Anything else?"}]}}'
rec '{type:"system",subtype:"turn_duration",uuid:"b0000000-0000-4000-8000-000000000003"}'
rec '{type:"user",isMeta:true,uuid:"c0000000-0000-4000-8000-000000000001",message:{role:"user",content:"<local-command-caveat>Caveat: local commands</local-command-caveat>"}}'
rec '{type:"user",uuid:"c0000000-0000-4000-8000-000000000002",message:{role:"user",content:"<command-name>/exit</command-name>\n<command-message>exit</command-message>\n<command-args></command-args>"}}'
rec '{type:"user",uuid:"c0000000-0000-4000-8000-000000000003",message:{role:"user",content:"<local-command-stdout>Bye!</local-command-stdout>"}}'

# A second recorded transcript R2 whose first message is plain text, not a
# slash command: the first message, pair P1, /exit.
R2="$T/recorded/R2.jsonl"
PLAIN_FIRST="plan the thing please"
RF="$R2"; PREV=
rec --arg m "$PLAIN_FIRST" '{type:"user",uuid:"e0000000-0000-4000-8000-000000000000",message:{role:"user",content:$m}}'
rec --arg t "$P1_TURN" '{type:"assistant",uuid:"e0000000-0000-4000-8000-000000000001",message:{role:"assistant",content:[{type:"text",text:$t}]}}'
rec '{type:"system",subtype:"turn_duration",uuid:"e0000000-0000-4000-8000-000000000002"}'
rec --arg u "$P1" --arg m "$P1_MSG" '{type:"user",uuid:$u,message:{role:"user",content:$m}}'
rec '{type:"user",uuid:"e0000000-0000-4000-8000-000000000003",message:{role:"user",content:"<command-name>/exit</command-name>\n<command-message>exit</command-message>\n<command-args></command-args>"}}'

# A third recorded transcript R3 as the session recorded it after a compaction:
# the first message, P1, a compact_boundary (its parentUuid is null, its
# logicalParentUuid the record before the compaction), the isCompactSummary
# user record (string content) and P2 after it, then /exit.
R3="$T/recorded/R3.jsonl"
SUMMARY="This session is being continued from a previous conversation. Summary: SUMMARY-TEXT-MARKER"
RF="$R3"; PREV=
rec --arg a $'spec first line\nsecond line <ol><li>a</li></ol>' \
  '{type:"user",uuid:"00000000-0000-4000-8000-000000000000",message:{role:"user",content:("<command-message>bjornstack:story-definition</command-message>\n<command-name>/bjornstack:story-definition</command-name>\n<command-args>"+$a+"</command-args>")}}'
rec --arg t "$P1_TURN" '{type:"assistant",uuid:"a0000000-0000-4000-8000-000000000002",message:{role:"assistant",content:[{type:"text",text:$t}]}}'
rec '{type:"system",subtype:"turn_duration",uuid:"b0000000-0000-4000-8000-000000000001"}'
rec --arg u "$P1" --arg m "$P1_MSG" '{type:"user",uuid:$u,message:{role:"user",content:$m}}'
BEFORE_COMPACTION="$PREV"; PREV=
rec --arg l "$BEFORE_COMPACTION" '{type:"system",subtype:"compact_boundary",uuid:"f0000000-0000-4000-8000-000000000001",logicalParentUuid:$l}'
rec --arg s "$SUMMARY" '{type:"user",isCompactSummary:true,uuid:"f0000000-0000-4000-8000-000000000002",message:{role:"user",content:$s}}'
rec --arg t "$P2_TURN" '{type:"assistant",uuid:"a0000000-0000-4000-8000-000000000003",message:{role:"assistant",content:[{type:"text",text:$t}]}}'
rec '{type:"system",subtype:"turn_duration",uuid:"b0000000-0000-4000-8000-000000000002"}'
rec --arg u "$P2" --arg m "$P2_MSG" '{type:"user",uuid:$u,message:{role:"user",content:$m}}'
rec '{type:"user",uuid:"c0000000-0000-4000-8000-000000000002",message:{role:"user",content:"<command-name>/exit</command-name>\n<command-message>exit</command-message>\n<command-args></command-args>"}}'
RF="$R"

# Recorded transcripts with multi-part messages. recorded_start writes the first
# message, recorded_turn what the session asked, recorded_answer the owner's
# message, recorded_exit the /exit records; each record chains to the one before.
SEQ=0
next_uuid() { SEQ=$((SEQ+1)); NEXT="$(printf '%08d-0000-4000-8000-%012d' "$SEQ" "$SEQ")"; }   # sets NEXT, not a subshell, so SEQ counts
recorded_start() {
  RF="$1"; PREV=
  rec --arg a $'spec first line\nsecond line <ol><li>a</li></ol>' \
    '{type:"user",uuid:"00000000-0000-4000-8000-000000000000",message:{role:"user",content:("<command-message>bjornstack:story-definition</command-message>\n<command-name>/bjornstack:story-definition</command-name>\n<command-args>"+$a+"</command-args>")}}'
}
recorded_turn() {
  next_uuid; rec --arg t "$1" --arg u "$NEXT" '{type:"assistant",uuid:$u,message:{role:"assistant",content:[{type:"text",text:$t}]}}'
  next_uuid; rec --arg u "$NEXT" '{type:"system",subtype:"turn_duration",uuid:$u}'
}
recorded_answer() { rec --arg u "$1" --arg m "$2" '{type:"user",uuid:$u,message:{role:"user",content:$m}}'; }
recorded_exit() { next_uuid; rec --arg u "$NEXT" '{type:"user",uuid:$u,message:{role:"user",content:"<command-name>/exit</command-name>\n<command-message>exit</command-message>\n<command-args></command-args>"}}'; }

# R4: one message of four segments (numbered, numbered with a continuation line,
# a paragraph that starts with a word and a colon, a paragraph) and one of two
# numbered segments in other punctuation. Only a numeric label is a label.
R4="$T/recorded/R4.jsonl"
PM="33333333-3333-4333-8333-333333333333"
PN="44444444-4444-4444-8444-444444444444"
PM_TURN="How often should prune run, which folders should it scan, and how many items per page?"
PM_MSG=$'1: weekly\n2: all folders\nincluding the archive\n\ntime for prune: nightly\n\nfifty items'
PN_TURN="Should the drafts stay hidden?"
PN_MSG=$'3) keep the drafts hidden\n4. yes'
PM0="$PM#0"; PM1="$PM#1"; PM2="$PM#2"; PM3="$PM#3"; PN0="$PN#0"; PN1="$PN#1"
recorded_start "$R4"
recorded_turn "$PM_TURN"; recorded_answer "$PM" "$PM_MSG"
recorded_turn "$PN_TURN"; recorded_answer "$PN" "$PN_MSG"
recorded_exit

# R5: a bare option letter answering a turn with its own options.
R5="$T/recorded/R5.jsonl"
PO="55555555-5555-4555-8555-555555555555"
PO_TURN="Which layout? A) a table B) a grid"
LAYOUT_TURN="Which layout should the list use? a) cards b) a table"
recorded_start "$R5"
recorded_turn "$PO_TURN"; recorded_answer "$PO" "B"
recorded_exit
RF="$R"

# R6: segments that look like labels but are not numeric ones: a letter label, a
# word-and-colon line, a time and a decimal, each a paragraph of its own; then a numbered
# line whose continuation line starts with a word and a colon.
R6="$T/recorded/R6.jsonl"
PW="66666666-6666-4666-8666-666666666666"
PW_TURN="What else should the job do?"
PW_MSG=$'A: and we need to specify a timeout\n\nno: keep the drafts\n\n10:30 is when the job runs\n\n3.5 hours\n\n1: weekly\nno: not on sundays'
PW0="$PW#0"; PW1="$PW#1"; PW2="$PW#2"; PW3="$PW#3"; PW4="$PW#4"
recorded_start "$R6"
recorded_turn "$PW_TURN"; recorded_answer "$PW" "$PW_MSG"
recorded_exit
RF="$R"

# R7: two bare answers, "no" and "yes", each a segment of its own.
R7="$T/recorded/R7.jsonl"
PA="77777777-7777-4777-8777-777777777777"
PB="88888888-8888-4888-8888-888888888888"
PA0="$PA#0"; PB0="$PB#0"
recorded_start "$R7"
recorded_turn "Should the drafts stay hidden?"; recorded_answer "$PA" "no"
recorded_turn "Should old items be pruned?"; recorded_answer "$PB" "yes"
recorded_exit
RF="$R"

# R8 (n4-shaped): one recorded answer that praises a name, with the multi-line
# turn that proposed that name.
R8="$T/recorded/R8.jsonl"
PQ="99999999-9999-4999-8999-999999999990"
PQ_TURN=$'I propose a name for the section.\nName: `publication`\nDo you accept it?'
PQ_MSG=$'publication is a nice touch, the concept is required ...\nand it reads well'
PQ0="$PQ#0"
recorded_start "$R8"
recorded_turn "$PQ_TURN"; recorded_answer "$PQ" "$PQ_MSG"
recorded_exit
RF="$R"

# R10: segments that start with a letter in three punctuations (not labels in
# a recording: they stay in the text), then lines that look like them
# ("e.g. foo", "A, it's fine"), then a word line.
R10="$T/recorded/R10.jsonl"
PL="aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
PL_TURN="What should the job do?"
PL_MSG=$'a: weekly\n\nB) all folders\nincluding the archive\n\ne.g. foo\n\nA, it\'s fine\n\nc. fifty items\n\ntime for prune: nightly'
PL0="$PL#0"; PL1="$PL#1"; PL2="$PL#2"; PL3="$PL#3"; PL4="$PL#4"; PL5="$PL#5"
recorded_start "$R10"
recorded_turn "$PL_TURN"; recorded_answer "$PL" "$PL_MSG"
recorded_exit
RF="$R"

# R12 (n2-shaped): "phase 2: a + b, yes ..." and "perfect", two paragraphs.
R12="$T/recorded/R12.jsonl"
PX="bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
PX_TURN="Which phase comes next, and is the plan fine?"
PX_MSG=$'phase 2: a + b, yes ...\n\nperfect'
PX0="$PX#0"; PX1="$PX#1"
recorded_start "$R12"
recorded_turn "$PX_TURN"; recorded_answer "$PX" "$PX_MSG"
recorded_exit
RF="$R"

# Stub rex. Every call is logged one per line in brackets (newlines in an
# argument shown as \n); typed texts are kept whole in $STUB_SIDE/typed.
cat > "$T/bin/rex" <<'STUB'
#!/usr/bin/env bash
S="$STUB_SIDE"
. "$S/lib.sh"
line=
for a in "$@"; do line="$line[${a//$'\n'/\\n}]"; done
echo "$line" >> "$S/rex.log"
echo $$ >> "$S/pids"
sub="$1"; shift
case "$sub" in
  window)
    act="$1"; shift
    case "$act" in
      new)
        shift   # the tab's name
        cwd=.
        while [ $# -gt 0 ] && [ "$1" != -- ]; do
          [ "$1" != -c ] || cwd="$2"
          shift
        done
        shift
        n="$(grep -c '^\[window\]\[new\]' "$S/rex.log")"
        printf '{"window_id":"win-%s","block_ids":["blk-%s"],"revision":1}\n' "$n" "$n"
        ( echo $BASHPID >> "$S/pids"; cd "$cwd" && "$@" > "$S/session.out" 2>&1 < /dev/null; echo $? > "$S/session.status" ) > /dev/null 2>&1 &
        ;;
      close) touch "$S/kill" ;;
      rename) [ ! -e "$S/rename-fails" ] || exit 1 ;;
      focus) ;;
      *) echo "stub: unknown window action $act" >&2; exit 1 ;;
    esac
    ;;
  send)
    t="${@: -1}"
    # The real rex reads a text starting with - as a flag unless it follows --.
    case "$t" in
      -*) [ "${@: -2:1}" = -- ] || { echo "rex: unknown flag: $t" >&2; exit 1; } ;;
    esac
    case "$t" in
      *$'\n'*) printf '\n\n<pasted_content id="198d">\n%s\n</pasted_content>' "$t" >> "$S/buffer" ;;
      *) printf '%s' "$t" >> "$S/buffer" ;;
    esac
    ;;
  send-key)
    case "${@: -1}" in
      ctrl+j) printf '\n' >> "$S/buffer" ;;
      enter)
        n=$(( $(ls "$S/typed" | wc -l) + 1 ))
        cp "$S/buffer" "$S/typed/$(printf %04d "$n")"
        if [ -e "$S/exit-on-enter" ] && [ "$n" = "$(cat "$S/exit-on-enter")" ]; then
          printf '/exit' > "$S/exit.msg"; submit "$S/exit.msg"
        else
          submit "$S/buffer"
        fi
        : > "$S/buffer"
        ;;
      *) echo "stub: only the enter and ctrl+j keys" >&2; exit 1 ;;
    esac
    ;;
  wait)
    # With the wait-hangs switch the wait records its pid and runs until the
    # release file exists, whatever the session does: a wait only the driver can stop.
    if [ -e "$S/wait-hangs" ]; then
      echo $$ > "$S/wait.pid"
      while [ ! -e "$S/release" ]; do [ -d "$S" ] || exit 1; sleep 0.05; done
      exit 0
    fi
    while [ ! -e "$S/session.status" ]; do [ -d "$S" ] || exit 1; sleep 0.05; done
    exit "$(cat "$S/session.status")"
    ;;
  capture) printf 'canned tab line\ncanned-tab-last-line\n' ;;
  *) echo "stub: unknown rex call $sub" >&2; exit 1 ;;
esac
STUB
chmod +x "$T/bin/rex"

# Stub jq: the real jq, except that the segment-text lookup (--arg id) first
# submits an owner message when $STUB_SIDE/owner-at-lookup exists.
cat > "$T/bin/jq" <<'STUB'
#!/usr/bin/env bash
S="${STUB_SIDE:-}"
if [ -n "$S" ] && [ -e "$S/jq-fails-on" ]; then
  for a in "$@"; do
    case "$a" in *"$(cat "$S/jq-fails-on")"*) echo "jq: stub failure" >&2; exit 5 ;; esac
  done
fi
if [ -n "$S" ] && [ -e "$S/owner-at-lookup" ]; then
  prev=
  for a in "$@"; do
    if [ "$prev" = --arg ] && [ "$a" = id ]; then
      rm -f "$S/owner-at-lookup"
      . "$S/lib.sh"
      printf '%s' "actually all of them" > "$S/owner.msg"; submit "$S/owner.msg"
      for i in $(seq 1 60); do
        grep -rqF -- "actually all of them" "$HOME/.claude/projects" 2>/dev/null && break
        sleep 0.05
      done
      break
    fi
    prev="$a"
  done
fi
exec "$REAL_JQ" "$@"
STUB
chmod +x "$T/bin/jq"

# Stub claude. With -p it is the matcher, otherwise the interactive session.
cat > "$T/bin/claude" <<'STUB'
#!/usr/bin/env bash
S="$STUB_SIDE"
echo $$ >> "$S/pids"
if [ "${1:-}" = -p ]; then
  n=$(( $(ls "$S/matcher" | grep -c '\.prompt$') + 1 )); id="$(printf %02d "$n")"
  printf '%s' "$2" > "$S/matcher/$id.prompt"
  pwd -P > "$S/matcher/$id.cwd"
  ls -A | wc -l | tr -d ' ' > "$S/matcher/$id.files"
  echo "${ANTHROPIC_API_KEY+set}${ANTHROPIC_API_KEY-unset}" | sed 's/^set.*/set/' > "$S/matcher/$id.key"
  jq -nc '$ARGS.positional' --args -- "$@" > "$S/matcher/$id.args"
  [ ! -e "$S/matcher-sleep" ] || sleep "$(cat "$S/matcher-sleep")"
  turn="$(printf '%s\n' "$2" | awk '/^THIS TURN:$/{f=1;next} /^RECORDED SEGMENTS \(JSON\):$/{f=0} f')"
  for m in "$S"/answers/*.match; do
    [ -e "$m" ] || break
    if printf '%s' "$turn" | grep -qF -- "$(cat "$m")"; then
      cat "${m%.match}.out"
      [ ! -e "${m%.match}.err" ] || cat "${m%.match}.err" >&2
      exit "$(cat "${m%.match}.exit")"
    fi
  done
  echo "no answer row for: $turn" >> "$S/matcher/unmatched"
  exit 9
fi

printf '%s\n' "$@" > "$S/session.argv"
pwd -P > "$S/session.cwd"
ls -A | paste -sd' ' - > "$S/session.cwdentries"
find .bjornstack 2>/dev/null | LC_ALL=C sort | while read -r f; do
  if [ -L "$f" ]; then echo "$f -> $(readlink "$f")"; else echo "$f"; fi
done > "$S/session.tree"
cat .bjornstack/plugin/strategies/s.md .bjornstack/plugin/tenets/t.md 2>/dev/null | paste -sd'|' - > "$S/session.resolved"
echo "${ANTHROPIC_API_KEY+set}${ANTHROPIC_API_KEY-unset}" | sed 's/^set.*/set/' > "$S/session.key"
sid=
for a in "$@"; do [ "$prev" != --session-id ] || sid="$a"; prev="$a"; done
dir="$HOME/.claude/projects/${PWD//[\/.]/-}"
mkdir -p "$dir"
TF="$dir/$sid.jsonl"
uuid() { uuidgen | tr A-Z a-z; }
# emit <user|other> <jq object program using $u> <jq args...>: one record,
# chained by parentUuid to the one before it. A user record after @rewind takes
# the parent of the previous user record instead (an abandoned sibling).
LAST=; USER_PARENT=; REWOUND=0
emit() {
  local kind="$1" prog="$2" u parent; shift 2
  u="$(uuid)"; parent="$LAST"
  if [ "$kind" = user ]; then
    [ "$REWOUND" = 0 ] || parent="$USER_PARENT"
    REWOUND=0; USER_PARENT="$parent"
  fi
  jq -nc --arg u "$u" --arg p "$parent" "$@" "$prog | . + {parentUuid: (if \$p == \"\" then null else \$p end)}" | put
  LAST="$u"
}
put() { [ -e "$S/no-transcript" ] || cat >> "$TF"; }
user_record() { emit user '{type:"user",uuid:$u,message:{role:"user",content:$t}}' --rawfile t "$1"; }
# A message typed while a turn runs is stored as a queued_command attachment, never also as a user record.
queued_record() { emit other '{type:"attachment",uuid:$u,attachment:{type:"queued_command",origin:{kind:"human"},prompt:$t}}' --rawfile t "$1"; }
turn_end() { emit other '{type:"system",subtype:"turn_duration",uuid:$u,durationMs:1}'; }
next() { f="$S/inbox/$(printf %04d "$idx")"; }
idx=1; turn=1; first=1
while :; do
  [ ! -e "$S/kill" ] || exit 143
  [ -d "$S" ] || exit 1
  next
  [ -e "$f" ] || { sleep 0.05; continue; }
  idx=$((idx+1))
  text="$(cat "$f")"
  if [ "$text" = @rewind ]; then REWOUND=1; continue; fi
  if [ "$first" = 1 ]; then
    first=0
    echo draft > notes.md
    case "$text" in
      /*)
        name="${text%% *}"; args="${text#* }"
        [ ! -e "$S/first-differs" ] || args="something else"
        printf '<command-message>%s</command-message>\n<command-name>%s</command-name>\n<command-args>%s</command-args>' "${name#/}" "$name" "$args" > "$S/first.rec" ;;
      *) printf '%s' "$text" > "$S/first.rec" ;;   # a plain first message is recorded as a plain string
    esac
    user_record "$S/first.rec"
  elif [ "$text" = /exit ]; then
    emit other '{type:"user",isMeta:true,uuid:$u,message:{role:"user",content:"<local-command-caveat>Caveat: local commands</local-command-caveat>"}}'
    emit other '{type:"user",uuid:$u,message:{role:"user",content:"<command-name>/exit</command-name>\n<command-message>exit</command-message>\n<command-args></command-args>"}}'
    emit other '{type:"user",uuid:$u,message:{role:"user",content:"<local-command-stdout>Bye!</local-command-stdout>"}}'
    exit 0
  elif [ -e "$S/record-differs" ]; then
    printf '%s (altered)' "$(cat "$f")" > "$S/altered.msg"; user_record "$S/altered.msg"
  else
    user_record "$f"
  fi
  rf="$S/replies/$(printf %02d "$turn")"
  if [ -e "$rf.delay" ]; then
    # A turn in progress: messages typed meanwhile show in the transcript at
    # once, as queued_command attachments, and get no reply of their own.
    for i in $(seq 1 "$(( $(cat "$rf.delay") * 20 ))"); do
      next
      if [ -e "$f" ]; then idx=$((idx+1)); queued_record "$f"; fi
      sleep 0.05
    done
  fi
  if [ -e "$rf.skip" ] && [ "$(cat "$rf.skip")" -gt 0 ]; then echo $(( $(cat "$rf.skip") - 1 )) > "$rf.skip"; continue; fi
  [ -e "$rf" ] || continue
  [ "$(cat "$rf")" != @die ] || exit 1
  emit other '{type:"assistant",uuid:$u,message:{role:"assistant",content:[{type:"text",text:$t}]}}' --rawfile t "$rf"
  turn_end
  turn=$((turn+1))
done
STUB
chmod +x "$T/bin/claude"

# fresh: a new SIDE directory (so a stub left from an earlier case cannot
# touch this one), a clean eval home with the frozen plugin copy and its
# commit, and an empty claude config and TMPDIR.
N=0
# leaked <side dir>: how many processes the stubs recorded there are still alive,
# after up to 3 s for them to notice the kill or release file.
leaked() {
  local i pid n
  for i in $(seq 1 60); do
    n=0
    for pid in $(cat "$1/pids" 2>/dev/null); do kill -0 "$pid" 2>/dev/null && n=$((n+1)); done
    [ "$n" = 0 ] && break
    sleep 0.05
  done
  echo "$n"
}
# alive_now <side dir>: how many of the recorded processes are alive at this moment.
alive_now() {
  local pid n=0
  for pid in $(cat "$1/pids" 2>/dev/null); do kill -0 "$pid" 2>/dev/null && n=$((n+1)); done
  echo "$n"
}
# leak_check: the case that used SIDE left no process of its own running.
leak_check() {
  [ "$N" = 0 ] || check "no process case $N started outlives it" "0" "$(leaked "$SIDE")"
}
fresh() {
  leak_check
  N=$((N+1))
  SIDE="$T/side.$N"
  mkdir -p "$SIDE"/{inbox,typed,matcher,answers,replies}
  : > "$SIDE/buffer"; : > "$SIDE/rex.log"
  cat > "$SIDE/lib.sh" <<LIB
submit() { # submit <file>: the file is the next message typed into the session tab
  while ! mkdir "$SIDE/lock" 2>/dev/null; do :; done
  n=\$(( \$(ls "$SIDE/inbox" | wc -l) + 1 ))
  cp "\$1" "$SIDE/inbox/\$(printf %04d "\$n").tmp"
  mv "$SIDE/inbox/\$(printf %04d "\$n").tmp" "$SIDE/inbox/\$(printf %04d "\$n")"
  rmdir "$SIDE/lock"
}
LIB
  export STUB_SIDE="$SIDE"
  [ -e "$R" ] || mv "$R.away" "$R"
  rm -rf "$EV" "$T/home/.claude" "$T/tmpd"
  mkdir -p "$COPY/plugin" "$COPY/strategies" "$COPY/tenets" "$COPY/.claude-plugin" "$EV/runs" "$T/tmpd"
  echo '{"name":"bjornstack"}' > "$COPY/plugin/plugin.json"
  echo '{"name":"market"}' > "$COPY/.claude-plugin/marketplace.json"
  echo strategy-text > "$COPY/strategies/s.md"
  echo tenet-text > "$COPY/tenets/t.md"
  ln -s ../strategies "$COPY/plugin/strategies"
  ln -s ../tenets "$COPY/plugin/tenets"
  printf 'abc123def4567890\n' > "$EV/config/sources/bjornstack.commit"
}

# Table of the session's scripted replies, and the matcher's answers.
reply() { printf '%s' "$2" > "$SIDE/replies/$(printf %02d "$1")"; }   # reply <turn number> <text>
reply_silent() { echo "$2" > "$SIDE/replies/$(printf %02d "$1").skip"; }   # reply_silent <turn number> <count>: the next <count> messages in that turn get no reply
matcher_sleeps() { echo "$1" > "$SIDE/matcher-sleep"; }   # every matcher call takes <seconds> to answer
reply_delay() { echo "$2" > "$SIDE/replies/$(printf %02d "$1").delay"; }
row() { # row <turn substring> <stdout> <exit status>
  local p; p="$(printf %02d $(( $(ls "$SIDE/answers" | grep -c '\.match$') + 1 )))"
  printf '%s' "$1" > "$SIDE/answers/$p.match"; printf '%s\n' "$2" > "$SIDE/answers/$p.out"; echo "$3" > "$SIDE/answers/$p.exit"
}
answer() { # answer <turn substring> <asks: true|false> [<number or letter>=<segment id>[=<refused id>,<refused id>[=<clash id>,<clash id>]] ...]: one entry per question of the turn, in order; null for no label or no segment; a fourth part gives the question's "clash" ids
  local match="$1" asks="$2" questions
  shift 2
  questions="$(for entry in "$@"; do
    jq -nc --arg e "$entry" '($e | split("=")) as $x | {number: (if $x[0] == "null" then null else ($x[0] as $s | try ($s | tonumber) catch $s) end), segment: (if $x[1] == "null" then null else $x[1] end)} + (if ($x[2] // "") != "" then {refused: ($x[2] | split(","))} else {} end) + (if ($x[3] // "") != "" then {clash: ($x[3] | split(","))} else {} end)'
  done | jq -sc .)"
  answer_result "$match" "{\"asks\": $asks, \"questions\": $questions}"
}
answer_result() { row "$1" "$(jq -nc --arg r "$2" '{result:$r}')" 0; }   # answer_result <turn substring> <the JSON string the matcher replies>
answer_raw() { row "$1" "$2" 0; }
answer_fails() { row "$1" "" 1; }

# owner: the owner types a message in the session tab, not through rex send.
owner() { . "$SIDE/lib.sh"; printf '%s' "$1" > "$SIDE/owner.msg"; submit "$SIDE/owner.msg"; : > "$SIDE/buffer"; }

# start <run name>: replay.sh in the background, as rex-run.sh's tab runs it.
# It runs in the eval home, the directory rex-run.sh's tab starts it in.
start() {
  ( cd "$EV" && exec env ANTHROPIC_API_KEY=sk-test STUB_SIDE="$SIDE" EVALS_DIR="$EV" REX_SESSION=sess-1 TMPDIR="$T/tmpd" \
    HOME="$T/home" PATH="$PATHX" REPLAY_POLL_SECONDS=0.1 REPLAY_STARTUP_SECONDS=0 REPLAY_FIRST_TIMEOUT="${FIRST_TIMEOUT:-5}" \
    "${HX:-$H}/replay.sh" "$1" "${RSRC:-$R}" ) > "$T/out" 2> "$T/err" &
  DRV=$!
}
# finish: wait for the driver to end (20 s at most), STATUS is its exit status.
finish() {
  local i
  for i in $(seq 1 400); do kill -0 "$DRV" 2>/dev/null || break; sleep 0.05; done
  if kill -0 "$DRV" 2>/dev/null; then kill -9 "$DRV" 2>/dev/null; STATUS=124; else wait "$DRV"; STATUS=$?; fi
}
# until_true <command...>: poll up to 10 s, stopping early when the driver has ended.
until_true() {
  local i
  for i in $(seq 1 200); do
    "$@" 2>/dev/null && return 0
    kill -0 "$DRV" 2>/dev/null || return 1
    sleep 0.05
  done
  return 1
}
logged() { grep -qF -- "$1" "$SIDE/rex.log"; }
in_session() { grep -rqF -- "$1" "$T/home/.claude/projects"; }
running() { kill -0 "$DRV" 2>/dev/null && echo running || echo ended; }

# Observers.
typed() { local f; for f in "$SIDE"/typed/*; do [ ! -e "$f" ] || jq -Rs . "$f"; done | paste -sd'|' -; }
session_file() { find "$T/home/.claude/projects" -name '*.jsonl' 2>/dev/null | head -1; }
owner_messages_in_session() {
  jq -sc '[.[] | select(.type=="user" and (.message.content|type)=="string" and (.message.content|startswith("<")|not)) | .message.content]' "$1"
}
replay_lines() { paste -sd'|' "$1" 2>/dev/null; }
rex_calls() { grep -E "^\[window\]\[(rename|focus|close)\]" "$SIDE/rex.log" | paste -sd'|' -; }
open_tabs() { echo $(( $(grep -c '^\[window\]\[new\]' "$SIDE/rex.log") - $(grep -c '^\[window\]\[close\]' "$SIDE/rex.log") )); }
run_files() { (cd "$EV/runs/$1" && LC_ALL=C ls -A | paste -sd' ' -); }
prompt_turn() { printf '%s\n' "$(awk '/^THIS TURN:$/{f=1;next} /^RECORDED SEGMENTS \(JSON\):$/{f=0} f' "$SIDE/matcher/0$1.prompt")"; }
prompt_segments() { awk 'f;/^RECORDED SEGMENTS \(JSON\):$/{f=1}' "$SIDE/matcher/0$1.prompt" | jq -c "$2"; }
matcher_env() { # one matcher call: files in its cwd, whether the cwd is under the eval home, the key, -p and the --tools value
  local id; id="$(printf %02d "$1")"
  case "$(cat "$SIDE/matcher/$id.cwd")" in "$EV"*) where=inside ;; *) where=outside ;; esac
  echo "$(cat "$SIDE/matcher/$id.files") $where $(cat "$SIDE/matcher/$id.key") $(jq -r '.[0]' "$SIDE/matcher/$id.args") [$(jq -r '.[index("--tools")+1]' "$SIDE/matcher/$id.args")]"
}
typing_calls() { # the typing calls in order: send:<text> and key:<key>
  sed -nE 's/^\[send\]\[-s\]\[sess-1\]\[-b\]\[blk-1\](\[--\])?\[(.*)\]$/send:\2/p; s/^\[send-key\]\[-s\]\[sess-1\]\[-b\]\[blk-1\]\[(.*)\]$/key:\1/p' "$SIDE/rex.log" | paste -sd'|' -
}
bad_sends() { grep -cE '^\[send\].*(\\n|\[\]$)' "$SIDE/rex.log"; }
matcher_persistence() { # per matcher call: whether its arguments hold --no-session-persistence
  local n; for n in "$@"; do jq -r 'index("--no-session-persistence") != null' "$SIDE/matcher/0$n.args"; done | paste -sd'|' -
}
matcher_strict() { # per matcher call: whether its arguments hold --strict-mcp-config
  local n; for n in "$@"; do jq -r 'index("--strict-mcp-config") != null' "$SIDE/matcher/0$n.args"; done | paste -sd'|' -
}
wait_pid_state() { # the stub wait's pid: gone (within 3 s), alive, or none when it never started
  local pid i; pid="$(cat "$SIDE/wait.pid" 2>/dev/null)"
  [ -n "$pid" ] || { echo none; return; }
  for i in $(seq 1 60); do kill -0 "$pid" 2>/dev/null || { echo gone; return; }; sleep 0.05; done
  echo alive
}
box() { jq -Rs . "$SIDE/buffer"; }   # what the session's input box holds, as a JSON string
stdout_json() { jq -Rs . "$T/out"; }   # what replay.sh printed to its own tab, as a JSON string
same() { cmp -s "$1" "$2" && echo same || echo different; }

check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then echo "ok   $1"; else
    echo "FAIL $1"; echo "  expected: $2"; echo "  actual:   $3"; FAILED=1
  fi
}

SESSION_TAB="[window][new][bjornstack-evals-session][--keep-open][--json][--focus=false][--shell=none][-s][sess-1][-c]"
RENAME_ASK="[window][rename][-s][sess-1][win-1][bjornstack-evals-session: your answer]"
FOCUS="[window][focus][-s][sess-1][win-1]"
RENAME_BACK="[window][rename][-s][sess-1][win-1][bjornstack-evals-session]"
CLOSE="[window][close][-s][sess-1][win-1]"
FIRST_JSON='"/bjornstack:story-definition spec first line\nsecond line <ol><li>a</li></ol>"'
P1_JSON='"only the ones I ticked"'
P2_TYPED_JSON='"1: 50 per page\n\n2:   and hide the drafts \n- keep the drafts hidden"'

# The default run (the invariant): both recorded questions come up, each
# answered by its recorded segments, then the session asks nothing.
# Scenarios: a question the recorded run answered gets the recorded answer;
# the run ends when the session asks the owner nothing.
fresh
reply 1 "$T1"; reply 2 "$T3"; reply 3 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "How many items" true "null=$P2S0" "null=$P2S1"; answer "Nothing more" false
export ANTHROPIC_API_KEY=sk-test
start r1; finish
check "a run whose questions are all recorded exits 0" "0" "$STATUS"
check "it opens the session tab named bjornstack-evals-session in <eval home>/live/<name>, started with the caller's PATH and HOME and ANTHROPIC_API_KEY removed" \
  "${SESSION_TAB}[$EV/live/r1][--][env][-u][ANTHROPIC_API_KEY][PATH=$PATHX][HOME=$T/home]" \
  "$(grep '^\[window\]\[new\]' "$SIDE/rex.log" | sed 's/\]\[claude\].*/]/')"
LIVE_COPY="$EV/live/r1/.bjornstack"
check "the session runs claude with the live run's flags, the plugin inside the working directory, and no --add-dir" \
  "--session-id|UUID|--restricted|--plugin-dir|$LIVE_COPY/plugin|--tools|Read,Write,Edit|--permission-mode|acceptEdits|--allowedTools|Read(/$LIVE_COPY/**)|--disallowedTools|Write(/$LIVE_COPY/**),Edit(/$LIVE_COPY/**)" \
  "$(awk 'NR==2{print "UUID";next}1' "$SIDE/session.argv" | grep -vxF -- --strict-mcp-config | paste -sd'|' -)"
check "the session runs claude with --strict-mcp-config, so no MCP server of the user's configuration loads" "1" "$(grep -cxF -- --strict-mcp-config "$SIDE/session.argv")"
check "the session id is a lowercase uuid" "1" "$(sed -n 2p "$SIDE/session.argv" | grep -c -E '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')"
check "the session starts in <eval home>/live/<name>, which holds only .bjornstack, without ANTHROPIC_API_KEY" \
  "$EV/live/r1 .bjornstack unset" "$(cat "$SIDE/session.cwd") $(cat "$SIDE/session.cwdentries") $(cat "$SIDE/session.key")"
check "the session finds a full copy of the frozen copy in .bjornstack, the two plugin symlinks kept as relative symlinks" \
  ".bjornstack
.bjornstack/.claude-plugin
.bjornstack/.claude-plugin/marketplace.json
.bjornstack/plugin
.bjornstack/plugin/plugin.json
.bjornstack/plugin/strategies -> ../strategies
.bjornstack/plugin/tenets -> ../tenets
.bjornstack/strategies
.bjornstack/strategies/s.md
.bjornstack/tenets
.bjornstack/tenets/t.md" "$(cat "$SIDE/session.tree")"
check "the copied symlinks still resolve to the copied strategies and tenets" "strategy-text|tenet-text" "$(cat "$SIDE/session.resolved")"
check "the frozen copy itself is unchanged and its symlinks are still symlinks" "../strategies ../tenets" "$(readlink "$COPY/plugin/strategies") $(readlink "$COPY/plugin/tenets")"
check "the driver types R's first message once, then R's owner messages as the matcher names them, then /exit, and nothing else" \
  "$FIRST_JSON|$P1_JSON|$P2_TYPED_JSON|\"/exit\"" "$(typed)"
check "each message is typed line by line: a send per non-empty line, ctrl+j between lines, enter at the end; an empty line is a ctrl+j alone" \
  "send:/bjornstack:story-definition spec first line|key:ctrl+j|send:second line <ol><li>a</li></ol>|key:enter|send:only the ones I ticked|key:enter|send:1: 50 per page|key:ctrl+j|key:ctrl+j|send:2:   and hide the drafts |key:ctrl+j|send:- keep the drafts hidden|key:enter|send:/exit|key:enter" \
  "$(typing_calls)"
check "no rex send carries a newline or an empty text" "0" "$(bad_sends)"
check "a line starting with a dash is sent after --, and reaches the session byte for byte" "1" \
  "$(grep -cF '[send][-s][sess-1][-b][blk-1][--][- keep the drafts hidden]' "$SIDE/rex.log")"
check "the first typed message reaches the session as one slash command with its spec" \
  "<command-message>bjornstack:story-definition</command-message>
<command-name>/bjornstack:story-definition</command-name>
<command-args>spec first line
second line <ol><li>a</li></ol></command-args>" \
  "$(jq -rs '[.[] | select(.type=="user")][0].message.content' "$EV/runs/r1/transcript.jsonl")"
check "the session's user records for the answers equal R's owner messages byte for byte" \
  "[$P1_JSON,$P2_TYPED_JSON]" "$(owner_messages_in_session "$EV/runs/r1/transcript.jsonl")"
check "replay.jsonl holds one line per replayed message, in order, with n, source, the segments and where each came from" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$P1S\"],\"from\":[{\"run\":\"R\",\"record\":\"$P1\"}]}|{\"n\":2,\"source\":\"replayed\",\"segments\":[\"$P2S0\",\"$P2S1\"],\"from\":[{\"run\":\"R\",\"record\":\"$P2\"},{\"run\":\"R\",\"record\":\"$P2\"}]}" \
  "$(replay_lines "$EV/runs/r1/replay.jsonl")"
check "the run directory holds exactly transcript.jsonl, plugin-commit.txt, replay.jsonl, replayed-from.txt and workdir" \
  "plugin-commit.txt replay.jsonl replayed-from.txt transcript.jsonl workdir" "$(run_files r1)"
check "transcript.jsonl is a copy of the session's transcript" "same" "$(same "$(session_file)" "$EV/runs/r1/transcript.jsonl")"
check "plugin-commit.txt is a copy of bjornstack.commit" "same" "$(same "$EV/config/sources/bjornstack.commit" "$EV/runs/r1/plugin-commit.txt")"
check "replayed-from.txt holds R's absolute path" "$R" "$(cat "$EV/runs/r1/replayed-from.txt")"
check "workdir holds what the session wrote there and no .bjornstack" "notes.md draft" \
  "$(ls -A "$EV/runs/r1/workdir" | paste -sd' ' -) $(cat "$EV/runs/r1/workdir/notes.md")"
check "the session tab is closed once, and no tab is left open" "1 0" "$(grep -cF "$CLOSE" "$SIDE/rex.log") $(open_tabs)"
check "the driver reads the screen of no tab" "0" "$(grep -c '^\[capture\]' "$SIDE/rex.log")"
check "an abandoned draft (a rewound sibling of P1) is never typed" "0" "$(typed | grep -cF "$DRAFT_MSG")"
check "an abandoned draft is in no matcher prompt" "0" "$(grep -rlF "$DRAFT_MSG" "$SIDE/matcher" | wc -l | tr -d ' ')"
check "the matcher is asked once per turn: three times" "3" "$(ls "$SIDE"/matcher/*.prompt | wc -l | tr -d ' ')"
check "every matcher runs in an empty directory outside the eval home, without ANTHROPIC_API_KEY, as claude -p with no tools" \
  "0 outside unset -p []|0 outside unset -p []|0 outside unset -p []" \
  "$(for n in 1 2 3; do matcher_env "$n"; done | paste -sd'|' -)"
check "the matcher's prompt for the first turn holds that turn's text" "$T1" "$(prompt_turn 1)"
check "the first matcher prompt lists the three unused segments, each as id, session turn and segment text" \
  "[[\"$P1S\",\"$P1_TURN\",$P1_JSON],[\"$P2S0\",\"$P2_TURN\",\"50 per page\"],[\"$P2S1\",\"$P2_TURN\",\"  and hide the drafts \\n- keep the drafts hidden\"]]" \
  "$(prompt_segments 1 '[.[] | [.id, .session_turn, .segment]]')"
check "a segment's fields in the prompt are id, label, order, run, segment and session_turn only" '["id","label","order","run","segment","session_turn"]' "$(prompt_segments 1 '.[0] | keys')"
check "each segment in the prompt carries the run it came from and its order among that run's owner messages" \
  "[[\"$P1S\",\"R\",1],[\"$P2S0\",\"R\",2],[\"$P2S1\",\"R\",2]]" "$(prompt_segments 1 '[.[] | [.id, .run, .order]]')"
check "the second prompt lists only the segments not yet used" "[\"$P2S0\",\"$P2S1\"]" "$(prompt_segments 2 '[.[].id]')"
check "the third prompt lists no segment" "[]" "$(prompt_segments 3 '[.[].id]')"
check "every matcher call is made with --no-session-persistence, so the CLI keeps no session of it" "true|true|true" "$(matcher_persistence 1 2 3)"
check "the driver waits on the session with rex wait and no timeout argument" "[wait][-s][sess-1][blk-1]" "$(grep '^\[wait\]' "$SIDE/rex.log")"
check "every matcher call is made with --strict-mcp-config, so no MCP server of the user's configuration loads" "true|true|true" "$(matcher_strict 1 2 3)"
check "no matcher prompt or output is left in the eval home or TMPDIR" "0 0" \
  "$(grep -rlF 'RECORDED SEGMENTS' "$EV" | wc -l | tr -d ' ') $(ls -A "$T/tmpd" | wc -l | tr -d ' ')"
check "a run in which every answer is typed and sent prints nothing to the driver tab" '""' "$(stdout_json)"

# Scenario: a question the recorded run has no answer for pulls the owner in;
# the owner's answer is recorded and the driver carries on. One row per way
# the matcher can say it found no usable segment.
UNKNOWN="99999999-9999-4999-8999-999999999999#0"
no_segment() { answer "prune run" true "null=null"; }
unknown_segment() { answer "prune run" true "null=$UNKNOWN"; }
no_questions() { answer "prune run" true; }
questions_missing() { answer_result "prune run" '{"asks": true}'; }
for matcher_row in \
  "no_segment|the matcher names no segment for the question" \
  "unknown_segment|the matcher names a segment id R does not hold" \
  "no_questions|the matcher says the turn asks but lists no question" \
  "questions_missing|the matcher's answer has no questions field"; do
  fn="${matcher_row%%|*}"; what="${matcher_row#*|}"
  fresh
  reply 1 "$T2"; reply 2 "$T_DONE"
  "$fn"; answer "Nothing more" false
  start r2
  until_true logged "[window][focus]"
  sleep 0.6
  before_typed="$(typed)"; before_state="$(running)"
  owner "weekly"
  finish
  check "when $what, the driver types nothing but R's first message before the owner answers" "$FIRST_JSON" "$before_typed"
  check "when $what, the driver keeps waiting on the owner" "running" "$before_state"
  check "when $what, the tab is renamed, focused, renamed back after the owner types, and closed at the end" \
    "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
  check "when $what, the owner's answer is recorded as the owner's" '{"n":1,"source":"owner"}' "$(replay_lines "$EV/runs/r2/replay.jsonl")"
  check "when $what, no failure reason is printed" "0" "$(grep -cE 'exited|not the expected JSON' "$T/err")"
  check "when $what, the driver carries on with the session's next turn and ends the run with /exit, exit 0" \
    "0 $FIRST_JSON|\"/exit\"" "$STATUS $(typed)"
done

# Scenario: output of the matcher that is not the expected JSON pulls the
# owner in, like a segment that is not found, and the failure reason goes to
# stderr. One row per way the matcher can fail; each prints LEAK, which must
# stay out of every place the run writes, stderr included.
LEAK="MATCHER-SAID-THIS"
not_that_json() { answer_raw "prune run" "{\"result\":\"The first segment, $LEAK.\"}"; }
not_json_at_all() { answer_raw "prune run" "garbage, $LEAK, not even JSON"; }
matcher_fails() { row "prune run" "$LEAK" 1; }
wrong_shape() { answer_raw "prune run" "$(jq -nc --arg r "{\"asks\":\"yes\",\"why\":\"$LEAK\"}" '{result:$r}')"; }
questions_not_a_list() { answer_raw "prune run" "$(jq -nc --arg r "{\"asks\":true,\"questions\":\"$LEAK\"}" '{result:$r}')"; }
refused_not_a_list() { answer_raw "prune run" "$(jq -nc --arg r '{"asks":true,"questions":[{"number":null,"segment":null,"refused":"x"}]}' '{result:$r}')"; }
refused_holds_a_number() { answer_raw "prune run" "$(jq -nc --arg r '{"asks":true,"questions":[{"number":null,"segment":null,"refused":[1]}]}' '{result:$r}')"; }
cli_error() { answer_raw "prune run" "$(jq -nc --arg r "{\"asks\": true, \"questions\": []} $LEAK" '{is_error:true,result:$r}')"; }
NOT_JSON='matcher.*output is not the expected JSON'
for matcher_row in \
  "not_that_json|$NOT_JSON|the matcher's result is not the JSON asked for" \
  "not_json_at_all|$NOT_JSON|the matcher prints something that is not JSON" \
  "matcher_fails|matcher.*exited[^0-9]*1|the matcher exits non-zero" \
  "wrong_shape|$NOT_JSON|the matcher's result is JSON of the wrong shape" \
  "questions_not_a_list|$NOT_JSON|the matcher's questions field is not a list" \
  "cli_error|$NOT_JSON|the CLI's JSON has is_error true" \
  "refused_not_a_list|$NOT_JSON|a question's refused field is a string, not a list" \
  "refused_holds_a_number|$NOT_JSON|a question's refused field holds a number, not ids"; do
  fn="${matcher_row%%|*}"; rest="${matcher_row#*|}"; reason="${rest%%|*}"; what="${rest#*|}"
  fresh
  reply 1 "$T2"; reply 2 "$T_DONE"
  "$fn"; answer "Nothing more" false
  start rm
  until_true logged "[window][focus]"
  sleep 0.6
  before_typed="$(typed)"; before_state="$(running)"
  owner "weekly"
  finish
  check "when $what, the driver types nothing but R's first message before the owner answers" "$FIRST_JSON" "$before_typed"
  check "when $what, the driver keeps waiting on the owner" "running" "$before_state"
  check "when $what, the tab is renamed, focused, renamed back after the owner types, and closed at the end" \
    "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
  check "when $what, the owner's answer is recorded as the owner's" '{"n":1,"source":"owner"}' "$(replay_lines "$EV/runs/rm/replay.jsonl")"
  check "when $what, the run carries on with the session's next turn and ends with /exit, exit 0" \
    "0 $FIRST_JSON|\"/exit\"" "$STATUS $(typed)"
  check "when $what, stderr states the failure reason" "yes" "$(grep -qE "$reason" "$T/err" && echo yes || echo no)"
  check "when $what, the matcher's output is in neither stderr nor the eval home" "0" "$(grep -rlF "$LEAK" "$T/err" "$EV" | wc -l | tr -d ' ')"
  check "when $what, nothing is printed to the driver tab, only the reason to stderr" '""' "$(stdout_json)"
  check "when $what, nothing is pre-filled into the session's input box" '""' "$(box)"
done

# Scenario: the tab is closed and the wait stopped on any exit, not only
# through fail(): here the exit comes from a rex call that fails under set -e.
fresh
touch "$SIDE/rename-fails" "$SIDE/wait-hangs"
reply 1 "$T2"
no_segment
start rt; finish
check "a failing rex call outside fail() makes replay.sh exit non-zero" "nonzero" "$([ "$STATUS" -ne 0 ] && echo nonzero || echo zero)"
check "it still closes the session tab exactly once, and no tab is left open" "1 0" "$(grep -cF "$CLOSE" "$SIDE/rex.log") $(open_tabs)"
check "it stops the background rex wait" "gone" "$(wait_pid_state)"
touch "$SIDE/release"

# Scenario: the driver puts no time limit on the owner while pulled in.
fresh
reply 1 "$T2"; reply 2 "$T_DONE"
no_segment; answer "Nothing more" false
FIRST_TIMEOUT=1 start rl
until_true logged "[window][focus]"
sleep 3
before_state="$(running)"
owner "weekly"
finish
unset FIRST_TIMEOUT
check "with REPLAY_FIRST_TIMEOUT=1 the driver is still waiting on the pulled-in owner after 3 seconds" "running" "$before_state"
check "when the owner then types, the run carries on and ends 0" "0 $FIRST_JSON|\"/exit\"" "$STATUS $(typed)"

# Scenario: a recorded answer is typed at most once.
fresh
reply 1 "$T1"; reply 2 "$T1_AGAIN"; reply 3 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "Nothing more" false
start r3
until_true logged "[window][focus]"
sleep 0.6
before_typed="$(typed)"
owner "all of them"
finish
check "a question asked again gets nothing typed the second time" "$FIRST_JSON|$P1_JSON" "$before_typed"
check "the repeated question pulls the owner in as an unmatched one" "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
check "the replayed answer and the owner's are recorded in order" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$P1S\"],\"from\":[{\"run\":\"R\",\"record\":\"$P1\"}]}|{\"n\":2,\"source\":\"owner\"}" "$(replay_lines "$EV/runs/r3/replay.jsonl")"
check "the matcher prompts for the turns after the first list P1's segment no more" "[\"$P1S\",\"$P2S0\",\"$P2S1\"] [\"$P2S0\",\"$P2S1\"] [\"$P2S0\",\"$P2S1\"]" \
  "$(prompt_segments 1 '[.[].id]') $(prompt_segments 2 '[.[].id]') $(prompt_segments 3 '[.[].id]')"

# Scenario: the owner ends the run while pulled in.
fresh
reply 1 "$T2"
no_segment
start r5
until_true logged "[window][focus]"
sleep 0.6
before_state="$(running)"
owner "/exit"
finish
check "while pulled in the driver waits" "running" "$before_state"
check "when the owner types /exit while pulled in, the driver exits 0" "0" "$STATUS"
check "the run directory is kept as in a run that ends on its own" \
  "plugin-commit.txt replay.jsonl replayed-from.txt transcript.jsonl workdir" "$(run_files r5)"
check "the session tab is closed and no tab is left open" "1 0" "$(grep -cF "$CLOSE" "$SIDE/rex.log") $(open_tabs)"
check "the driver typed nothing but R's first message" "$FIRST_JSON" "$(typed)"

# Scenario: a message the owner types at any time, not pulled in, is the
# owner's, and the driver waits for the session's next turn.
fresh
reply 1 "$T1"; reply 2 "$T_MID"; reply_delay 2 2
answer "Which folders" true "null=$P1S"; answer "Anything else" false
start r6
until_true in_session "$P1_MSG"
owner "actually keep the drafts"
finish
check "a message the owner types mid-run is recorded as the owner's, after the replayed one" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$P1S\"],\"from\":[{\"run\":\"R\",\"record\":\"$P1\"}]}|{\"n\":2,\"source\":\"owner\"}" "$(replay_lines "$EV/runs/r6/replay.jsonl")"
check "the driver does not pull the owner in for it" "$CLOSE" "$(rex_calls)"
check "the driver asks the matcher about the turn after the owner's message, with only that turn's text, and ends the run" \
  "2 $T_MID 0 $FIRST_JSON|$P1_JSON|\"/exit\"" \
  "$(ls "$SIDE"/matcher/*.prompt | wc -l | tr -d ' ') $(prompt_turn 2) $STATUS $(typed)"

# Rule: after a turn ends, if an owner message (or the session's /exit) is on
# the transcript before the driver types, the driver types nothing for that
# turn and discards the matcher's result, whatever it says. The owner's
# message is recorded as the owner's and the next turn is decided fresh.
# Scenario A: the owner types while the matcher is still working on a turn
# whose answer would be P1. Nothing is typed for that turn, the owner's
# message is recorded, and the next turn is decided fresh with P1 still unused.
fresh
reply 1 "$T1"; reply 2 "$T3"; reply 3 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "How many items" true "null=$P2S0" "null=$P2S1"; answer "Nothing more" false
matcher_sleeps 2
start r11
until_true in_session "$T1"
sleep 0.5
owner "actually all of them"
finish
check "an owner message typed during the matcher call for a turn: nothing is typed for that turn, the next turn's segments are typed, then /exit, exit 0" \
  "0 $FIRST_JSON|$P2_TYPED_JSON|\"/exit\"" "$STATUS $(typed)"
check "the owner's message is recorded as the owner's, the replayed answer after it" \
  "{\"n\":1,\"source\":\"owner\"}|{\"n\":2,\"source\":\"replayed\",\"segments\":[\"$P2S0\",\"$P2S1\"],\"from\":[{\"run\":\"R\",\"record\":\"$P2\"},{\"run\":\"R\",\"record\":\"$P2\"}]}" "$(replay_lines "$EV/runs/r11/replay.jsonl")"
check "the driver does not pull the owner in, and no failure is printed" "$CLOSE 0" "$(rex_calls) $(grep -c . "$T/err")"
check "the dropped decision used no segment: the second matcher prompt lists P1's and P2's segments" "[\"$P1S\",\"$P2S0\",\"$P2S1\"]" "$(prompt_segments 2 '[.[].id]')"

# Scenario B: the same timing, but the matcher names no segment for the turn
# the owner typed during. The owner is not pulled in for that turn; the next
# turn, which the matcher also finds no segment for, pulls the owner in.
fresh
reply 1 "$T2"; reply 2 "$T2"; reply 3 "$T_DONE"
no_segment; answer "Nothing more" false
matcher_sleeps 2
start r12
until_true in_session "$T2"
sleep 0.5
owner "actually daily"
until_true logged "[window][focus]"
owner "weekly"
finish
check "an owner message typed during a matcher call that names no segment does not pull the owner in for that turn; the next turn does, once, and the tab is renamed back after the owner types" \
  "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
check "both owner messages are recorded as the owner's" '{"n":1,"source":"owner"}|{"n":2,"source":"owner"}' "$(replay_lines "$EV/runs/r12/replay.jsonl")"
check "only the first message and /exit are typed, exit 0" "0 $FIRST_JSON|\"/exit\"" "$STATUS $(typed)"

# Scenario C: the owner types during a matcher call whose answer is that the
# turn asks nothing. The /exit is not typed for that turn; the next turn is
# decided fresh and ends the run.
fresh
reply 1 "$T_MID"; reply 2 "$T_DONE"
answer "Anything else" false; answer "Nothing more" false
matcher_sleeps 2
start r13
until_true in_session "$T_MID"
sleep 0.5
owner "actually all of them"
finish
check "an owner message typed during a matcher call that says the turn asks nothing: the matcher is asked about the next turn too" \
  "2" "$(ls "$SIDE"/matcher/*.prompt | wc -l | tr -d ' ')"
check "/exit is typed once, after the second turn, exit 0" "0 $FIRST_JSON|\"/exit\"" "$STATUS $(typed)"
check "the owner's message is recorded as the owner's" '{"n":1,"source":"owner"}' "$(replay_lines "$EV/runs/r13/replay.jsonl")"

# Scenario D: the owner types after the decision, before the driver types.
# The stub jq submits the owner's message when decide looks the chosen segments up
# up, so the message is on the transcript between the decision and typing.
fresh
touch "$SIDE/owner-at-lookup"
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "Nothing more" false
start r14; finish
check "an owner message that appears after the decision and before typing: nothing is typed for the turn, /exit after the next one, exit 0" \
  "0 $FIRST_JSON|\"/exit\"" "$STATUS $(typed)"
check "the owner's message is recorded as the owner's" '{"n":1,"source":"owner"}' "$(replay_lines "$EV/runs/r14/replay.jsonl")"
check "the second matcher prompt lists P1's and P2's segments unused" "[\"$P1S\",\"$P2S0\",\"$P2S1\"]" "$(prompt_segments 2 '[.[].id]')"
check "the driver does not pull the owner in, and no failure is printed" "$CLOSE 0" "$(rex_calls) $(grep -c . "$T/err")"

# Scenario E: the session exits while the driver is deciding. Nothing is typed
# into the ended session, no answer is missing, and the run ends as usual.
fresh
reply 1 "$T1"
answer "Which folders" true "null=$P1S"
matcher_sleeps 2
start r15
until_true in_session "$T1"
sleep 0.5
owner "/exit"
finish
check "a session that exits while the driver is deciding: exit 0, no 'never appeared', only the first message typed" "0 0 $FIRST_JSON" \
  "$STATUS $(grep -c 'never appeared' "$T/err") $(typed)"
check "the tab is closed once and no tab is left open" "1 0" "$(grep -cF "$CLOSE" "$SIDE/rex.log") $(open_tabs)"
check "the run directory is kept as in a run that ends on its own" \
  "plugin-commit.txt replay.jsonl replayed-from.txt transcript.jsonl workdir" "$(run_files r15)"

# Scenario F: the session exits right after the replayed answer is typed (the
# stub makes the second enter submit /exit): the answer never appeared.
fresh
echo 2 > "$SIDE/exit-on-enter"
reply 1 "$T1"
answer "Which folders" true "null=$P1S"
start r16; finish
check "a session that exits instead of taking the typed answer fails, non-zero" "nonzero" "$([ "$STATUS" -ne 0 ] && echo nonzero || echo zero)"
check "the failure says the replayed answer never appeared and shows the tab's last lines on stderr" "1 1" \
  "$(grep -c 'never appeared' "$T/err") $(grep -c canned-tab-last-line "$T/err")"
check "the tab is closed once and no tab is left open" "1 0" "$(grep -cF "$CLOSE" "$SIDE/rex.log") $(open_tabs)"

# Scenario: a queued_command whose origin is not a human (a task
# notification) is not an owner message.
task_notification() { # appended to the session's transcript as the harness would write it
  jq -nc --arg u "$(uuidgen | tr A-Z a-z)" '{type:"attachment",uuid:$u,parentUuid:null,attachment:{type:"queued_command",origin:{kind:"task-notification"},prompt:"build finished"}}' >> "$(session_file)"
}
fresh
reply 1 "$T1"; reply 2 "$T_MID"; reply_delay 2 2
answer "Which folders" true "null=$P1S"; answer "Anything else" false
start r7
until_true in_session "$P1_MSG"
task_notification
finish
check "a queued_command from a task notification is not recorded as an owner message" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$P1S\"],\"from\":[{\"run\":\"R\",\"record\":\"$P1\"}]}" "$(replay_lines "$EV/runs/r7/replay.jsonl")"
check "a queued_command from a task notification does not pull the owner in, and the run ends 0" \
  "$CLOSE 0" "$(rex_calls) $STATUS"

# Scenario: the session's first record is not the recorded first message.
fresh
touch "$SIDE/first-differs"
reply 1 "$T1"
start r8; finish
check "a session whose first user record differs from R's fails, non-zero" "nonzero" "$([ "$STATUS" -ne 0 ] && echo nonzero || echo zero)"
check "the failure names the first message and shows the tab's last lines on stderr" "1 1" \
  "$(grep -c 'spec first line' "$T/err") $(grep -c canned-tab-last-line "$T/err")"
check "the tab is closed, no tab is left open and nothing more than the first message was typed" "1 0 $FIRST_JSON" \
  "$(grep -cF "$CLOSE" "$SIDE/rex.log") $(open_tabs) $(typed)"

# Scenario: the first message is skipped by position, not by its
# <command-message> prefix: a recorded plain-text first message.
fresh
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "Nothing more" false
RSRC="$R2" start r9; finish
unset RSRC
check "a run whose recorded first message is plain text exits 0 and types it, the replayed answer and /exit" \
  "0 \"$PLAIN_FIRST\"|$P1_JSON|\"/exit\"" "$STATUS $(typed)"
check "the session's own plain first message is not recorded as an owner message" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$P1S\"],\"from\":[{\"run\":\"R2\",\"record\":\"$P1\"}]}" "$(replay_lines "$EV/runs/r9/replay.jsonl")"

# Scenario: a compacted recorded transcript. P1 before the boundary and P2
# after it both give segments; the summary is neither a segment nor an owner message.
fresh
reply 1 "$T1"; reply 2 "$T3"; reply 3 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "How many items" true "null=$P2S0" "null=$P2S1"; answer "Nothing more" false
RSRC="$R3" start r10; finish
unset RSRC
check "a compacted recorded run replays: first message, P1 from before the boundary, P2 from after it, /exit, exit 0" \
  "0 $FIRST_JSON|$P1_JSON|$P2_TYPED_JSON|\"/exit\"" "$STATUS $(typed)"
check "the first matcher prompt lists the segments of P1 and P2 with the turns recorded around them" \
  "[[\"$P1S\",\"$P1_TURN\",$P1_JSON],[\"$P2S0\",\"$P2_TURN\",\"50 per page\"],[\"$P2S1\",\"$P2_TURN\",\"  and hide the drafts \\n- keep the drafts hidden\"]]" \
  "$(prompt_segments 1 '[.[] | [.id, .session_turn, .segment]]')"
check "the compaction summary is in no matcher prompt and is never typed" "0 0" \
  "$(grep -rlF SUMMARY-TEXT-MARKER "$SIDE/matcher" | wc -l | tr -d ' ') $(typed | grep -cF SUMMARY-TEXT-MARKER)"

# Scenario: a turn answered by parts of one multi-part message. R4's first
# message holds four segments; the matcher covers three questions with three
# of them, which are typed as one message, labelled 1, 2, 3 (the turn's
# questions are unnumbered), joined by a blank line.
fresh
reply 1 "$PM_TURN"; reply 2 "$T_DONE"
answer "How often should prune run, which" true "null=$PM0" "null=$PM1" "null=$PM3"; answer "Nothing more" false
RSRC="$R4" start s1; finish
unset RSRC
check "a turn answered by three segments of one message types them as one labelled message, then /exit, exit 0" \
  "0 $FIRST_JSON|\"1: weekly\\n\\n2: all folders\\nincluding the archive\\n\\n3: fifty items\"|\"/exit\"" "$STATUS $(typed)"
check "the session's user record for the answer equals the labelled joined text byte for byte" \
  "[\"1: weekly\\n\\n2: all folders\\nincluding the archive\\n\\n3: fifty items\"]" "$(owner_messages_in_session "$EV/runs/s1/transcript.jsonl")"
check "replay.jsonl lists every typed segment in typed order" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$PM0\",\"$PM1\",\"$PM3\"],\"from\":[{\"run\":\"R4\",\"record\":\"$PM\"},{\"run\":\"R4\",\"record\":\"$PM\"},{\"run\":\"R4\",\"record\":\"$PM\"}]}" "$(replay_lines "$EV/runs/s1/replay.jsonl")"
check "the next matcher prompt lists only the segments not yet used" "[\"$PM2\",\"$PN0\",\"$PN1\"]" "$(prompt_segments 2 '[.[].id]')"
check "the matcher's prompt says a bare option letter matches only with the same options under the same letters" "1" \
  "$(grep -cF 'same options under the same letters' "$SIDE/matcher/01.prompt")"

# Scenario: a turn needing segments from two messages (two messages).
fresh
reply 1 "Should prune run nightly, and should the drafts stay hidden?"; reply 2 "$T_DONE"
answer "Should prune run nightly" true "null=$PM2" "null=$PN0"; answer "Nothing more" false
RSRC="$R4" start s2; finish
unset RSRC
check "a turn answered by segments of two messages types them as one labelled message, exit 0" \
  "0 $FIRST_JSON|\"1: time for prune: nightly\\n\\n2: keep the drafts hidden\"|\"/exit\"" "$STATUS $(typed)"
check "replay.jsonl lists the segments of both messages" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$PM2\",\"$PN0\"],\"from\":[{\"run\":\"R4\",\"record\":\"$PM\"},{\"run\":\"R4\",\"record\":\"$PN\"}]}" "$(replay_lines "$EV/runs/s2/replay.jsonl")"

# Rule: labels follow the turn's numbering. Every question numbered: the turn's
# own numbers; otherwise 1, 2, ... in order asked; one unnumbered question is
# typed bare. Row: name, match, turn text, answer entries, typed message.
TURN_13=$'1. How often should prune run?\n3. Which folders should it scan?'
TURN_MIXED=$'1. How often should prune run?\nAlso, which folders should it scan?'
TURN_UNNUMBERED_THEN_PAIR=$'Should prune run at all?\n1. How often should it run?\n2. Which folders should it scan?'
TURN_ONE=$'1. How often should prune run?'
TURN_2=$'2. Which prune schedule should it use?'
TURN_12=$'1. How often should prune run?\n2. Which folders should it scan?'
TURN_0=$'0. How often should prune run?\n1. Which folders should it scan?'
TURN_MIDLINE=$'1. How often should prune run?\nSee point 3. of the plan about which folders it should scan.'
TURN_DASH_QUOTE=$'- 1. How often should prune run?\n> 3: Which folders should it scan?'
TURN_STAR_PAREN=$'  * 1) How often should prune run?\n(3) Which folders should it scan?'
for label_row in \
  "numbered 1 and 3|How often should prune run?|$TURN_13|1=$PM0 3=$PM1|\"1: weekly\\n\\n3: all folders\\nincluding the archive\"" \
  "numbers on lines led by a dash and a quote mark|How often should prune run?|$TURN_DASH_QUOTE|1=$PM0 3=$PM1|\"1: weekly\\n\\n3: all folders\\nincluding the archive\"" \
  "numbers on lines led by a star and a parenthesis|How often should prune run?|$TURN_STAR_PAREN|1=$PM0 3=$PM1|\"1: weekly\\n\\n3: all folders\\nincluding the archive\"" \
  "two unnumbered|How often should prune run, and|How often should prune run, and which folders should it scan?|null=$PM0 null=$PM1|\"1: weekly\\n\\n2: all folders\\nincluding the archive\"" \
  "a single numbered 2|Which prune schedule|$TURN_2|2=$PM3|\"2: fifty items\"" \
  "a single unnumbered|Which prune schedule|Which prune schedule should it use?|null=$PM3|\"fifty items\""; do
  IFS='|' read -r -d '' name match turn entries typed_json <<< "$label_row"
  typed_json="${typed_json%$'\n'}"
  fresh
  reply 1 "$turn"; reply 2 "$T_DONE"
  answer "$match" true $entries; answer "Nothing more" false
  RSRC="$R4" start sl; finish
  unset RSRC
  check "for a turn with $name question(s), the typed message is $typed_json" "0 $FIRST_JSON|$typed_json|\"/exit\"" "$STATUS $(typed)"
done

# Scenario: a segment already used is named again: nothing is typed and the
# owner is pulled in.
fresh
reply 1 "How often should prune run?"; reply 2 "Sorry, asking again: How often should prune run?"; reply 3 "$T_DONE"
answer "How often should prune run?" true "null=$PM0"; answer "Nothing more" false
RSRC="$R4" start s3
until_true logged "[window][focus]"
sleep 0.6
before_typed="$(typed)"
owner "every week"
finish
unset RSRC
check "a used segment named again gets nothing typed: only the first message and the first answer are typed before the owner answers" \
  "$FIRST_JSON|\"weekly\"" "$before_typed"
check "the used segment pulls the owner in" "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
check "the replayed answer and the owner's are recorded in order" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$PM0\"],\"from\":[{\"run\":\"R4\",\"record\":\"$PM\"}]}|{\"n\":2,\"source\":\"owner\"}" "$(replay_lines "$EV/runs/s3/replay.jsonl")"

# Scenario: an answer the driver cannot use pulls the owner in for the whole
# turn: nothing is typed and nothing is pre-filled (every question has a
# segment, yet the segments or the labelling are unusable). One row per way.
TWO_Q="How often should prune run, and which folders should it scan?"
segment_twice_in_answer() { RSRC="$R4"; reply 1 "$TWO_Q"; answer "How often should prune run, and" true "null=$PM0" "null=$PM0" ; BOX='""'; UNUSED="[\"$PM0\",\"$PM1\",\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
mixed_numbering() { RSRC="$R4"; reply 1 "$TURN_MIXED"; answer "How often should prune run?" true "2=$PM0" "null=$PM1" ; BOX='"weekly\n\nall folders\nincluding the archive"'; UNUSED="[\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
unnumbered_then_numbered_pair() { RSRC="$R4"; reply 1 "$TURN_UNNUMBERED_THEN_PAIR"; answer "Should prune run at all?" true "null=$PM0" "1=$PM1" "2=$PM3" ; BOX='"weekly\n\nall folders\nincluding the archive\n\nfifty items"'; UNUSED="[\"$PM2\",\"$PN0\",\"$PN1\"]"; }
unknown_segment_with_number() { RSRC="$R4"; reply 1 "$TURN_ONE"; answer "How often should prune run?" true "1=$UNKNOWN" ; BOX='""'; UNUSED="[\"$PM0\",\"$PM1\",\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
option_letter_with_other_options() { RSRC="$R5"; reply 1 "$LAYOUT_TURN"; answer "Which layout" true "null=null" ; BOX='""'; UNUSED="[\"$PO#0\"]"; }
numbers_repeat() { RSRC="$R4"; reply 1 "$TURN_12"; answer "How often should prune run?" true "1=$PM0" "1=$PM1" ; BOX='"weekly\n\nall folders\nincluding the archive"'; UNUSED="[\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
number_fraction() { RSRC="$R4"; reply 1 "$TURN_12"; answer "How often should prune run?" true "1.5=$PM0" "2=$PM1" ; BOX='"weekly\n\nall folders\nincluding the archive"'; UNUSED="[\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
number_negative() { RSRC="$R4"; reply 1 "$TURN_12"; answer "How often should prune run?" true "1=$PM0" "-2=$PM1" ; BOX='"weekly\n\nall folders\nincluding the archive"'; UNUSED="[\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
number_zero() { RSRC="$R4"; reply 1 "$TURN_0"; answer "How often should prune run?" true "0=$PM0" "1=$PM1" ; BOX='"weekly\n\nall folders\nincluding the archive"'; UNUSED="[\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
number_not_in_turn() { RSRC="$R4"; reply 1 "$TURN_12"; answer "How often should prune run?" true "1=$PM0" "3=$PM1" ; BOX='"weekly\n\nall folders\nincluding the archive"'; UNUSED="[\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
single_number_not_in_turn() { RSRC="$R4"; reply 1 "$TURN_ONE"; answer "How often should prune run?" true "2=$PM0" ; BOX='"weekly"'; UNUSED="[\"$PM1\",\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
number_only_mid_line() { RSRC="$R4"; reply 1 "$TURN_MIDLINE"; answer "How often should prune run?" true "1=$PM0" "3=$PM1" ; BOX='"weekly\n\nall folders\nincluding the archive"'; UNUSED="[\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
number_not_digits() { RSRC="$R4"; reply 1 "$TURN_ONE"; answer_result "How often should prune run?" "$(jq -nc --arg s "$PM0" '{asks:true,questions:[{number:"one",segment:$s}]}')" ; BOX='"weekly"'; UNUSED="[\"$PM1\",\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
TURN_AB=$'a) How often should prune run?\nb) Which folders should it scan?'
TURN_AB_WORD=$'a table or a grid, how often should prune run?\nb) Which folders should it scan?'
letters_not_in_turn() { RSRC="$R10"; reply 1 "$TURN_AB"; answer "How often should prune run?" true "a=$PL0" "c=$PL1" ; BOX='"a: weekly\n\nB) all folders\nincluding the archive"'; UNUSED="[\"$PL2\",\"$PL3\",\"$PL4\",\"$PL5\"]"; }
letters_repeat_by_case() { RSRC="$R10"; reply 1 "$TURN_AB"; answer "How often should prune run?" true "a=$PL0" "A=$PL1" ; BOX='"a: weekly\n\nB) all folders\nincluding the archive"'; UNUSED="[\"$PL2\",\"$PL3\",\"$PL4\",\"$PL5\"]"; }
numbers_with_letters() { RSRC="$R10"; reply 1 $'1) How often should prune run?\nb) Which folders should it scan?'; answer "How often should prune run?" true "1=$PL0" "b=$PL1" ; BOX='"a: weekly\n\nB) all folders\nincluding the archive"'; UNUSED="[\"$PL2\",\"$PL3\",\"$PL4\",\"$PL5\"]"; }
letter_only_starts_a_word() { RSRC="$R10"; reply 1 "$TURN_AB_WORD"; answer "how often should prune run?" true "a=$PL0" "b=$PL1" ; BOX='"a: weekly\n\nB) all folders\nincluding the archive"'; UNUSED="[\"$PL2\",\"$PL3\",\"$PL4\",\"$PL5\"]"; }
letter_word_as_label() { RSRC="$R10"; reply 1 "$TURN_AB"; answer "How often should prune run?" true "ab=$PL0" "b=$PL1" ; BOX='"a: weekly\n\nB) all folders\nincluding the archive"'; UNUSED="[\"$PL2\",\"$PL3\",\"$PL4\",\"$PL5\"]"; }
letters_with_one_unlabelled() { RSRC="$R10"; reply 1 "$TURN_AB"; answer "How often should prune run?" true "a=$PL0" "null=$PL1" ; BOX='"a: weekly\n\nB) all folders\nincluding the archive"'; UNUSED="[\"$PL2\",\"$PL3\",\"$PL4\",\"$PL5\"]"; }
for refusal_row in \
  "letters_not_in_turn|the turn lists a) and b) and a question's letter is c" \
  "letters_repeat_by_case|two questions get the letters a and A" \
  "numbers_with_letters|its questions are labelled 1 and b" \
  "letter_only_starts_a_word|the turn has the letter a only as the word a at a line start" \
  "letter_word_as_label|a question's label is the word ab" \
  "letters_with_one_unlabelled|its questions are labelled a and none" \
  "segment_twice_in_answer|the matcher names one segment for both of its questions" \
  "mixed_numbering|its questions are partly numbered (2 and none)" \
  "unnumbered_then_numbered_pair|it asks an unnumbered question, then a numbered pair" \
  "unknown_segment_with_number|a numbered question names a segment id R does not hold" \
  "option_letter_with_other_options|the only recorded answer is a bare letter B for other options" \
  "numbers_repeat|two questions of a numbered turn get the number 1 twice" \
  "number_fraction|a question's number is 1.5" \
  "number_negative|a question's number is -2" \
  "number_zero|a question's number is 0" \
  "number_not_in_turn|the turn lists 1. and 2. and a question's number is 3" \
  "single_number_not_in_turn|the turn's one question is numbered 1 and the matcher says 2" \
  "number_only_mid_line|a number (3) appears in the turn only in the middle of a line, not as a question number" \
  "number_not_digits|a question's number is the string one"; do
  fn="${refusal_row%%|*}"; what="${refusal_row#*|}"
  fresh
  reply 2 "$T_DONE"
  "$fn"; answer "Nothing more" false
  start sp
  until_true logged "[window][focus]"
  sleep 0.6
  before_typed="$(typed)"; before_box="$(box)"
  owner "weekly"
  finish
  unset RSRC
  check "when $what, nothing but R's first message is typed for the turn" "$FIRST_JSON" "$before_typed"
  check "when $what, the session's input box holds $BOX" "$BOX" "$before_box"
  check "when $what, the segments pre-filled are used and the others are not: the next matcher prompt lists only the unused ones" "$UNUSED" "$(prompt_segments 2 '[.[].id]')"
  check "when $what, the owner is pulled in for the turn and the tab is renamed back after the owner types" "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
  check "when $what, the owner's answer is recorded as the owner's" '{"n":1,"source":"owner"}' "$(replay_lines "$EV/runs/sp/replay.jsonl")"
  check "when $what, the matcher's prompt says a bare option letter matches only with the same options under the same letters" "1" \
    "$(grep -cF 'same options under the same letters' "$SIDE/matcher/01.prompt")"
done

# Scenario: the segmenting itself, seen through the segments the first matcher
# prompt lists for R4: a numbered line in three punctuations, a paragraph that
# starts with a word and a colon, a paragraph after a blank line, and a
# continuation line that stays in its segment. A numeric label is removed from
# the text, nothing else changes.
fresh
reply 1 "$T_MID"
answer "Anything else" false
RSRC="$R4" start sg; finish
unset RSRC
check "the first matcher prompt lists R4's segments: only a numeric label is stripped, a word-led paragraph keeps its words and has no label" \
  "[[\"$PM0\",\"1\",\"weekly\"],[\"$PM1\",\"2\",\"all folders\\nincluding the archive\"],[\"$PM2\",null,\"time for prune: nightly\"],[\"$PM3\",null,\"fifty items\"],[\"$PN0\",\"3\",\"keep the drafts hidden\"],[\"$PN1\",\"4\",\"yes\"]]" \
  "$(prompt_segments 1 '[.[] | [.id, .label, .segment]]')"
check "the matcher's prompt no longer calls any line a labelled line" "no" "$(grep -qF 'labelled line' "$SIDE/matcher/01.prompt" && echo yes || echo no)"
check "the matcher's prompt says a numeric label is the one kept apart in the label field" "yes" "$(grep -qF 'numeric label' "$SIDE/matcher/01.prompt" && echo yes || echo no)"
check "the matcher's prompt no longer says a single-letter label such as a:, a) or a. is kept apart in the label field" "no" \
  "$(grep -qF '"a:", "a)" or "a."' "$SIDE/matcher/01.prompt" && echo yes || echo no)"
check "each segment carries the session turn its message answered" \
  "[\"$PM_TURN\",\"$PM_TURN\",\"$PM_TURN\",\"$PM_TURN\",\"$PN_TURN\",\"$PN_TURN\"]" "$(prompt_segments 1 '[.[].session_turn]')"

# Scenario: only a numeric label is a label. Letter and word labels stay in
# the owner's words (one paragraph, label null); a time and a decimal are not
# labels; a numbered line still labels its segment, and a line that is not
# numerically labelled continues it.
fresh
reply 1 "$T_MID"
answer "Anything else" false
RSRC="$R6" start sw; finish
unset RSRC
check "the first matcher prompt lists R6's segments: letter, word, time and decimal lines are unlabelled paragraphs; a word line after a numbered line continues it" \
  "[[\"$PW0\",null,\"A: and we need to specify a timeout\"],[\"$PW1\",null,\"no: keep the drafts\"],[\"$PW2\",null,\"10:30 is when the job runs\"],[\"$PW3\",null,\"3.5 hours\"],[\"$PW4\",\"1\",\"weekly\\nno: not on sundays\"]]" \
  "$(prompt_segments 1 '[.[] | [.id, .label, .segment]]')"

# Scenario: a segment that starts with a letter and a colon is typed with the
# turn's question number in front and its own text unchanged.
fresh
reply 1 $'1. What should we specify?'; reply 2 "$T_DONE"
answer "What should we specify?" true "1=$PW0"; answer "Nothing more" false
RSRC="$R6" start sx; finish
unset RSRC
check "a segment that starts with a word and a colon is typed after the turn's number, its text unchanged, then /exit, exit 0" \
  "0 $FIRST_JSON|\"1: A: and we need to specify a timeout\"|\"/exit\"" "$STATUS $(typed)"

# Scenario: a number given as a digit string is a whole positive integer too.
fresh
reply 1 "$TURN_ONE"; reply 2 "$T_DONE"
answer_result "How often should prune run?" "$(jq -nc --arg s "$PM0" '{asks:true,questions:[{number:"1",segment:$s}]}')"; answer "Nothing more" false
RSRC="$R4" start sd; finish
unset RSRC
check "a question numbered with the digit string 1, which the turn uses, is typed as 1, then /exit, exit 0" \
  "0 $FIRST_JSON|\"1: weekly\"|\"/exit\"" "$STATUS $(typed)"

# Scenario: the replay log marks the record the driver matched, not any record
# with the typed text. The owner types "no" while pulled in, the driver replays
# an answer whose text is also "no", then the owner types "no" mid-run: three
# records with one text, only the second replayed.
fresh
reply 1 "Should prune run at all?"; reply 2 "Should the drafts stay hidden?"; reply 3 "$T_MID"; reply_delay 3 2
answer "prune run at all" true "null=null"; answer "drafts stay hidden" true "null=$PA0"; answer "Anything else" false
RSRC="$R7" start ru
until_true logged "[window][focus]"
sleep 0.6
owner "no"
until_true test -e "$SIDE/typed/0002"
owner "no"
finish
unset RSRC
check "the run types the first message, the replayed no and /exit, exit 0" "0 $FIRST_JSON|\"no\"|\"/exit\"" "$STATUS $(typed)"
check "replay.jsonl logs the owner's no before the replayed no as the owner's, the replayed no as replayed, and the owner's later no as the owner's" \
  "{\"n\":1,\"source\":\"owner\"}|{\"n\":2,\"source\":\"replayed\",\"segments\":[\"$PA0\"],\"from\":[{\"run\":\"R7\",\"record\":\"$PA\"}]}|{\"n\":3,\"source\":\"owner\"}" "$(replay_lines "$EV/runs/ru/replay.jsonl")"

# Scenario: the owner's yes comes first, the replayed answer, also yes, later.
fresh
reply 1 "Should prune run at all?"; reply 2 "Should old items be pruned?"; reply 3 "$T_DONE"
answer "prune run at all" true "null=null"; answer "old items be pruned" true "null=$PB0"; answer "Nothing more" false
RSRC="$R7" start rv
until_true logged "[window][focus]"
sleep 0.6
owner "yes"
finish
unset RSRC
check "the run types the first message, the replayed yes and /exit, exit 0" "0 $FIRST_JSON|\"yes\"|\"/exit\"" "$STATUS $(typed)"
check "replay.jsonl logs the owner's earlier yes as the owner's and the replayed yes as replayed" \
  "{\"n\":1,\"source\":\"owner\"}|{\"n\":2,\"source\":\"replayed\",\"segments\":[\"$PB0\"],\"from\":[{\"run\":\"R7\",\"record\":\"$PB\"}]}" "$(replay_lines "$EV/runs/rv/replay.jsonl")"

# Scenario: a replay.jq in the directory replay.sh runs from (the eval home) is
# not the harness's: jq's include finds it before the -L directory. Every
# definition the driver uses fails loudly there.
fresh
for decoy_dir in "$EV" "$EV/live"; do
  mkdir -p "$decoy_dir"
  cat > "$decoy_dir/replay.jq" <<'DECOY'
def first_message_text: error("decoy");
def first_user_content: error("decoy");
def segments: error("decoy");
def session_events: error("decoy");
def owner_messages: error("decoy");
def replay_log($typed): error("decoy");
DECOY
done
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "Nothing more" false
start rj; finish
check "a decoy replay.jq in the directory replay.sh runs from is ignored: exit 0 with the first message, the replayed answer and /exit typed" \
  "0 $FIRST_JSON|$P1_JSON|\"/exit\"" "$STATUS $(typed)"
check "with the decoy there replay.jsonl still logs the replayed answer" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$P1S\"],\"from\":[{\"run\":\"R\",\"record\":\"$P1\"}]}" "$(replay_lines "$EV/runs/rj/replay.jsonl")"

# Scenario: the session's own rewound draft is logged once, as the final answer.
# The owner is pulled in, types a draft, rewinds (the stub session makes the
# next user record a sibling of the draft) and types the real answer.
fresh
reply 1 "$T2"; reply 2 "$T_DONE"; reply_silent 2 1
no_segment; answer "Nothing more" false
start rw
until_true logged "[window][focus]"
owner "a draft the owner then rewound"
until_true in_session "a draft the owner then rewound"
owner "@rewind"
owner "weekly"
finish
check "the session's transcript holds the draft and the real answer as two user records with one parent" "[2,1]" \
  "$(jq -sc '[.[] | select(.type=="user" and (.message.content|type)=="string" and (.message.content|startswith("<")|not))] | [length, (map(.parentUuid) | unique | length)]' "$EV/runs/rw/transcript.jsonl")"
check "replay.jsonl holds the real answer once and no line for the rewound draft" '{"n":1,"source":"owner"}' "$(replay_lines "$EV/runs/rw/replay.jsonl")"
check "the run ends with /exit, exit 0" "0 $FIRST_JSON|\"/exit\"" "$STATUS $(typed)"

# Scenario: a replayed answer the owner rewinds is not on the chain, so it is
# not logged; the owner's replacement is the owner's; a later replayed answer
# is still logged as replayed though an unlogged typed text precedes it. The
# stub session gives the replayed P1 no reply, then the rewind makes the
# owner's replacement its sibling and the replacement gets the second reply.
fresh
reply 1 "$T1"; reply 2 "$T3"; reply 3 "$T_DONE"; reply_silent 2 1
answer "Which folders" true "null=$P1S"; answer "How many items" true "null=$P2S0" "null=$P2S1"; answer "Nothing more" false
start rr
until_true in_session "$P1_MSG"
owner "@rewind"
owner "the owner's own replacement"
finish
check "the run types the first message, the rewound P1, then P2's segments and /exit, exit 0" \
  "0 $FIRST_JSON|$P1_JSON|$P2_TYPED_JSON|\"/exit\"" "$STATUS $(typed)"
check "replay.jsonl logs the replacement as the owner's and the later replayed answer as replayed; the rewound replayed answer is not logged" \
  "{\"n\":1,\"source\":\"owner\"}|{\"n\":2,\"source\":\"replayed\",\"segments\":[\"$P2S0\",\"$P2S1\"],\"from\":[{\"run\":\"R\",\"record\":\"$P2\"},{\"run\":\"R\",\"record\":\"$P2\"}]}" "$(replay_lines "$EV/runs/rr/replay.jsonl")"

# Scenario: the session records something other than the typed answer.
fresh
touch "$SIDE/record-differs"
reply 1 "$T1"; reply 2 "$T_MID"
answer "Which folders" true "null=$P1S"
start rd; finish
check "a session that never records the typed answer fails at the next turn end, non-zero" "nonzero" "$([ "$STATUS" -ne 0 ] && echo nonzero || echo zero)"
check "the failure says the replayed text differs or never appeared, and shows the tab's last lines on stderr" "yes 1" \
  "$(grep -qiE 'differ|never' "$T/err" && echo yes || echo no) $(grep -c canned-tab-last-line "$T/err")"
check "the tab is closed once and no tab is left open" "1 0" "$(grep -cF "$CLOSE" "$SIDE/rex.log") $(open_tabs)"
check "the answer was typed once, and the altered record is the owner's, never counted as the replayed answer" \
  "$FIRST_JSON|$P1_JSON {\"n\":1,\"source\":\"owner\"}" \
  "$(typed) $(replay_lines "$EV/runs/rd/replay.jsonl")"

# Scenario (rule d): a recorded segment that names or accepts something this
# turn does not hold is refused by the matcher (n4-shaped: this turn proposes
# journal, the recorded owner praised publication). The stub cannot judge
# meaning; these cases prove what the matcher is shown and what the driver
# does with its answer.
JOURNAL_TURN=$'I propose the name `journal` for the section.\nDo you accept it?'
R_PQ0="refused near-match $PQ0:"'\npublication is a nice touch, the concept is required ...\nand it reads well\nrecorded turn it answered:\nI propose a name for the section.\nName: `publication`\nDo you accept it?\n\n'
fresh
reply 1 "$JOURNAL_TURN"; reply 2 "$T_DONE"
answer "journal" true "null=null=$PQ0"; answer "Nothing more" false
RSRC="$R8" start n4
until_true logged "[window][focus]"
sleep 0.6
before_typed="$(typed)"; before_box="$(box)"; before_out="$(stdout_json)"
owner "yes, journal"
finish
unset RSRC
check "the matcher is shown this turn" "$JOURNAL_TURN" "$(prompt_turn 1)"
check "the matcher is shown the recorded segment with the recorded session turn it answered" \
  "[[\"$PQ0\",\"I propose a name for the section.\\nName: \`publication\`\\nDo you accept it?\",\"publication is a nice touch, the concept is required ...\\nand it reads well\"]]" \
  "$(prompt_segments 1 '[.[] | [.id, .session_turn, .segment]]')"
for phrase in \
  'read against this turn alone' \
  'everything it names, accepts or rejects must be in this turn' \
  'matches only the same proposal' \
  'segment null' \
  'a number or a single letter' \
  '"refused"' \
  'the question is a clash' \
  '"clash"' \
  'same run'; do
  check "the matcher's prompt holds the phrase: $phrase" "yes" "$(grep -qF -- "$phrase" "$SIDE/matcher/01.prompt" && echo yes || echo no)"
done
check "when the matcher refuses the only recorded segment, nothing but the first message is typed before the owner answers" "$FIRST_JSON" "$before_typed"
check "when the matcher refuses the only recorded segment, nothing is pre-filled into the input box" '""' "$before_box"
check "when the matcher refuses the only recorded segment, the owner is pulled in and the tab renamed back after the owner types" \
  "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
check "the refused near-match is displayed on the driver tab: the segment and the recorded turn it answered, verbatim" "\"$R_PQ0\"" "$before_out"
check "the display is in no file of the eval home and not on stderr" "0 0" \
  "$(grep -rlF 'recorded turn it answered' "$EV" | wc -l | tr -d ' ') $(grep -c 'recorded turn it answered' "$T/err")"
check "the owner's answer is recorded as the owner's and nothing was replayed" '{"n":1,"source":"owner"}' "$(replay_lines "$EV/runs/n4/replay.jsonl")"

# Scenario: typed in full, as before, for turns shaped like the recorded
# runs' n1, n2 and n9, and for letter labels.
typed_case() { # typed_case <description> <recording> <turn> <match> <expected typed json> <label=segment ...>
  local what="$1" rec="$2" turn="$3" match="$4" expected="$5"
  shift 5
  fresh
  reply 1 "$turn"; reply 2 "$T_DONE"
  answer "$match" true "$@"; answer "Nothing more" false
  RSRC="$rec" start tc; finish
  unset RSRC
  check "for $what, the typed message is $expected, then /exit, exit 0" "0 $FIRST_JSON|$expected|\"/exit\"" "$STATUS $(typed)"
  check "for $what, nothing is printed to the driver tab" '""' "$(stdout_json)"
}
TURN_123=$'1. How often should prune run?\n2. Which folders should it scan?\n3. Should the drafts stay hidden?'
typed_case "three numbered questions answered from two recorded messages" "$R4" "$TURN_123" "How often should prune run?" \
  '"1: weekly\n\n2: all folders\nincluding the archive\n\n3: keep the drafts hidden"' "1=$PM0" "2=$PM1" "3=$PN0"
typed_case "two numbered questions answered by 'phase 2: a + b, yes ...' and 'perfect'" "$R12" $'1. Which phase comes next?\n2. Is the plan fine?' "Which phase comes next?" \
  '"1: phase 2: a + b, yes ...\n\n2: perfect"' "1=$PX0" "2=$PX1"
typed_case "a single unnumbered question with one matching segment" "$R12" "Is the plan fine?" "Is the plan fine?" \
  '"perfect"' "null=$PX1"
typed_case "two questions labelled a) and b)" "$R10" "$TURN_AB" "How often should prune run?" \
  '"a: a: weekly\n\nb: B) all folders\nincluding the archive"' "a=$PL0" "b=$PL1"
typed_case "three questions labelled by letters in three punctuations" "$R10" $'a. How often should prune run?\n*b: Which folders should it scan?\n(c) How many items per page?' "How often should prune run?" \
  '"a: a: weekly\n\nb: B) all folders\nincluding the archive\n\nc: c. fifty items"' "a=$PL0" "b=$PL1" "c=$PL4"

# Scenario: the segmenting with letters, seen through the first matcher
# prompt for R10: a line that starts with a letter then : . or ) is not a
# label in a recording; a/B/c lines, "e.g. foo", "A, it's fine" and a word
# before a colon all stay text.
fresh
reply 1 "$T_MID"
answer "Anything else" false
RSRC="$R10" start sy; finish
unset RSRC
check "the first matcher prompt lists R10's segments: the a, B and c lines stay in the text with no label, like e.g., a comma after A and a word before a colon" \
  "[[\"$PL0\",null,\"a: weekly\"],[\"$PL1\",null,\"B) all folders\\nincluding the archive\"],[\"$PL2\",null,\"e.g. foo\"],[\"$PL3\",null,\"A, it's fine\"],[\"$PL4\",null,\"c. fifty items\"],[\"$PL5\",null,\"time for prune: nightly\"]]" \
  "$(prompt_segments 1 '[.[] | [.id, .label, .segment]]')"

# Scenario: a turn some questions of which are covered and some not. Nothing is
# sent. The session's input box gets the covered segments, typed line by line
# like a message but without the final enter: with the turn's labels and an
# empty marker ("N: ") for each uncovered question when the labelling is
# numbers or letters, as plain paragraphs of the covered segments when it is
# mixed or absent. The owner is pulled in and sends the answer, which is
# recorded as the owner's; the pre-filled segments stay unused. A turn with no
# covered question, or a refusal, or a covered but unusable one, pulls the owner
# in with nothing pre-filled. On every pull-in the covered and the refused
# near-match segments are displayed on the driver tab.
# Each row sets: the recording, the turn, the matcher's answer, BOX (the input
# box before the owner types, a JSON string), OUT (what the driver tab shows,
# a JSON string) and UNUSED (the segment ids the next matcher prompt lists).
PM_ALL="[\"$PM0\",\"$PM1\",\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"
PL_ALL="[\"$PL0\",\"$PL1\",\"$PL2\",\"$PL3\",\"$PL4\",\"$PL5\"]"
B_PM0="matched answer $PM0:"'\nweekly\nrecorded turn it answered:\n'"$PM_TURN"'\n\n'
B_PM1="matched answer $PM1:"'\nall folders\nincluding the archive\nrecorded turn it answered:\n'"$PM_TURN"'\n\n'
B_PM3="matched answer $PM3:"'\nfifty items\nrecorded turn it answered:\n'"$PM_TURN"'\n\n'
B_PL0="matched answer $PL0:"'\na: weekly\nrecorded turn it answered:\n'"$PL_TURN"'\n\n'
B_PL4="matched answer $PL4:"'\nc. fifty items\nrecorded turn it answered:\n'"$PL_TURN"'\n\n'
F_PM0="refused near-match $PM0:"'\nweekly\nrecorded turn it answered:\n'"$PM_TURN"'\n\n'
F_PM1="refused near-match $PM1:"'\nall folders\nincluding the archive\nrecorded turn it answered:\n'"$PM_TURN"'\n\n'
F_PN0="refused near-match $PN0:"'\nkeep the drafts hidden\nrecorded turn it answered:\n'"$PN_TURN"'\n\n'
TURN_PF3=$'1. How often should prune run?\n2. Which folders should it scan?\n3. How many items per page?'
TURN_PF3_LETTERS=$'a) How often should prune run?\nb) Which folders should it scan?\nc) How many items per page?'
TURN_PF3_MIXED=$'1. How often should prune run?\nWhich folders should it scan?\n3. How many items per page?'
TURN_PF3_FREE="How often should prune run, which folders should it scan, and how many items per page?"
TURN_PF2=$'1. How often should prune run?\n2. Which folders should it scan?'
pf_numbers_middle_missing() { RSRC="$R4"; reply 1 "$TURN_PF3"; answer "How often should prune run?" true "1=$PM0" "2=null" "3=$PM3"
  BOX='"1: weekly\n\n2: \n\n3: fifty items"'; OUT="\"$B_PM0$B_PM3\""; UNUSED="[\"$PM1\",\"$PM2\",\"$PN0\",\"$PN1\"]"; }
pf_numbers_first_missing() { RSRC="$R4"; reply 1 "$TURN_PF3"; answer "How often should prune run?" true "1=null" "2=$PM1" "3=$PM3"
  BOX='"1: \n\n2: all folders\nincluding the archive\n\n3: fifty items"'; OUT="\"$B_PM1$B_PM3\""; UNUSED="[\"$PM0\",\"$PM2\",\"$PN0\",\"$PN1\"]"; }
pf_numbers_one_of_three() { RSRC="$R4"; reply 1 "$TURN_PF3"; answer "How often should prune run?" true "1=null" "2=$PM1" "3=null"
  BOX='"1: \n\n2: all folders\nincluding the archive\n\n3: "'; OUT="\"$B_PM1\""; UNUSED="[\"$PM0\",\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
pf_letters_middle_missing() { RSRC="$R10"; reply 1 "$TURN_PF3_LETTERS"; answer "How often should prune run?" true "a=$PL0" "b=null" "c=$PL4"
  BOX='"a: a: weekly\n\nb: \n\nc: c. fifty items"'; OUT="\"$B_PL0$B_PL4\""; UNUSED="[\"$PL1\",\"$PL2\",\"$PL3\",\"$PL5\"]"; }
pf_mixed_numbering() { RSRC="$R4"; reply 1 "$TURN_PF3_MIXED"; answer "How often should prune run?" true "1=$PM0" "null=$PM1" "3=null"
  BOX='"weekly\n\nall folders\nincluding the archive"'; OUT="\"$B_PM0$B_PM1\""; UNUSED="[\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
pf_absent_labelling() { RSRC="$R4"; reply 1 "$TURN_PF3_FREE"; answer "How often should prune run, which" true "null=$PM0" "null=null" "null=$PM3"
  BOX='"weekly\n\nfifty items"'; OUT="\"$B_PM0$B_PM3\""; UNUSED="[\"$PM1\",\"$PM2\",\"$PN0\",\"$PN1\"]"; }
pf_two_unnumbered() { RSRC="$R4"; reply 1 "$TWO_Q"; answer "How often should prune run, and" true "null=$PM0" "null=null"
  BOX='"weekly"'; OUT="\"$B_PM0\""; UNUSED="[\"$PM1\",\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
pf_duplicate_number() { RSRC="$R4"; reply 1 "$TURN_PF3"; answer "How often should prune run?" true "1=$PM0" "1=null" "3=$PM3"
  BOX='"weekly\n\nfifty items"'; OUT="\"$B_PM0$B_PM3\""; UNUSED="[\"$PM1\",\"$PM2\",\"$PN0\",\"$PN1\"]"; }
pf_number_not_in_turn() { RSRC="$R4"; reply 1 "$TURN_PF2"; answer "How often should prune run?" true "1=$PM0" "3=null"
  BOX='"weekly"'; OUT="\"$B_PM0\""; UNUSED="[\"$PM1\",\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
pf_refused_near_matches() { RSRC="$R4"; reply 1 "$TURN_PF3"
  answer "How often should prune run?" true "1=$PM0" "2=null=$PM1,$UNKNOWN,$PM0,$PM1" "3=null=$PN0,$PM1"
  BOX='"1: weekly\n\n2: \n\n3: "'; OUT="\"$B_PM0$F_PM1$F_PN0\""; UNUSED="[\"$PM1\",\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
pf_none_covered_several() { RSRC="$R4"; reply 1 "$TURN_PF3"; answer "How often should prune run?" true "1=null" "2=null" "3=null"
  BOX='""'; OUT='""'; UNUSED="$PM_ALL"; }
pf_none_covered_single() { RSRC="$R4"; reply 1 "Which prune schedule should it use?"; answer "Which prune schedule" true "null=null"
  BOX='""'; OUT='""'; UNUSED="$PM_ALL"; }
pf_none_covered_with_a_refusal() { RSRC="$R4"; reply 1 "Which prune schedule should it use?"; answer "Which prune schedule" true "null=null=$PM0"
  BOX='""'; OUT="\"$F_PM0\""; UNUSED="$PM_ALL"; }
pf_full_coverage_mixed_labels() { RSRC="$R4"; reply 1 "$TURN_MIXED"; answer "How often should prune run?" true "2=$PM0" "null=$PM1"
  BOX='"weekly\n\nall folders\nincluding the archive"'; OUT="\"$B_PM0$B_PM1\""; UNUSED="[\"$PM2\",\"$PM3\",\"$PN0\",\"$PN1\"]"; }
for pf_row in \
  "pf_numbers_middle_missing|numbered 1, 2, 3 with the middle one missing" \
  "pf_numbers_first_missing|numbered 1, 2, 3 with the first one missing" \
  "pf_numbers_one_of_three|numbered 1, 2, 3 with only the middle one covered" \
  "pf_letters_middle_missing|labelled a), b), c) with the middle one missing" \
  "pf_mixed_numbering|numbered 1 and 3 with an unnumbered question between" \
  "pf_absent_labelling|three unnumbered questions with the middle one missing" \
  "pf_two_unnumbered|two unnumbered questions with the second one missing" \
  "pf_duplicate_number|a number used twice among three numbered questions, one uncovered" \
  "pf_number_not_in_turn|a question numbered 3 that the turn does not number" \
  "pf_refused_near_matches|a covered question and two uncovered ones, one naming refused near-matches (an unknown id, a matched id and a repeat among them)" \
  "pf_none_covered_several|three numbered questions none of which is covered" \
  "pf_none_covered_single|one question that is not covered" \
  "pf_none_covered_with_a_refusal|one question that is not covered and a refused near-match" \
  "pf_full_coverage_mixed_labels|every question covered but labelled 2 and none"; do
  fn="${pf_row%%|*}"; what="${pf_row#*|}"
  fresh
  reply 2 "$T_DONE"
  "$fn"; answer "Nothing more" false
  start pf
  until_true logged "[window][focus]"
  sleep 0.6
  before_typed="$(typed)"; before_box="$(box)"; before_out="$(stdout_json)"
  owner "weekly, all of them, fifty"
  finish
  unset RSRC
  check "for a turn with $what, nothing is sent: only R's first message is typed before the owner answers" "$FIRST_JSON" "$before_typed"
  check "for a turn with $what, the session's input box holds $BOX" "$BOX" "$before_box"
  check "for a turn with $what, the driver tab shows $OUT" "$OUT" "$before_out"
  check "for a turn with $what, the owner is pulled in and the tab renamed back after the owner types" "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
  check "for a turn with $what, the owner's message is recorded as the owner's, with no segments" '{"n":1,"source":"owner"}' "$(replay_lines "$EV/runs/pf/replay.jsonl")"
  check "for a turn with $what, the driver types no answer of its own: R's first message and /exit only, exit 0" "0 $FIRST_JSON|\"/exit\"" "$STATUS $(typed)"
  check "for a turn with $what, the segments pre-filled are used and the others are not: the next matcher prompt lists only the unused ones" "$UNUSED" "$(prompt_segments 2 '[.[].id]')"
  check "for a turn with $what, the display is in no file of the eval home and not on stderr" "0 0" \
    "$(grep -rlF 'recorded turn it answered' "$EV" | wc -l | tr -d ' ') $(grep -c 'recorded turn it answered' "$T/err")"
done

# Scenario: a segment that was pre-filled is used. A later matcher answer that
# names it is unusable as a whole: the owner is pulled in again, nothing is
# typed and nothing is pre-filled.
fresh
reply 1 "$TURN_PF3"; reply 2 "Which prune schedule should it use?"; reply 3 "$T_DONE"
RSRC="$R4"; answer "1. How often should prune run?" true "1=$PM0" "2=null" "3=$PM3"
answer "Which prune schedule" true "null=$PM0"; answer "Nothing more" false
start pu
focused() { [ "$(grep -cF '[window][focus]' "$SIDE/rex.log")" -ge "$1" ]; }
until_true focused 1
sleep 0.6
owner "weekly, all folders, fifty"
until_true focused 2
sleep 0.6
before_typed="$(typed)"; before_box="$(box)"
owner "every week"
finish
unset RSRC
check "a later answer that names a pre-filled segment gets nothing typed: only the first message is typed before the owner answers" "$FIRST_JSON" "$before_typed"
check "a later answer that names a pre-filled segment gets nothing pre-filled" '""' "$before_box"
check "a later answer that names a pre-filled segment pulls the owner in again, once more after each owner answer" \
  "$RENAME_ASK|$FOCUS|$RENAME_BACK|$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
check "both owner answers are recorded as the owner's and nothing was replayed" \
  '{"n":1,"source":"owner"}|{"n":2,"source":"owner"}' "$(replay_lines "$EV/runs/pu/replay.jsonl")"

# Scenario: the pre-fill is typed like a message, line by line, without the
# final enter: a send per non-empty line, ctrl+j between lines, an empty line
# only a ctrl+j, the empty marker "2: " a line of its own.
fresh
reply 1 "$TURN_PF3"; reply 2 "$T_DONE"
RSRC="$R4"; answer "How often should prune run?" true "1=$PM0" "2=null" "3=$PM3"; answer "Nothing more" false
start pc
until_true logged "[window][focus]"
sleep 0.6
before_calls="$(typing_calls)"
owner "weekly"
finish
unset RSRC
check "the pre-fill is typed after the first message as sends and ctrl+j keys, and ends with no enter" \
  "send:/bjornstack:story-definition spec first line|key:ctrl+j|send:second line <ol><li>a</li></ol>|key:enter|send:1: weekly|key:ctrl+j|key:ctrl+j|send:2: |key:ctrl+j|key:ctrl+j|send:3: fifty items" "$before_calls"

# Scenario: a partly covered turn when the owner types before the driver does:
# nothing is typed, nothing is pre-filled, nothing is displayed, the owner's
# message is recorded and the next turn is decided fresh.
fresh
reply 1 "$TURN_PF3"; reply 2 "$T_DONE"
RSRC="$R4"; answer "How often should prune run?" true "1=$PM0" "2=null" "3=$PM3"; answer "Nothing more" false
matcher_sleeps 2
start po
until_true in_session "3. How many items per page?"
sleep 0.5
owner "actually all of them"
finish
unset RSRC
check "an owner message typed during the matcher call for a partly covered turn: nothing is typed, exit 0" "0 $FIRST_JSON|\"/exit\"" "$STATUS $(typed)"
check "an owner message typed during the matcher call for a partly covered turn: nothing is pre-filled" '""' "$(box)"
check "an owner message typed during the matcher call for a partly covered turn: nothing is displayed" '""' "$(stdout_json)"
check "an owner message typed during the matcher call for a partly covered turn: the owner is not pulled in and the message is the owner's" \
  "$CLOSE {\"n\":1,\"source\":\"owner\"}" "$(rex_calls) $(replay_lines "$EV/runs/po/replay.jsonl")"

# Refusals and failures. Preconditions: nothing is started, no rex call.
break_commit() { rm "$EV/config/sources/bjornstack.commit"; }
break_plugin() { rm -rf "$COPY/plugin"; }
break_transcript() { mv "$R" "$R.away"; }
existing_run() { mkdir -p "$EV/runs/rf"; }
existing_live() { mkdir -p "$EV/live/rf"; }
for refusal in \
  "break_commit|bjornstack.commit is missing" \
  "break_plugin|the frozen plugin directory is missing" \
  "break_transcript|the recorded transcript is missing" \
  "existing_run|runs/<name> exists" \
  "existing_live|live/<name> exists"; do
  fn="${refusal%%|*}"; what="${refusal#*|}"
  fresh
  "$fn"
  files_before="$(cd "$EV" && find . | sort | paste -sd' ' -)"
  start rf; finish
  check "when $what, replay.sh exits 1 with a message and makes no rex call" "1 yes 0" \
    "$STATUS $([ -s "$T/err" ] && echo yes || echo no) $(grep -c . "$SIDE/rex.log")"
  check "when $what, nothing is added to the eval home" "$files_before" "$(cd "$EV" && find . | sort | paste -sd' ' -)"
done

# The session ends without /exit: the failure carries the tab's last lines.
fresh
reply 1 "@die"
start rg; finish
check "a session that ends without /exit exits non-zero" "nonzero" "$([ "$STATUS" -ne 0 ] && echo nonzero || echo zero)"
check "the tab's last lines go to stderr" "1" "$(grep -c canned-tab-last-line "$T/err")"
check "the session tab is closed, and no tab is left open" "1 0" "$(grep -cF "$CLOSE" "$SIDE/rex.log") $(open_tabs)"

# No transcript file within REPLAY_FIRST_TIMEOUT of the first message.
fresh
touch "$SIDE/no-transcript"
reply 1 "$T1"
FIRST_TIMEOUT=2 start rh; finish
unset FIRST_TIMEOUT
check "a session that writes no transcript file fails, non-zero" "nonzero" "$([ "$STATUS" -ne 0 ] && echo nonzero || echo zero)"
check "its tab's last lines go to stderr" "1" "$(grep -c canned-tab-last-line "$T/err")"
check "its session tab is closed, and no tab is left open" "1 0" "$(grep -cF "$CLOSE" "$SIDE/rex.log") $(open_tabs)"

# The frozen commit is copied when the run starts: a change to it while the
# session runs does not reach plugin-commit.txt.
fresh
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "Nothing more" false
matcher_sleeps 1
start ri
until_true in_session "$T1"
printf 'fedcba9876543210\n' > "$EV/config/sources/bjornstack.commit"
finish
check "plugin-commit.txt holds the commit as it was when the run started, though bjornstack.commit changed during it" \
  "0 abc123def4567890" "$STATUS $(cat "$EV/runs/ri/plugin-commit.txt")"

# The corpus. The matcher is offered the answers of every run of R's spec under
# $EV/runs as well as R's own, and the driver's replay.jsonl says where each
# typed segment came from. Other runs of the spec are built with the same
# first message as R's; a run of another spec has a different one.
C_L="cccccccc-cccc-4ccc-8ccc-cccccccccccc"; C_LS="$C_L#0"
C_PCOPY="dddddddd-dddd-4ddd-8ddd-dddddddddddd"
C_POWN="eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"; C_POWNS="$C_POWN#0"
C_LA="ffffffff-ffff-4fff-8fff-ffffffffffff"; C_LAS="$C_LA#0"
C_X="12121212-1212-4212-8212-121212121212"
T_SKIP="Which folders should a refresh skip?"
T_WHEN="When does a refresh run?"
SPEC_TEXT=$'spec first line\nsecond line <ol><li>a</li></ol>'
FILES_PLAIN="plugin-commit.txt replay.jsonl replayed-from.txt transcript.jsonl workdir"
FILES_CLASH="clashes.jsonl plugin-commit.txt replay.jsonl replayed-from.txt transcript.jsonl workdir"
other_run() { mkdir -p "$EV/runs/$1"; recorded_start "$EV/runs/$1/transcript.jsonl"; }   # other_run <name>: the first message of a run of R's spec; the caller adds turns and answers, then sets RF back to $R
settled() { local d; d="$EV/corpus/$(printf '%s' "$SPEC_TEXT" | shasum -a 256 | cut -d' ' -f1)"; mkdir -p "$d"; printf '%s\n' "$1" >> "$d/settled.jsonl"; }   # settled <json line>
# L is a live run of the spec: its owner answered "the archive" to T_SKIP.
# P is a replay of L: its first answer is a copy of L's (logged replayed), its
# second the owner's, "every 15 minutes", to T_WHEN.
corpus_runs() {
  other_run L
  recorded_turn "$T_SKIP"; recorded_answer "$C_L" "the archive"; recorded_exit
  other_run P
  recorded_turn "$T_SKIP"; recorded_answer "$C_PCOPY" "the archive"
  recorded_turn "$T_WHEN"; recorded_answer "$C_POWN" "every 15 minutes"; recorded_exit
  RF="$R"
  jq -nc --arg s "$C_LS" --arg r "$C_L" '{n:1,source:"replayed",segments:[$s],from:[{run:"L",record:$r}]}' > "$EV/runs/P/replay.jsonl"
  echo '{"n":2,"source":"owner"}' >> "$EV/runs/P/replay.jsonl"
}
# L2 answered R's own question T1 with "all of them", where R's owner said "only the ones I ticked": the two clash.
clashing_run() { other_run L2; recorded_turn "$P1_TURN"; recorded_answer "$C_LA" "all of them"; recorded_exit; RF="$R"; }

# Scenario: a replay answers from any earlier run of the spec. The session asks
# T_WHEN, which only P's owner answered; the matcher names that segment, the
# driver types it, and replay.jsonl says which run and record it came from.
# The copy P logged as replayed counts once, as L's: the matcher is offered
# "the archive" once, with L's record id.
fresh
corpus_runs
reply 1 "$T_WHEN"; reply 2 "$T_DONE"
answer "$T_WHEN" true "null=$C_POWNS"; answer "Nothing more" false
start ca; finish
check "a question only another run of the spec answered gets that run's answer typed" "0 $FIRST_JSON|\"every 15 minutes\"|\"/exit\"" "$STATUS $(typed)"
check "replay.jsonl names the run and record the typed answer came from" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$C_POWNS\"],\"from\":[{\"run\":\"P\",\"record\":\"$C_POWN\"}]}" "$(replay_lines "$EV/runs/ca/replay.jsonl")"
check "a replay that met no clash leaves no clashes.jsonl in its run directory" "$FILES_PLAIN" "$(run_files ca)"
check "the line P logged as replayed is offered once, as L's answer, not again as P's" "[\"$C_LS\"]" \
  "$(prompt_segments 1 '[.[] | select(.segment == "the archive") | .id]')"

# Scenario: another spec's run under runs/ changes nothing. Its answer to the
# same question is not offered, and the replay is R's replay.
fresh
mkdir -p "$EV/runs/other-spec"
RF="$EV/runs/other-spec/transcript.jsonl"; PREV=
rec '{type:"user",uuid:"00000000-0000-4000-8000-000000000099",message:{role:"user",content:"<command-message>bjornstack:story-definition</command-message>\n<command-name>/bjornstack:story-definition</command-name>\n<command-args>another spec entirely</command-args>"}}'
recorded_turn "$P1_TURN"; recorded_answer "$C_X" "everything"; recorded_exit
RF="$R"
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "Nothing more" false
start cb; finish
check "with another spec's run in runs/ the replay types R's answer as before" "0 $FIRST_JSON|$P1_JSON|\"/exit\"" "$STATUS $(typed)"
check "with another spec's run in runs/ the answer's source is R alone" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$P1S\"],\"from\":[{\"run\":\"R\",\"record\":\"$P1\"}]}" "$(replay_lines "$EV/runs/cb/replay.jsonl")"
check "another spec's answer is not offered to the matcher" "[]" \
  "$(prompt_segments 1 '[.[] | select(.segment == "everything") | .id]')"

# Scenario: the owner settled a clash. The dropped answer is not among the
# segments the matcher is offered, and it is never typed, even when the matcher
# names it: that answer is unknown, so the owner is pulled in.
fresh
clashing_run
settled "{\"keep\":\"$P1S\",\"drop\":[\"$C_LAS\"]}"
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "Nothing more" false
start cc; finish
check "a settled choice: the kept answer is typed and the dropped one never is" "0 $FIRST_JSON|$P1_JSON|\"/exit\"" "$STATUS $(typed)"
check "a settled choice: the dropped answer is not among the segments the matcher is offered" "[]" \
  "$(prompt_segments 1 '[.[] | select(.segment == "all of them") | .id]')"
check "a settled choice: replay.jsonl names R as the kept answer's source" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$P1S\"],\"from\":[{\"run\":\"R\",\"record\":\"$P1\"}]}" "$(replay_lines "$EV/runs/cc/replay.jsonl")"

fresh
clashing_run
settled "{\"keep\":\"$P1S\",\"drop\":[\"$C_LAS\"]}"
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=$C_LAS"; answer "Nothing more" false
start cc2
until_true logged "[window][focus]"
sleep 0.6
before_typed="$(typed)"
owner "only the ones I ticked, yes"
finish
check "a matcher that names a dropped answer gets it nowhere near the session: only the first message is typed before the owner answers" "$FIRST_JSON" "$before_typed"
check "a matcher that names a dropped answer pulls the owner in, and the answer is never typed" \
  "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE 0 $FIRST_JSON|\"/exit\"" "$(rex_calls) $STATUS $(typed)"

# Scenario: a clash met during the replay. The matcher says two answers
# answer the session's question and disagree. The driver types neither, pulls
# the owner in showing both answers with their run and record, records the
# owner's message as the owner's, and records the clash for the owner to settle
# after the run. A clash is recorded only when it was met.
fresh
clashing_run
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=null==$P1S,$C_LAS"; answer "Nothing more" false
start cd
until_true logged "[window][focus]"
sleep 0.6
before_typed="$(typed)"; before_box="$(box)"; before_out="$(stdout_json)"
owner "only the ones I ticked, and the archive"
finish
CLASH_OUT="clashing answer $P1S (run R, record $P1):"'\nonly the ones I ticked\nrecorded turn it answered:\n'"$P1_TURN"'\n\n'"clashing answer $C_LAS (run L2, record $C_LA):"'\nall of them\nrecorded turn it answered:\n'"$P1_TURN"'\n\n'
check "a clash met during the replay: neither answer is typed, only the first message before the owner answers" "$FIRST_JSON" "$before_typed"
check "a clash met during the replay: nothing is pre-filled" '""' "$before_box"
check "a clash met during the replay: the driver tab shows both answers with their run and record" "\"$CLASH_OUT\"" "$before_out"
check "a clash met during the replay: the owner is pulled in and the tab renamed back after the owner types" "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
check "a clash met during the replay: the owner's message is recorded as the owner's" '{"n":1,"source":"owner"}' "$(replay_lines "$EV/runs/cd/replay.jsonl")"
check "a clash met during the replay: clashes.jsonl records the turn's text and both answer ids" \
  "{\"question\":\"$T1\",\"answers\":[\"$P1S\",\"$C_LAS\"]}" "$(replay_lines "$EV/runs/cd/clashes.jsonl")"
check "a clash met during the replay: the run directory gains clashes.jsonl and nothing else" "$FILES_CLASH" "$(run_files cd)"
check "a clash met during the replay: the run exits 0 having typed the first message and /exit only" "0 $FIRST_JSON|\"/exit\"" "$STATUS $(typed)"
check "an unsettled clash: both answers are offered to the matcher" "[\"$C_LAS\"]" \
  "$(prompt_segments 1 '[.[] | select(.segment == "all of them") | .id]')"

# Scenario: the matcher names a segment for a question and a clash that holds
# the same segment. The clash wins: the segment is not typed, and the owner is
# pulled in as for any clash.
fresh
clashing_run
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=$P1S==$P1S,$C_LAS"; answer "Nothing more" false
start cf
until_true logged "[window][focus]"
sleep 0.6
before_typed="$(typed)"; before_box="$(box)"
owner "only the ones I ticked, and the archive"
finish
check "a segment named together with a clash that holds it: nothing is typed or pre-filled before the owner answers" "$FIRST_JSON|\"\"" "$before_typed|$before_box"
check "a segment named together with a clash that holds it: the owner is pulled in and the tab renamed back after the owner types" "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
check "a segment named together with a clash that holds it: the owner's message is recorded as the owner's" '{"n":1,"source":"owner"}' "$(replay_lines "$EV/runs/cf/replay.jsonl")"
check "a segment named together with a clash that holds it: clashes.jsonl records the clash" \
  "{\"question\":\"$T1\",\"answers\":[\"$P1S\",\"$C_LAS\"]}" "$(replay_lines "$EV/runs/cf/clashes.jsonl")"
check "a segment named together with a clash that holds it: the run exits 0 having typed the first message and /exit only" "0 $FIRST_JSON|\"/exit\"" "$STATUS $(typed)"

# Scenario: within one run the later answer stands. Run L2 answered the
# question and later, in the same run, answered it again; the matcher lists both
# as a clash. Per run only the answer with the highest order stays in the
# clash: when one id is left there is no clash and that answer is typed like
# any matched answer. When two or more are left they clash as before, listing
# only the ids left. The order of the matcher's list does not matter.
C_LB="abababab-abab-4bab-8bab-abababababab"; C_LBS="$C_LB#0"
C_Y="acacacac-acac-4cac-8cac-acacacacacac"; C_YS="$C_Y#0"
later_answer_run() { other_run L2; recorded_turn "$P1_TURN"; recorded_answer "$C_LA" "all of them"; recorded_turn "$T_WHEN"; recorded_answer "$C_LB" "mark it read again"; recorded_exit; RF="$R"; }
other_run_answer() { other_run L3; recorded_turn "$P1_TURN"; recorded_answer "$C_Y" "just the inbox"; recorded_exit; RF="$R"; }

fresh
later_answer_run
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=null==$C_LAS,$C_LBS"; answer "Nothing more" false
start cg; finish
check "two answers of one run in a clash list: the later one is typed and nothing is raised" "0 $FIRST_JSON|\"mark it read again\"|\"/exit\"" "$STATUS $(typed)"
check "two answers of one run in a clash list: replay.jsonl names the later answer's run and record" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$C_LBS\"],\"from\":[{\"run\":\"L2\",\"record\":\"$C_LB\"}]}" "$(replay_lines "$EV/runs/cg/replay.jsonl")"
check "two answers of one run in a clash list: the owner is not pulled in and no clashes.jsonl is written" "$FILES_PLAIN" "$(run_files cg)"

fresh
later_answer_run; other_run_answer
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=null==$C_LAS,$C_LBS,$C_YS"; answer "Nothing more" false
start ch
until_true logged "[window][focus]"
sleep 0.6
before_typed="$(typed)"; before_box="$(box)"
owner "only the ones I ticked, and the archive"
finish
check "a clash list holding the earlier and later answer of one run and one of another: nothing is typed or pre-filled before the owner answers" "$FIRST_JSON|\"\"" "$before_typed|$before_box"
check "a clash list holding the earlier and later answer of one run and one of another: the owner is pulled in" "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
check "a clash list holding the earlier and later answer of one run and one of another: clashes.jsonl lists only the later answer and the other run's" \
  "{\"question\":\"$T1\",\"answers\":[\"$C_LBS\",\"$C_YS\"]}" "$(replay_lines "$EV/runs/ch/clashes.jsonl")"

fresh
later_answer_run
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=null==$C_LBS,$C_LAS"; answer "Nothing more" false
start ci; finish
check "the later answer of a run stands whatever the order of the matcher's list: it is typed and no clash is recorded" \
  "0 $FIRST_JSON|\"mark it read again\"|\"/exit\" $FILES_PLAIN" "$STATUS $(typed) $(run_files ci)"

# Scenario: a clash that names an id that is unknown, or one already used,
# makes the whole answer unusable: the owner is pulled in, nothing is typed or
# pre-filled, and no clash is recorded. One row per way.
cx_unknown() { reply 1 "$T1"; reply 2 "$T_DONE"; answer "Which folders" true "null=null==$P1S,$UNKNOWN"
  BEFORE="$FIRST_JSON"; }
cx_used() { reply 1 "$T1"; reply 2 "$T2"; reply 3 "$T_DONE"; answer "Which folders" true "null=$P1S"; answer "prune run daily" true "null=null==$P1S,$C_LAS"
  BEFORE="$FIRST_JSON|$P1_JSON"; }
for cx_row in \
  "cx_unknown|an id the corpus does not hold" \
  "cx_used|an id the driver already typed"; do
  fn="${cx_row%%|*}"; what="${cx_row#*|}"
  fresh
  clashing_run
  "$fn"; answer "Nothing more" false
  start cu
  until_true logged "[window][focus]"
  sleep 0.6
  before_typed="$(typed)"; before_box="$(box)"
  owner "weekly"
  finish
  check "for a clash naming $what, nothing more is typed before the owner answers" "$BEFORE" "$before_typed"
  check "for a clash naming $what, nothing is pre-filled" '""' "$before_box"
  check "for a clash naming $what, the owner is pulled in" "$RENAME_ASK|$FOCUS|$RENAME_BACK|$CLOSE" "$(rex_calls)"
  check "for a clash naming $what, no clash is recorded" "$FILES_PLAIN" "$(run_files cu)"
done

# Scenario: a clash on one question of a turn whose other question is covered.
# The covered answer is pre-filled, the clashing question gets an empty marker,
# the owner is pulled in with both clashing answers shown, and the clash is
# recorded. The clashing answers are not used; the pre-filled one is.
fresh
clashing_run
TURN_CP=$'1. Which folders should a refresh read?\n2. How many items should a page hold?'
reply 1 "$TURN_CP"; reply 2 "$T_DONE"
answer "1. Which folders should a refresh read?" true "1=null==$P1S,$C_LAS" "2=$P2S0"; answer "Nothing more" false
start ce
until_true logged "[window][focus]"
sleep 0.6
before_typed="$(typed)"; before_box="$(box)"; before_out="$(stdout_json)"
owner $'1: all folders\n\n2: 50 per page'
finish
check "a clash on one question of two: nothing is sent, only the first message is typed before the owner answers" "$FIRST_JSON" "$before_typed"
check "a clash on one question of two: the input box holds the covered answer and an empty marker for the clashing question" '"1: \n\n2: 50 per page"' "$before_box"
check "a clash on one question of two: the driver tab shows both clashing answers with run and record" "true" \
  "$(printf '%s' "$before_out" | jq -r --arg a "clashing answer $P1S (run R, record $P1):" --arg b "clashing answer $C_LAS (run L2, record $C_LA):" '[contains($a), contains($b)] | all')"
check "a clash on one question of two: the clash is recorded with the turn's text" \
  "{\"question\":\"1. Which folders should a refresh read?\\n2. How many items should a page hold?\",\"answers\":[\"$P1S\",\"$C_LAS\"]}" "$(replay_lines "$EV/runs/ce/clashes.jsonl")"
check "a clash on one question of two: the owner's message is recorded as the owner's" '{"n":1,"source":"owner"}' "$(replay_lines "$EV/runs/ce/replay.jsonl")"
check "a clash on one question of two: the pre-filled answer is used and the clashing ones are not" "[false,true,true]" \
  "$(prompt_segments 2 "[any(.[]; .id == \"$P2S0\"), any(.[]; .id == \"$P1S\"), any(.[]; .id == \"$C_LAS\")]")"

# Scenario: a later answer of one run, typed for a question, is used: when the
# same question comes up again the matcher is offered neither it nor the
# earlier answer it superseded (both ids are used).
fresh
later_answer_run
reply 1 "$T1"; reply 2 "$T1_AGAIN"; reply 3 "$T_DONE"
answer "I can draft" true "null=null==$C_LAS,$C_LBS"; answer "Sorry, asking again" false
start cs; finish
check "a later answer typed over an earlier one of its run: the second prompt shows neither of them among the unused segments" \
  "0 $FIRST_JSON|\"mark it read again\"|\"/exit\" [\"$P1S\",\"$P2S0\",\"$P2S1\"]" \
  "$STATUS $(typed) $(prompt_segments 2 '[.[].id]')"

# Scenario: the owner's pick settles a clash. The turn asked one question, the
# matcher listed a clash, the owner typed a line, and it is on the session's
# final chain: replay.sh settles at exit by dropping every id of the matcher's
# list (before the same-run pruning), keeping no id. A later replay of the
# spec is offered the owner's line and none of the dropped answers.
OWN_LINE="only the ones I ticked, and the archive"
own_id() { jq -r --arg m "$1" 'select(.type == "user" and .message.content == $m) | .uuid + "#0"' "$EV/runs/$2/transcript.jsonl"; }   # own_id <message> <run>: the segment id of the owner's line in that run
settled_log() { find "$EV/corpus" -name settled.jsonl -exec cat {} + 2> /dev/null | jq -cS '.drop |= sort' | paste -sd'|' -; }
pull_in_and_answer() { until_true logged "[window][focus]"; sleep 0.6; owner "$1"; }   # pull_in_and_answer <the owner's line>

fresh
clashing_run
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=null==$P1S,$C_LAS"; answer "Nothing more" false
start cs1
pull_in_and_answer "$OWN_LINE"
finish
check "a clash on a one-question turn with the owner's line on the chain: settled.jsonl holds a drop line of both answers and no keep key" \
  "0 {\"drop\":[\"$P1S\",\"$C_LAS\"]}" "$STATUS $(settled_log)"

OWN_ID="$(own_id "$OWN_LINE" cs1)"
mkdir -p "$T/keep"; rm -rf "$T/keep"/*
mkdir -p "$EV/corpus"; cp -R "$EV/runs" "$T/keep/runs"; cp -R "$EV/corpus" "$T/keep/corpus"
fresh
cp -R "$T/keep/runs/." "$EV/runs/"; mkdir -p "$EV/corpus"; cp -R "$T/keep/corpus/." "$EV/corpus/"
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=${OWN_ID}"; answer "Nothing more" false
start cs2; finish
check "a later replay of the spec types the owner's line from the earlier replay, then /exit" \
  "0 $FIRST_JSON|\"$OWN_LINE\"|\"/exit\"" "$STATUS $(typed)"
check "a later replay's log names the earlier replay's run and the owner's record" \
  "{\"n\":1,\"source\":\"replayed\",\"segments\":[\"$OWN_ID\"],\"from\":[{\"run\":\"cs1\",\"record\":\"${OWN_ID%#0}\"}]}" "$(replay_lines "$EV/runs/cs2/replay.jsonl")"
check "a later replay's matcher is offered the owner's line and neither answer the settling dropped" \
  "[true,false,false]" \
  "$(prompt_segments 1 "[any(.[]; .id == \"$OWN_ID\"), any(.[]; .id == \"$P1S\"), any(.[]; .id == \"$C_LAS\")]")"

fresh
later_answer_run; other_run_answer
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=null==$C_LAS,$C_LBS,$C_YS"; answer "Nothing more" false
start cs3
pull_in_and_answer "$OWN_LINE"
finish
check "a clash that the same-run pruning shortened is settled with every id the matcher listed, the superseded earlier answer included" \
  "0 {\"drop\":[\"$C_LBS\",\"$C_YS\",\"$C_LAS\"]}" "$STATUS $(settled_log)"

fresh
clashing_run
TURN_CP=$'1. Which folders should a refresh read?\n2. How many items should a page hold?'
reply 1 "$TURN_CP"; reply 2 "$T_DONE"
answer "1. Which folders should a refresh read?" true "1=null==$P1S,$C_LAS" "2=$P2S0"; answer "Nothing more" false
start cs4
pull_in_and_answer $'1: all folders\n\n2: 50 per page'
finish
check "a clash on a turn that asked several questions settles nothing, whatever the owner types" "0 []" "$STATUS [$(settled_log)]"

fresh
clashing_run
reply 1 "$T1"; reply 2 "$T_DONE"; reply_silent 2 1
answer "Which folders" true "null=null==$P1S,$C_LAS"; answer "Nothing more" false
start cs5
until_true logged "[window][focus]"
owner "a draft the owner then rewound"
until_true in_session "a draft the owner then rewound"
owner "@rewind"
owner "$OWN_LINE"
finish
check "a clash whose pulled-in owner line was rewound off the final chain settles nothing" "0 []" "$STATUS [$(settled_log)]"

# Scenario: a corpus that cannot be read is no empty corpus. A corpus.sh that
# exits 1 stops the replay with exit 1 and a message naming the corpus, before
# any tab is opened, and no run directory or live directory is made.
HX="$T/harness-broken"; rm -rf "$HX"; mkdir -p "$HX"
for f in replay.sh replay.jq corpus.jq; do cp "$H/$f" "$HX/$f"; done
printf '#!/usr/bin/env bash\necho "corpus.sh: broken stub" >&2\nexit 1\n' > "$HX/corpus.sh"
fresh
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "Nothing more" false
start rk; finish
unset HX
check "a corpus that cannot be read stops the replay: exit 1 and a message naming the corpus on stderr" "1 1" "$STATUS $(grep -c '^replay.sh: .*corpus' "$T/err")"
check "a corpus that cannot be read stops the replay before any session tab is opened" "0" "$(grep -c '^\[window\]\[new\]' "$SIDE/rex.log")"
check "a corpus that cannot be read leaves no run directory and no live directory" "no no" \
  "$([ -e "$EV/runs/rk" ] && echo yes || echo no) $([ -e "$EV/live/rk" ] && echo yes || echo no)"
check "a corpus that cannot be read is not read as no answers: the matcher is never asked" "0" "$(ls "$SIDE"/matcher/*.prompt 2> /dev/null | wc -l | tr -d ' ')"

# Scenario: recorded text is typed into a TUI that runs commands, so text the
# TUI would take for a command is never typed. A segment of an answer, or the
# first text, whose first line starts with "!", "/" or "#" is not typed and the
# owner is pulled in, shown the text. The first text's own
# /bjornstack:story-definition command (every first message above) is typed.
ctrl_bytes() { LC_ALL=C tr -d '\n\040-\176\200-\377' < "$1" | wc -c | tr -d ' '; }   # how many control bytes (below 0x20, newline aside, and 0x7f) the file holds
sent_calls() { grep -c '^\[send\]' "$SIDE/rex.log"; }
stop_when_idle() { # the driver is pulled-in or has typed the answer: stop the session and end the run
  local i
  for i in $(seq 1 100); do
    logged "[window][focus]" && break
    [ -e "$SIDE/typed/0002" ] && break
    kill -0 "$DRV" 2>/dev/null || break
    sleep 0.05
  done
  sleep 0.5
  touch "$SIDE/kill"
  finish
}
ANS_ID="a1a1a1a1-a1a1-4a1a-8a1a-a1a1a1a1a1a1"
one_answer_run() { # one_answer_run <file> <the turn> <the owner's answer>: R's first message, one turn, one answer
  rm -f "$1"; recorded_start "$1"; recorded_turn "$2"; recorded_answer "$ANS_ID" "$3"; recorded_exit; RF="$R"
}
one_text_run() { # one_text_run <file> <the first message record's content>: a run whose first message is that text
  rm -f "$1"; RF="$1"; PREV=
  rec --arg m "$2" '{type:"user",uuid:"00000000-0000-4000-8000-000000000000",message:{role:"user",content:$m}}'
  RF="$R"
}

for cmd_row in \
  "!|!ls -la|!ls -la" \
  "/|/clear|/clear" \
  "#|# remember this|# remember this" \
  "an escape before !|"$'\x1b'"!curl x|!curl x" \
  "a carriage return before /|"$'\r'"/add-dir /|/add-dir /" \
  "a delete byte before /|"$'\x7f'"/add-dir /|/add-dir /" \
  "a space before /| /add-dir /| /add-dir /"; do
  what="${cmd_row%%|*}"; rest="${cmd_row#*|}"; seg="${rest%%|*}"; shown="${rest#*|}"
  fresh
  one_answer_run "$T/recorded/cmd.jsonl" "$P1_TURN" "$seg"
  reply 1 "$T1"
  answer "Which folders" true "null=$ANS_ID#0"
  RSRC="$T/recorded/cmd.jsonl" start sg; stop_when_idle
  unset RSRC
  check "an answer whose first line starts with $what is not typed, the owner is pulled in and shown it" \
    "typed=$FIRST_JSON sends=2 focus=1 shown=1 ctrl=0" \
    "typed=$(typed) sends=$(sent_calls) focus=$(grep -cF "$FOCUS" "$SIDE/rex.log") shown=$(grep -cF -- "$shown" "$T/out" | sed 's/^[1-9][0-9]*$/1/') ctrl=$(ctrl_bytes "$SIDE/rex.log")"
done

fresh
one_answer_run "$T/recorded/cmd.jsonl" "$P1_TURN" $'fine\n/clear\n#2 as well'
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=$ANS_ID#0"; answer "Nothing more" false
RSRC="$T/recorded/cmd.jsonl" start sg2; finish
unset RSRC
check "an answer whose first line is plain is typed whole, though a later line starts with / or #" \
  "0 $FIRST_JSON|\"fine\\n/clear\\n#2 as well\"|\"/exit\"" "$STATUS $(typed)"

for first_row in \
  "#|#plan the thing|#plan the thing" \
  "!|!plan the thing|!plan the thing" \
  "/ of another command|/other:cmd plan the thing|/other:cmd plan the thing" \
  "an escape before !|"$'\x1b'"!plan the thing|!plan the thing" \
  "a carriage return before /|"$'\r'"/other:cmd plan the thing|/other:cmd plan the thing" \
  "a delete byte before /|"$'\x7f'"/other:cmd plan the thing|/other:cmd plan the thing" \
  "a space before /| /other:cmd plan the thing| /other:cmd plan the thing"; do
  what="${first_row%%|*}"; rest="${first_row#*|}"; first="${rest%%|*}"; shown="${rest#*|}"
  fresh
  one_text_run "$T/recorded/first.jsonl" "$first"
  reply 1 "$T1"
  RSRC="$T/recorded/first.jsonl" start sf; stop_when_idle
  unset RSRC
  check "a first text starting with $what is not typed, the owner is pulled in and shown it" \
    "sends=0 focus=1 shown=1 ctrl=0" \
    "sends=$(sent_calls) focus=$(grep -cF "$FOCUS" "$SIDE/rex.log") shown=$(grep -cF -- "$shown" "$T/out" | sed 's/^[1-9][0-9]*$/1/') ctrl=$(ctrl_bytes "$SIDE/rex.log")"
done

# A control character below 0x20 (newline aside) in typed text never reaches
# rex send: a "\r" would submit the line, an escape would drive the TUI.
for ctrl_row in \
  "a carriage return|weekly"$'\r'"monthly" \
  "an escape|all"$'\x1b'"[2Jfolders" \
  "a ctrl-c|all"$'\x03'"folders" \
  "a tab|all"$'\t'"folders" \
  "a delete byte|all"$'\x7f'"folders" \
  "a carriage return on a later line|weekly"$'\n'"monthly"$'\r'"yearly"; do
  what="${ctrl_row%%|*}"; seg="${ctrl_row#*|}"
  fresh
  one_answer_run "$T/recorded/ctrl.jsonl" "$P1_TURN" "$seg"
  reply 1 "$T1"; reply 2 "$T_DONE"
  answer "Which folders" true "null=$ANS_ID#0"; answer "Nothing more" false
  RSRC="$T/recorded/ctrl.jsonl" start sc; stop_when_idle
  unset RSRC
  check "an answer holding $what reaches rex send with no control character" "0" "$(ctrl_bytes "$SIDE/rex.log")"
done
for ctrl_row in \
  "a carriage return|plan"$'\r'"the thing" \
  "an escape|plan"$'\x1b'"[2J the thing" \
  "a delete byte|plan"$'\x7f'" the thing"; do
  what="${ctrl_row%%|*}"; first="${ctrl_row#*|}"
  fresh
  one_text_run "$T/recorded/first.jsonl" "$first"
  reply 1 "$T1"
  RSRC="$T/recorded/first.jsonl" start sf; stop_when_idle
  unset RSRC
  check "a first text holding $what reaches rex send with no control character" "0" "$(ctrl_bytes "$SIDE/rex.log")"
done

# Scenario: a failure message quotes recorded text, so it holds no control
# character (0x7f included) either.
fresh
one_text_run "$T/recorded/first.jsonl" "plan"$'\x1b'"[2J the"$'\x7f'" thing"
touch "$SIDE/first-differs"
reply 1 "$T1"
RSRC="$T/recorded/first.jsonl" start sf; finish
unset RSRC
check "a failure that names a first message holding control bytes shows none of them, and still names the text" "nonzero 0 1" \
  "$([ "$STATUS" -ne 0 ] && echo nonzero || echo zero) $(ctrl_bytes "$T/err") $(grep -c 'differs from the recorded first message' "$T/err")"

fresh
one_answer_run "$T/recorded/ctrl.jsonl" "$P1_TURN" "all"$'\x1b'"[2J fol"$'\x7f'"ders"
echo 2 > "$SIDE/exit-on-enter"
reply 1 "$T1"
answer "Which folders" true "null=$ANS_ID#0"
RSRC="$T/recorded/ctrl.jsonl" start sc; finish
unset RSRC
check "a failure that names a replayed answer holding control bytes shows none of them, and still says it never appeared" "nonzero 0 1" \
  "$([ "$STATUS" -ne 0 ] && echo nonzero || echo zero) $(ctrl_bytes "$T/err") $(grep -c 'never appeared' "$T/err")"

# Scenario: recorded text the owner is shown is shown without control
# characters, so a recording cannot drive the owner's terminal. A refused
# near-match shows its segment and the turn it answered.
fresh
rm -f "$T/recorded/ctrl.jsonl"; recorded_start "$T/recorded/ctrl.jsonl"
recorded_turn $'Which \x1b]0;pwned\x07folders should it read?'; recorded_answer "$ANS_ID" $'all\x1b[2J folders'; recorded_exit
RF="$R"
reply 1 "$T1"
answer "Which folders" true "null=null=$ANS_ID#0"
RSRC="$T/recorded/ctrl.jsonl" start sd; stop_when_idle
unset RSRC
check "the segment and the turn shown to the pulled-in owner hold no control character, and the text around them stays" \
  "ctrl=0 segment=1 turn=1" \
  "ctrl=$(ctrl_bytes "$T/out") segment=$(grep -cF '[2J folders' "$T/out") turn=$(grep -cF ']0;pwnedfolders should it read?' "$T/out")"

# Scenario: a settle that fails leaves a trace. The run keeps its exit status;
# its directory holds one file besides the usual ones, naming the clash's ids,
# and replay.sh prints the ids to its own stdout beyond what the pull-in shows.
extra_files() { (cd "$EV/runs/$1" && LC_ALL=C ls -A | grep -vxE 'clashes.jsonl|plugin-commit.txt|replay.jsonl|replayed-from.txt|transcript.jsonl|workdir' | paste -sd' ' -); }
trace_names() { # trace_names <run name> <id>...: yes when the run's one extra file holds every id
  local f id; f="$EV/runs/$1/$(extra_files "$1")"; shift
  for id in "$@"; do grep -qF -- "$id" "$f" 2> /dev/null || { echo no; return; }; done
  echo yes
}
unsettled_run() { # unsettled_run <name>: a one-question clash the owner's line would settle
  fresh
  clashing_run
  reply 1 "$T1"; reply 2 "$T_DONE"
  answer "Which folders" true "null=null==$P1S,$C_LAS"; answer "Nothing more" false
}
unsettled_run
start us0
pull_in_and_answer "$OWN_LINE"
finish
BASE_MENTIONS="$(grep -cF -- "$P1S" "$T/out")"
check "a settle that works leaves nothing extra in the run directory" "0 []" "$STATUS [$(extra_files us0)]"

HX="$T/harness-nosettle"; rm -rf "$HX"; mkdir -p "$HX"
for f in replay.sh replay.jq corpus.jq; do cp "$H/$f" "$HX/$f"; done
printf '#!/usr/bin/env bash\n[ "$1" != settle ] || { echo "corpus.sh: settle broke" >&2; exit 1; }\nexec bash "%s/corpus.sh" "$@"\n' "$H" > "$HX/corpus.sh"
unsettled_run
start us1
pull_in_and_answer "$OWN_LINE"
finish
unset HX
check "a settle that fails keeps the run's exit status, settles nothing and leaves one extra file in the run directory naming both ids" \
  "0 [] 1 yes" "$STATUS [$(settled_log)] $(extra_files us1 | wc -w | tr -d ' ') $(trace_names us1 "$P1S" "$C_LAS")"
check "a settle that fails prints the unsettled ids to replay.sh's stdout, beyond the pull-in's own display" "yes" \
  "$([ "$(grep -cF -- "$P1S" "$T/out")" -gt "$BASE_MENTIONS" ] && [ "$(grep -cF -- "$C_LAS" "$T/out")" -gt "$BASE_MENTIONS" ] && echo yes || echo no)"

unsettled_run
echo owner_messages > "$SIDE/jq-fails-on"
start us2
pull_in_and_answer "$OWN_LINE"
finish
check "a settle whose chain cannot be read counts as a failed one: exit status kept, one extra file naming both ids" \
  "0 [] 1 yes" "$STATUS [$(settled_log)] $(extra_files us2 | wc -w | tr -d ' ') $(trace_names us2 "$P1S" "$C_LAS")"

fresh
reply 1 "$T1"; reply 2 "$T_DONE"
answer "Which folders" true "null=$P1S"; answer "Nothing more" false
echo replay_log > "$SIDE/jq-fails-on"
start us3; finish
check "a replay.jsonl that cannot be written is reported on stderr, not left silently empty" "yes" \
  "$(grep -qF 'replay.jsonl' "$T/err" && echo yes || echo no)"

# Scenario: the matcher's own complaint is not thrown away. claude -p's stderr
# is reported with the failure.
fresh
reply 1 "$T2"; reply 2 "$T_DONE"
row "prune run" "" 1; echo "CLAUDE-SAID-QUOTA-EXCEEDED" > "$SIDE/answers/01.err"
answer "Nothing more" false
start mf
until_true logged "[window][focus]"
sleep 0.6
owner "weekly"
finish
check "when the matcher fails, what claude printed to stderr is in replay.sh's stderr" "1" "$(grep -cF 'CLAUDE-SAID-QUOTA-EXCEEDED' "$T/err")"

# Scenario: answer_plan assembles the message. Its output carries it, so the
# caller types or pre-fills what the plan says. answer_plan is run from the
# text of replay.sh, over segments and used ids given here.
PLAN_SEGS='[{"id":"a#0","label":null,"segment":"50 per page","session_turn":"t","run":"R","record":"a","order":1},{"id":"b#0","label":null,"segment":"hide the drafts","session_turn":"t","run":"R","record":"b","order":2}]'
plan_message() { # plan_message <matcher answer JSON> <turn text>: the message of answer_plan's output
  ( SEGMENTS="$PLAN_SEGS"; USED='[]'
    eval "$(sed -n '/^answer_plan() {$/,/^}$/p' "$H/replay.sh")"
    answer_plan "$1" "$2" | jq -c '.message' )
}
Q_ONE='{"asks":true,"questions":[{"number":null,"segment":"a#0"}]}'
Q_LAB='{"asks":true,"questions":[{"number":1,"segment":"a#0"},{"number":2,"segment":"b#0"}]}'
Q_NUM='{"asks":true,"questions":[{"number":null,"segment":"a#0"},{"number":null,"segment":"b#0"}]}'
Q_LAB_PART='{"asks":true,"questions":[{"number":1,"segment":"a#0"},{"number":2,"segment":null}]}'
Q_NUM_PART='{"asks":true,"questions":[{"number":null,"segment":"a#0"},{"number":null,"segment":null}]}'
TWO_NUMBERED=$'1. How many per page?\n2. Hide the drafts?'
TWO_PLAIN=$'How many per page?\nHide the drafts?'
ONE_TURN="Which page size?"
for plan_row in \
  "one question, no label|Q_ONE|ONE_TURN|\"50 per page\"" \
  "two labelled questions, both covered|Q_LAB|TWO_NUMBERED|\"1: 50 per page\\n\\n2: hide the drafts\"" \
  "two unlabelled questions, both covered|Q_NUM|TWO_PLAIN|\"1: 50 per page\\n\\n2: hide the drafts\"" \
  "two labelled questions, the second uncovered|Q_LAB_PART|TWO_NUMBERED|\"1: 50 per page\\n\\n2: \"" \
  "two unlabelled questions, the second uncovered|Q_NUM_PART|TWO_PLAIN|\"50 per page\""; do
  IFS='|' read -r what ans turn want <<< "$plan_row"
  check "answer_plan's message for $what" "$want" "$(plan_message "${!ans}" "${!turn}")"
done

# Scenario: the stubs end by themselves once their case's side directory is
# gone, so a case that is killed halfway leaves no stub behind. Started by hand
# through the stubs, not through replay.sh.
fresh
touch "$SIDE/wait-hangs"
mkdir "$T/selfexit"
env STUB_SIDE="$SIDE" HOME="$T/home" PATH="$PATHX" rex window new selfexit --keep-open --json -s sess-1 -c "$T/tmpd" -- claude --session-id selfexit > /dev/null
env STUB_SIDE="$SIDE" HOME="$T/home" PATH="$PATHX" rex wait -s sess-1 blk-1 > /dev/null 2>&1 &
sleep 0.5
cp "$SIDE/pids" "$T/selfexit/pids"
alive_before="$(alive_now "$T/selfexit")"
rm -rf "$SIDE"
check "the stub session and the stub wait were both running before the side directory was removed" "yes" "$([ "$alive_before" -ge 2 ] && echo yes || echo no)"
check "a stub session and a stub wait end within 3 seconds of their side directory being removed" "0" "$(leaked "$T/selfexit")"

leak_check

exit "$FAILED"
