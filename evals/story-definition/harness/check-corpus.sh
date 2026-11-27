#!/usr/bin/env bash
# Checks for the corpus of a spec: corpus.jq (the rules) and corpus.sh (the
# glue that reads runs, settles clashes).
#
# Where the cases went and why:
#  - Part A, solitary unit cases of corpus.jq. The corpus rules are pure jq
#    functions, run with `jq -s` over fixture transcripts or `jq -n` over
#    literals. No mock, no stub: spec identity (spec_text, spec_of_prompt), which owner
#    messages are answers (owner_segments), what settling removes (effective),
#    what the owner is shown (clash_listing) and how clashes from two sources
#    become one list (merge_clashes). Three or more cases of one function are a table.
#  - Part B, black-box cases of corpus.sh, run directly from a temp copy of the
#    harness directory against fixture runs under a temp eval home, with a
#    stub claude on PATH that only logs a call: corpus.sh has no matcher and
#    must never call it. They prove the wiring: which run directories form a spec's
#    corpus (segments), that a settled choice survives into segments (settle),
#    the exit codes (0, 2 for usage, an unknown id or an unknown subcommand,
#    check among them), and that no claude call is made. The rules beneath them
#    are Part A's; this part has one case per scenario of the story.
#  - replay.sh's use of the corpus lives in check-replay.sh; rex-run.sh calling
#    no corpus.sh is in check-rex-run.sh.
#
# Interface the cases pin (corpus.jq, include "corpus" {search: <dir>}; it
# includes replay.jq):
#   spec_text                      over a transcript array; the first user record's
#                                  <command-args> (or the plain first message) with trailing
#                                  whitespace and a trailing "\n\nThe owner is away for this
#                                  session" removed; null when there is no user record
#   spec_of_prompt                 over the raw text of prompt.txt; the text after
#                                  "/bjornstack:story-definition ", trimmed as spec_text; null
#                                  when the text does not start with that command
#   owner_segments($run; $log)     over a transcript array; $run the run's name, $log the lines
#                                  of replay.jsonl as an array, or null; one array of
#                                  {id, label, segment, session_turn, run, record, order}, id
#                                  (order: the position of the record among the run's owner records on the final chain, from 1)
#                                  "<record uuid>#<index>"; owner messages only, and with a log
#                                  only those whose line (n counts owner messages on the final
#                                  chain, from 1) has source "owner"
#   effective($segments; $settled) over nothing (null input); $settled the settled.jsonl lines
#                                  [{keep, drop:[ids]}], either key may be missing (a line of
#                                  the driver's has only drop; a revive may have only keep);
#                                  $segments without every dropped id
#   clash_listing($clashes; $segments)
#                                  a string, the text the check prints; per clash:
#                                    clash: <question>
#                                      answer <id>: <segment>
#                                        run <run>, record <record>
#                                      ... (one answer block per id)
#                                      one line per answer id, in clash order:
#                                      "  settle with: --keep <id> --drop <the other ids, space separated>"
#                                  clashes joined by one blank line; no trailing newline
#   merge_clashes($met; $segments)
#                                  null input; clashes [{question, answers:[ids]}] met during a
#                                  replay, ids not in $segments (dropped ones) removed, a clash with
#                                  fewer than 2 ids left removed, duplicates (same id set, any order) kept once
#                                  as their first occurrence
# corpus.sh: `settle <run-dir|transcript> --keep <id> --drop <id>...` or
# `settle <run-dir|transcript> --drop <id>...` (drops only; each id must be a segment),
# `segments <run-dir|transcript>` (a JSON array of corpus segments on stdout).
# Any other subcommand, `check` included, exits 2 with the usage on stderr.
#
# The stub claude has no answer: every call is logged in $SIDE/claude.calls and
# exits 9. That reads the stub for its calls, not corpus.sh's code: the call
# is the effect under test (there must be none), and it is not output of corpus.sh.
# Usage: check-corpus.sh
set -uo pipefail

unset $(git rev-parse --local-env-vars)

HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/corpus-check.XXXXXX")"
T="$(cd "$T" && pwd -P)"
trap 'rm -rf "$T"' EXIT
FAILED=0

H="$T/harness"
EV="$T/home/workspace/bjornstack-evals"
PATHX="$T/bin:$PATH"
mkdir -p "$T/bin" "$H" "$T/tmp" "$T/recorded"
for f in corpus.sh corpus.jq replay.jq matcher.sh; do
  [ ! -e "$HERE/$f" ] || cp "$HERE/$f" "$H/$f"
done

check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then echo "ok   $1"; else
    echo "FAIL $1"; echo "  expected: $2"; echo "  actual:   $3"; FAILED=1
  fi
}
check_json() { # check_json <description> <expected JSON literal> <actual, already compact with sorted keys>
  check "$1" "$(printf '%s' "$2" | jq -cS . 2>&1)" "$3"
}

# Ids, uuids and text of the fixtures.
SPEC=$'build a refresh\nfor the inbox'
AWAY_SUFFIX=$'\n\nThe owner is away for this session'
Q1="Which folders should a refresh read?"; A1="only the ones I ticked"
Q2="When does a refresh run?";             A2="every 15 minutes"
AX="all of them"
UL="11111111-1111-4111-8111-111111111111"   # live run's answer to Q1
UP="22222222-2222-4222-8222-222222222222"   # replay's own answer to Q2
UX="33333333-3333-4333-8333-333333333333"   # a third run's answer to Q1
UC="44444444-4444-4444-8444-444444444444"   # replay's copy of the live run's answer
UA="55555555-5555-4555-8555-555555555555"
UR="66666666-6666-4666-8666-666666666666"
US="77777777-7777-4777-8777-777777777777"
UZ="88888888-8888-4888-8888-888888888888"

# Transcripts. rec writes a record chained by parentUuid to the previous one.
RF=; PREV=; SEQ=0
rec() {
  jq -nc "$@" | jq -c --arg p "$PREV" '. + {parentUuid: (if $p == "" then null else $p end)}' >> "$RF"
  PREV="$(tail -n 1 "$RF" | jq -r .uuid)"
}
rec_abandoned() { local keep="$PREV"; rec "$@"; PREV="$keep"; }
next_uuid() { SEQ=$((SEQ+1)); NEXT="$(printf '%08d-0000-4000-8000-%012d' "$SEQ" "$SEQ")"; }
t_start() { # t_start <file> <command args>: the first message, a slash command
  RF="$1"; PREV=; : > "$RF"
  rec --arg a "$2" '{type:"user",uuid:"00000000-0000-4000-8000-000000000000",message:{role:"user",content:("<command-message>x:y</command-message>\n<command-name>/x:y</command-name>\n<command-args>"+$a+"</command-args>")}}'
}
t_plain() { # t_plain <file> <plain first message>
  RF="$1"; PREV=; : > "$RF"
  rec --arg m "$2" '{type:"user",uuid:"00000000-0000-4000-8000-000000000000",message:{role:"user",content:$m}}'
}
t_turn() {
  next_uuid; rec --arg t "$1" --arg u "$NEXT" '{type:"assistant",uuid:$u,message:{role:"assistant",content:[{type:"text",text:$t}]}}'
  next_uuid; rec --arg u "$NEXT" '{type:"system",subtype:"turn_duration",uuid:$u}'
}
t_answer() { rec --arg u "$1" --arg m "$2" '{type:"user",uuid:$u,message:{role:"user",content:$m}}'; }
t_draft() { rec_abandoned --arg u "$1" --arg m "$2" '{type:"user",uuid:$u,message:{role:"user",content:$m}}'; }
t_exit() { next_uuid; rec --arg u "$NEXT" '{type:"user",uuid:$u,message:{role:"user",content:"<command-name>/exit</command-name>\n<command-message>exit</command-message>\n<command-args></command-args>"}}'; }
t_headless() { # a stream-json run: no user record at all
  RF="$1"; PREV=; : > "$RF"
  rec '{type:"system",subtype:"init",uuid:"00000000-0000-4000-8000-0000000000a0"}'
  rec '{type:"assistant",uuid:"00000000-0000-4000-8000-0000000000a1",message:{role:"assistant",content:[{type:"text",text:"asking"}]}}'
  rec '{type:"result",uuid:"00000000-0000-4000-8000-0000000000a2"}'
}
t_stream() { # a stream-json run as claude -p writes it: records not chained by parentUuid, a tool result as its only user record
  RF="$1"; PREV=; : > "$RF"
  rec '{type:"system",subtype:"init",uuid:"00000000-0000-4000-8000-0000000000b0"}'
  rec '{type:"assistant",uuid:"00000000-0000-4000-8000-0000000000b1",message:{role:"assistant",content:[{type:"tool_use",id:"t1",name:"Read",input:{}}]}}'
  rec '{type:"user",uuid:"00000000-0000-4000-8000-0000000000b2",message:{role:"user",content:[{type:"tool_result",tool_use_id:"t1",content:"x"}]}}'
  PREV=
  rec '{type:"result",uuid:"00000000-0000-4000-8000-0000000000b3"}'
}
make() { # make <file> <command args> [<turn> <answer uuid> <answer text>]...
  local f="$1" spec="$2"; shift 2
  t_start "$f" "$spec"
  while [ $# -gt 0 ]; do t_turn "$1"; t_answer "$2" "$3"; shift 3; done
  t_exit
}

# Part A fixtures.
U="$T/u"; mkdir -p "$U"
make "$U/live.jsonl" "$SPEC" "$Q1" "$UL" "$A1"
make "$U/numbered.jsonl" "$SPEC" "$Q1" "$UL" $'1: weekly\n2: all folders\nincluding the archive'
make "$U/two.jsonl" "$SPEC" "$Q1" "$UL" "$A1" "$Q2" "$UP" "$A2"
t_start "$U/rewound.jsonl" "$SPEC"; t_turn "$Q1"; t_draft "$UZ" "a draft I then rewound"; t_answer "$UL" "$A1"; t_exit
make "$U/ws.jsonl" $'build a refresh\nfor the inbox  \n\n'
make "$U/away.jsonl" "$SPEC$AWAY_SUFFIX"
make "$U/away-ws.jsonl" "$SPEC$AWAY_SUFFIX"$'\n'
t_plain "$U/plain.jsonl" "plan the thing please"
t_headless "$U/headless.jsonl"
t_stream "$U/stream.jsonl"

J="include \"corpus\" {search: \"$H\"};"
over_transcript() { # over_transcript <file> <program> [jq args]: jq -s over the transcript
  local f="$1" p="$2"; shift 2
  jq -sSc "$@" "$J $p" "$f" 2>&1
}
over_literal() { # over_literal <program> [jq args]
  local p="$1"; shift
  jq -nSc "$@" "$J $p" 2>&1
}
seg() { # seg <id> <label or null> <segment> <session turn> <run> <record> <order>
  jq -nSc --arg id "$1" --arg l "$2" --arg s "$3" --arg t "$4" --arg r "$5" --arg rec "$6" --argjson o "$7" \
    '{id:$id, label:(if $l == "null" then null else $l end), segment:$s, session_turn:$t, run:$r, record:$rec, order:$o}'
}
# Splits a table row "a@@b@@c" into ROW0, ROW1, ROW2.
split_row() { local r="$1"; ROW0="${r%%@@*}"; r="${r#*@@}"; ROW1="${r%%@@*}"; ROW2="${r#*@@}"; }

SEG_L="$(seg "$UL#0" null "$A1" "$Q1" L "$UL" 1)"
SEG_P="$(seg "$UP#0" null "$A2" "$Q2" P "$UP" 2)"

echo "== Part A: corpus.jq =="

# The invariant: the default transcript's spec.
check_json "the spec of a run is the command args of its first message" \
  "$(jq -nc --arg s "$SPEC" '$s')" "$(over_transcript "$U/live.jsonl" 'spec_text')"

# spec_text: one row per way a spec text is written down.
for row in \
  "a plain first message is the spec as typed@@$U/plain.jsonl@@\"plan the thing please\"" \
  "trailing whitespace and blank lines are removed@@$U/ws.jsonl@@\"build a refresh\\nfor the inbox\"" \
  "a trailing owner-away line is removed@@$U/away.jsonl@@\"build a refresh\\nfor the inbox\"" \
  "an owner-away line and the whitespace after it are removed@@$U/away-ws.jsonl@@\"build a refresh\\nfor the inbox\"" \
  "a transcript with no user record has no spec@@$U/headless.jsonl@@null" \
  "a stream-json transcript whose only user record is a tool result has no spec and no jq error@@$U/stream.jsonl@@null"; do
  split_row "$row"
  check_json "spec_text: $ROW0" "$ROW2" "$(over_transcript "$ROW1" 'spec_text')"
done

# spec_of_prompt: the raw prompt.txt text as run.sh wrote it.
PROMPT_CMD="/bjornstack:story-definition"
for row in \
  "the text after the command@@$PROMPT_CMD $SPEC@@\"build a refresh\\nfor the inbox\"" \
  "the newline run.sh adds is removed@@$PROMPT_CMD $SPEC"$'\n@@'"\"build a refresh\\nfor the inbox\"" \
  "the owner-away line and the newline are removed@@$PROMPT_CMD $SPEC$AWAY_SUFFIX"$'\n@@'"\"build a refresh\\nfor the inbox\"" \
  "a prompt of another command has no spec@@/x:y $SPEC@@null"; do
  split_row "$row"
  check_json "spec_of_prompt: $ROW0" "$ROW2" "$(over_literal '$p | spec_of_prompt' --arg p "$ROW1")"
done

# owner_segments: a live run counts every owner message; a replay counts the
# lines logged "owner" and never a copy.
LOG_COPY_THEN_OWN='[{"n":1,"source":"replayed","segments":["x#0"],"from":[{"run":"L","record":"x"}]},{"n":2,"source":"owner"}]'
LOG_ALL_COPIES='[{"n":1,"source":"replayed","segments":["x#0"],"from":[{"run":"L","record":"x"}]},{"n":2,"source":"replayed","segments":["y#0"],"from":[{"run":"L","record":"y"}]}]'
LOG_ALL_OWN='[{"n":1,"source":"owner"},{"n":2,"source":"owner"}]'
check_json "an owner message of a live run is one segment, with its run and record" \
  "[$SEG_L]" "$(over_transcript "$U/live.jsonl" 'owner_segments("L"; null)')"
for row in \
  "a numbered message is a segment per number, its label removed from the text@@$U/numbered.jsonl@@null@@[$(seg "$UL#0" 1 weekly "$Q1" L "$UL" 1),$(seg "$UL#1" 2 $'all folders\nincluding the archive' "$Q1" L "$UL" 1)]" \
  "a rewound draft is not an answer@@$U/rewound.jsonl@@null@@[$SEG_L]" \
  "a copy logged replayed is dropped, the owner line kept@@$U/two.jsonl@@$LOG_COPY_THEN_OWN@@[$(seg "$UP#0" null "$A2" "$Q2" L "$UP" 2)]" \
  "a log of only copies leaves no answer@@$U/two.jsonl@@$LOG_ALL_COPIES@@[]" \
  "a log of only owner lines keeps both messages@@$U/two.jsonl@@$LOG_ALL_OWN@@[$(seg "$UL#0" null "$A1" "$Q1" L "$UL" 1),$(seg "$UP#0" null "$A2" "$Q2" L "$UP" 2)]"; do
  name="${row%%@@*}"; rest="${row#*@@}"; file="${rest%%@@*}"; rest="${rest#*@@}"; log="${rest%%@@*}"; want="${rest#*@@}"
  check_json "owner_segments: $name" "$want" "$(over_transcript "$file" 'owner_segments("L"; $log)' --argjson log "$log")"
done

# effective: the latest settled line naming an id decides it: dropped iff the last line that names it (as keep or in drop) names it in drop.
IDS3='[{"id":"a"},{"id":"b"},{"id":"c"}]'
for row in \
  "no settled choice leaves every segment@@[]@@$IDS3" \
  "a dropped id is removed@@[{\"keep\":\"a\",\"drop\":[\"b\"]}]@@[{\"id\":\"a\"},{\"id\":\"c\"}]" \
  "the drops of two settlings both apply@@[{\"keep\":\"a\",\"drop\":[\"b\"]},{\"keep\":\"a\",\"drop\":[\"c\"]}]@@[{\"id\":\"a\"}]" \
  "a dropped id that is not a segment changes nothing@@[{\"keep\":\"a\",\"drop\":[\"zz\"]}]@@$IDS3" \
  "a kept id stays@@[{\"keep\":\"c\",\"drop\":[\"a\",\"b\"]}]@@[{\"id\":\"c\"}]" \
  "a keep after a drop revives the id@@[{\"keep\":\"a\",\"drop\":[\"b\"]},{\"keep\":\"b\",\"drop\":[\"c\"]}]@@[{\"id\":\"a\"},{\"id\":\"b\"}]" \
  "a drop after a keep drops the id@@[{\"keep\":\"a\",\"drop\":[\"b\"]},{\"keep\":\"c\",\"drop\":[\"a\"]}]@@[{\"id\":\"c\"}]" \
  "a line with only drop removes its ids (the driver's line)@@[{\"drop\":[\"b\",\"c\"]}]@@[{\"id\":\"a\"}]" \
  "a line with only keep drops nothing@@[{\"keep\":\"a\"}]@@$IDS3" \
  "a line with only keep revives an id an earlier drop-only line removed@@[{\"drop\":[\"b\"]},{\"keep\":\"b\"}]@@$IDS3" \
  "a drop-only line after a keep drops the id@@[{\"keep\":\"a\",\"drop\":[\"b\"]},{\"drop\":[\"a\"]}]@@[{\"id\":\"c\"}]" \
  "the same two lines in the other order give another corpus@@[{\"keep\":\"c\",\"drop\":[\"a\"]},{\"keep\":\"a\",\"drop\":[\"b\"]}]@@[{\"id\":\"a\"},{\"id\":\"c\"}]"; do
  split_row "$row"
  check_json "effective: $ROW0" "$ROW2" "$(over_literal 'effective($segs; $settled)' --argjson segs "$IDS3" --argjson settled "$ROW1")"
done

# merge_clashes: met during a replay, cleaned against the effective segments.
CL_AB='{"question":"q","answers":["a","b"]}'
CL_BA='{"question":"asked another way","answers":["b","a"]}'
CL_BC='{"question":"r","answers":["b","c"]}'
CL_ABC='{"question":"s","answers":["a","b","c"]}'
for row in \
  "a clash met during a replay is kept@@[$CL_BC]@@[$CL_BC]" \
  "the same id set twice is listed once, as first met@@[$CL_AB,$CL_BA]@@[$CL_AB]" \
  "different clashes are all kept, in order@@[$CL_BC,$CL_AB]@@[$CL_BC,$CL_AB]" \
  "a dropped id is removed from a clash that keeps two live ids@@[$CL_ABC,{\"question\":\"t\",\"answers\":[\"a\",\"zz\",\"b\"]}]@@[$CL_ABC,{\"question\":\"t\",\"answers\":[\"a\",\"b\"]}]" \
  "a clash left with fewer than two live ids is removed@@[{\"question\":\"u\",\"answers\":[\"yy\",\"zz\"]},{\"question\":\"t\",\"answers\":[\"a\",\"zz\"]}]@@[]"; do
  name="${row%%@@*}"; rest="${row#*@@}"; met="${rest%%@@*}"; want="${rest#*@@}"
  check_json "merge_clashes: $name" "$want" "$(over_literal 'merge_clashes($met; $segs)' --argjson met "$met" --argjson segs "$IDS3")"
done

# clash_listing: what the owner reads, ready to settle.
CLASH_SEGS="[$(seg "$UL#0" null "$A1" "$Q1" live-1 "$UL" 1),$(seg "$UX#0" null "$AX" "$Q1" third-1 "$UX" 1),$(seg "$UP#0" null "$A2" "$Q2" replay-1 "$UP" 2)]"
check_json "clash_listing: a clash lists the question, each answer with its run and record, and one line per answer to settle with, keeping that answer" \
  "$(jq -nc --arg q "$Q1" --arg a "$A1" --arg x "$AX" --arg l "$UL" --arg y "$UX" \
    '"clash: \($q)\n  answer \($l)#0: \($a)\n    run live-1, record \($l)\n  answer \($y)#0: \($x)\n    run third-1, record \($y)\n  settle with: --keep \($l)#0 --drop \($y)#0\n  settle with: --keep \($y)#0 --drop \($l)#0"')" \
  "$(over_literal 'clash_listing($clashes; $segs)' --argjson segs "$CLASH_SEGS" --argjson clashes "[{\"question\":\"$Q1\",\"answers\":[\"$UL#0\",\"$UX#0\"]}]")"
check_json "clash_listing: three answers get three settle lines, each dropping the others in clash order, and clashes are separated by a blank line" \
  "$(jq -nc --arg q "$Q1" --arg a "$A1" --arg x "$AX" --arg p "$A2" --arg l "$UL" --arg y "$UX" --arg z "$UP" \
    '"clash: \($q)\n  answer \($l)#0: \($a)\n    run live-1, record \($l)\n  answer \($y)#0: \($x)\n    run third-1, record \($y)\n  answer \($z)#0: \($p)\n    run replay-1, record \($z)\n  settle with: --keep \($l)#0 --drop \($y)#0 \($z)#0\n  settle with: --keep \($y)#0 --drop \($l)#0 \($z)#0\n  settle with: --keep \($z)#0 --drop \($l)#0 \($y)#0\n\nclash: again\n  answer \($l)#0: \($a)\n    run live-1, record \($l)\n  answer \($z)#0: \($p)\n    run replay-1, record \($z)\n  settle with: --keep \($l)#0 --drop \($z)#0\n  settle with: --keep \($z)#0 --drop \($l)#0"')" \
  "$(over_literal 'clash_listing($clashes; $segs)' --argjson segs "$CLASH_SEGS" --argjson clashes "[{\"question\":\"$Q1\",\"answers\":[\"$UL#0\",\"$UX#0\",\"$UP#0\"]},{\"question\":\"again\",\"answers\":[\"$UL#0\",\"$UP#0\"]}]")"

echo "== Part B: corpus.sh =="

# Stub claude: corpus.sh must never call it. It has no answer: every call is
# logged in $SIDE/claude.calls and exits 9. Reading the stub for its calls is the
# only way to see that nothing was called: a call leaves no output of corpus.sh.
cat > "$T/bin/claude" <<'STUB'
#!/usr/bin/env bash
echo called >> "$STUB_SIDE/claude.calls"
exit 9
STUB
chmod +x "$T/bin/claude"

N=0
fresh() {
  N=$((N+1)); SIDE="$T/side.$N"
  rm -rf "${EV:?}" "${T:?}/tmp" "${T:?}/recorded"; mkdir -p "$EV/runs" "$SIDE" "$T/tmp" "$T/recorded"
}
make_run() { # make_run <name> <command args> [<turn> <uuid> <text>]...: a run directory under the eval home
  local name="$1"; shift
  mkdir -p "$EV/runs/$name"
  make "$EV/runs/$name/transcript.jsonl" "$@"
}
# The story's background: a live run and a replay of the same spec. The replay
# holds a copy of the live run's answer (logged replayed, with where it came from) and its own.
default_runs() {
  make_run live-1 "$SPEC" "$Q1" "$UL" "$A1"
  make_run replay-1 "$SPEC" "$Q1" "$UC" "$A1" "$Q2" "$UP" "$A2"
  jq -nc --arg s "$UL#0" --arg r "$UL" '{n:1,source:"replayed",segments:[$s],from:[{run:"live-1",record:$r}]}' > "$EV/runs/replay-1/replay.jsonl"
  echo '{"n":2,"source":"owner"}' >> "$EV/runs/replay-1/replay.jsonl"
}
third_run() { make_run third-1 "$SPEC" "$Q1" "$UX" "$AX"; }
LIVE="$EV/runs/live-1"
run_corpus() { # run_corpus <args>: sets STATUS, OUT, ERR
  OUT="$T/out"; ERR="$T/err"
  ( cd "$EV" && env EVALS_DIR="$EV" HOME="$T/home" PATH="$PATHX" TMPDIR="$T/tmp" STUB_SIDE="$SIDE" ANTHROPIC_API_KEY=sk-test \
      bash "$H/corpus.sh" "$@" > "$OUT" 2> "$ERR" < /dev/null )
  STATUS=$?
}
calls() { cat "$SIDE/claude.calls" 2> /dev/null | wc -l | tr -d ' '; }
seen() { grep -cF -- "$1" "$2" | sed 's/^[1-9][0-9]*$/1/'; }   # 1 when the file holds a line with the text, else 0
corpus_ids() { jq -c '[.[].id] | sort' "$OUT" 2>&1; }
corpus_view() { jq -cS '[.[] | {id, run, record, segment, order}] | sort_by(.id)' "$OUT" 2>&1; }
settled_lines() { find "$EV/corpus" -name settled.jsonl -exec cat {} + 2> /dev/null | wc -l | tr -d ' '; }

# Scenario: copies are not counted as answers.
fresh; default_runs
run_corpus segments "$LIVE"
check_json "the corpus holds the live run's answer once, as the live run's, and the replay's own answer, with run, record and order in run of each (a copy keeps its place in the order)" \
  "[{\"id\":\"$UL#0\",\"run\":\"live-1\",\"record\":\"$UL\",\"segment\":\"$A1\",\"order\":1},{\"id\":\"$UP#0\",\"run\":\"replay-1\",\"record\":\"$UP\",\"segment\":\"$A2\",\"order\":2}]" \
  "$(corpus_view)"

# Scenario: the owner settles a clash and the corpus holds it.
fresh; default_runs; third_run
run_corpus settle "$LIVE" --keep "$UL#0" --drop "$UX#0"
run_corpus segments "$LIVE"
check_json "the dropped answer is no longer in the corpus, the kept one is" \
  "[\"$UL#0\",\"$UP#0\"]" "$(corpus_ids)"

fresh; default_runs; third_run
before="$(cd "$EV/runs" && find . -type f | sort | xargs cat | cksum)"
run_corpus settle "$LIVE" --keep "$UL#0" --drop "$UX#0"
after="$(cd "$EV/runs" && find . -type f | sort | xargs cat | cksum)"
check "settling succeeds and writes nothing into any run directory" "exit=0 same" "exit=$STATUS $([ "$before" = "$after" ] && echo same || echo different)"

fresh; default_runs; third_run
run_corpus settle "$LIVE" --drop "$UX#0"; SETTLE_STATUS=$STATUS
run_corpus segments "$LIVE"
check "settle with --drop alone (no --keep) exits 0, records one line and the dropped id leaves the corpus" \
  "settle=0 recorded=1 [\"$UL#0\",\"$UP#0\"]" "settle=$SETTLE_STATUS recorded=$(settled_lines) $(corpus_ids)"

fresh; default_runs; third_run
run_corpus settle "$LIVE" --drop "$UX#0"
check_json "settle --drop alone records a line with the drop and no keep key" \
  "{\"drop\":[\"$UX#0\"]}" "$(find "$EV/corpus" -name settled.jsonl -exec cat {} + 2> /dev/null | jq -cS . 2>&1)"

fresh; default_runs; third_run
run_corpus settle "$LIVE" --drop "$UX#0"; FIRST_STATUS=$STATUS
run_corpus settle "$LIVE" --keep "$UX#0" --drop "$UL#0"
run_corpus segments "$LIVE"
check "a later --keep line revives an id an earlier --drop-only line removed" \
  "first=0 [\"$UP#0\",\"$UX#0\"]" "first=$FIRST_STATUS $(corpus_ids)"

fresh; default_runs; third_run
run_corpus settle "$LIVE" --drop "no-such-record#0"
check "settle --drop alone with an id that is not in the corpus exits 2, names the id and records nothing" \
  "exit=2 named=1 recorded=0" "exit=$STATUS named=$(seen "no-such-record#0" "$ERR") recorded=$(settled_lines)"

fresh; default_runs; third_run
run_corpus settle "$LIVE" --keep "$UL#0" --drop "no-such-record#0"
check "settling with a drop id that is not in the corpus exits 2 and names the id" \
  "exit=2 named=1" "exit=$STATUS named=$(seen "no-such-record#0" "$ERR")"

fresh; default_runs; third_run
run_corpus settle "$LIVE" --keep "no-such-record#0" --drop "$UX#0"
check "settling with a keep id that is not in the corpus exits 2 and names the id" \
  "exit=2 named=1" "exit=$STATUS named=$(seen "no-such-record#0" "$ERR")"

# corpus.sh has no matcher: `check` is an unknown subcommand, and nothing it
# does calls claude.
fresh; default_runs; third_run
run_corpus check "$LIVE"
check "check is an unknown subcommand: exit 2, the usage on stderr, nothing on stdout and no claude call" \
  "exit=2 usage=1 out=[] claude=0" "exit=$STATUS usage=$(seen "usage: corpus.sh" "$ERR") out=[$(cat "$OUT")] claude=$(calls)"

fresh; default_runs; third_run
run_corpus check "$LIVE"
check "the usage on stderr does not offer check" "0" "$(grep -c check "$ERR")"

fresh; default_runs; third_run
run_corpus segments "$LIVE"
check "segments calls no claude" "claude=0" "claude=$(calls)"

fresh; default_runs; third_run
run_corpus settle "$LIVE" --keep "$UL#0" --drop "$UX#0"
check "settle calls no claude" "claude=0" "claude=$(calls)"

fresh; default_runs
run_corpus bogus "$LIVE"
check "any other unknown subcommand exits 2 too" "exit=2" "exit=$STATUS"

# clashes lists what the run recorded in its own clashes.jsonl, cleaned of what
# the owner settled; it is a listing, not a verdict, and calls no matcher.
record_clash() { # record_clash <run name> <question> <id>...: one line of the run's clashes.jsonl
  local name="$1" q="$2"; shift 2
  jq -nc --arg q "$q" '{question: $q, answers: $ARGS.positional}' --args -- "$@" >> "$EV/runs/$name/clashes.jsonl"
}
CLASH_TEXT="clash: $Q1"$'\n'"  answer $UL#0: $A1"$'\n'"    run live-1, record $UL"$'\n'"  answer $UX#0: $AX"$'\n'"    run third-1, record $UX"$'\n'"  settle with: --keep $UL#0 --drop $UX#0"$'\n'"  settle with: --keep $UX#0 --drop $UL#0"$'\n'
listed() { cat "$OUT"; printf x; }   # the output with its trailing newline kept, and an x after it

fresh; default_runs; third_run; record_clash replay-1 "$Q1" "$UL#0" "$UX#0"
run_corpus clashes "$EV/runs/replay-1"
check "clashes lists a recorded clash with each answer's run and record and one settle line per answer, exit 0, a trailing newline" \
  "exit=0 text=${CLASH_TEXT}x" "exit=$STATUS text=$(listed)"

fresh; default_runs; third_run; record_clash replay-1 "$Q1" "$UL#0" "$UX#0"
run_corpus clashes "$EV/runs/replay-1"
check "clashes calls no claude" "claude=0" "claude=$(calls)"

fresh; default_runs; third_run; record_clash replay-1 "$Q1" "$UL#0" "$UX#0"
run_corpus settle "$LIVE" --keep "$UL#0" --drop "$UX#0"
run_corpus clashes "$EV/runs/replay-1"
check "after settling the clash, clashes lists nothing and still exits 0" "exit=0 out=[]" "exit=$STATUS out=[$(cat "$OUT")]"

fresh; default_runs; third_run
run_corpus clashes "$EV/runs/replay-1"
check "a run with no clashes.jsonl lists nothing and exits 0" "exit=0 out=[] claude=0" "exit=$STATUS out=[$(cat "$OUT")] claude=$(calls)"

fresh; default_runs; third_run; record_clash live-1 "$Q1" "$UL#0" "$UX#0"
run_corpus clashes "$EV/runs/replay-1"
check "another run's clashes.jsonl is not listed: only the target's own is" "exit=0 out=[]" "exit=$STATUS out=[$(cat "$OUT")]"

fresh; default_runs; third_run; record_clash replay-1 "$Q1" "$UL#0" "$UX#0"
make "$T/recorded/R.jsonl" "$SPEC" "$Q1" "$UR" "somewhere else"
run_corpus clashes "$T/recorded/R.jsonl"
check "a transcript target with no run directory lists nothing and exits 0" "exit=0 out=[]" "exit=$STATUS out=[$(cat "$OUT")]"

fresh; default_runs
run_corpus clashes
check "clashes without a target exits 2 with a usage that names clashes" "exit=2 usage=1 named=1" \
  "exit=$STATUS usage=$(seen "usage: corpus.sh" "$ERR") named=$(seen "clashes" "$ERR")"

fresh; default_runs
run_corpus clashes "$EV/runs/no-such-run"
check "clashes of a target that is not readable exits 2" "exit=2" "exit=$STATUS"

# Spec identity: the spec text, not the run's name, says which spec a run answered.
fresh; default_runs; make_run other-1 "a spec about something else entirely" "$Q1" "$UZ" "$AX"
run_corpus segments "$LIVE"
check_json "a run of another spec is not in the corpus" "[\"$UL#0\",\"$UP#0\"]" "$(corpus_ids)"

fresh; default_runs; make_run owner-away-1 "$SPEC$AWAY_SUFFIX"$'\n' "$Q1" "$UA" "everything, always"
run_corpus segments "$LIVE"
check_json "a run of the same spec started with the owner away, and with trailing whitespace, is in the corpus" \
  "[\"$UL#0\",\"$UP#0\",\"$UA#0\"]" "$(corpus_ids)"

fresh; default_runs
mkdir -p "$EV/runs/headless-1"; t_headless "$EV/runs/headless-1/transcript.jsonl"
printf '%s\n' "$PROMPT_CMD $SPEC$AWAY_SUFFIX" > "$EV/runs/headless-1/prompt.txt"
run_corpus segments "$EV/runs/headless-1"
check_json "a headless run with no command record is identified by its prompt.txt: its corpus is the spec's" \
  "[\"$UL#0\",\"$UP#0\"]" "$(corpus_ids)"

fresh; default_runs
mkdir -p "$EV/runs/stream-1"; t_stream "$EV/runs/stream-1/transcript.jsonl"
printf '%s\n' "$PROMPT_CMD $SPEC" > "$EV/runs/stream-1/prompt.txt"
run_corpus segments "$EV/runs/stream-1"
check "a stream-json run with a prompt.txt gets its spec from the prompt: its corpus is the spec's, and stderr is empty" \
  "[\"$UL#0\",\"$UP#0\"] err=" "$(jq -c '[.[].id] | sort' "$OUT") err=$(cat "$ERR")"

fresh; default_runs
make "$T/recorded/R.jsonl" "$SPEC" "$Q1" "$UR" "somewhere else"
run_corpus segments "$T/recorded/R.jsonl"
check_json "a transcript outside runs/ given on the command line is in the corpus, as the run R" \
  "[{\"id\":\"$UL#0\",\"run\":\"live-1\"},{\"id\":\"$UP#0\",\"run\":\"replay-1\"},{\"id\":\"$UR#0\",\"run\":\"R\"}]" \
  "$(jq -cS '[.[] | {id, run}] | sort_by(.id)' "$OUT" 2>&1)"

# A stand-in's messages answer the stand-in's questions, not the owner's.
fresh; default_runs
make_run standin-1 "$SPEC" "$Q1" "$US" "the stand-in's answer"
echo '{}' > "$EV/runs/standin-1/standin.jsonl"
run_corpus segments "$LIVE"
check_json "a run with a stand-in counts no answers" "[\"$UL#0\",\"$UP#0\"]" "$(corpus_ids)"

# A replay of a recorded transcript outside runs/: that transcript's answers are in its corpus.
replay_of_recorded() { # replay_of_recorded <where R lives: outside|inside>: R answered Q1 "somewhere else", replay-2 answered it AX
  default_runs
  if [ "$1" = outside ]; then
    R="$T/recorded/recorded-1.jsonl"; make "$R" "$SPEC" "$Q1" "$UR" "somewhere else"
  else
    mkdir -p "$EV/runs/recorded-1"; R="$EV/runs/recorded-1/transcript.jsonl"; make "$R" "$SPEC" "$Q1" "$UR" "somewhere else"
  fi
  make_run replay-2 "$SPEC" "$Q1" "$UX" "$AX"
  echo '{"n":1,"source":"owner"}' > "$EV/runs/replay-2/replay.jsonl"
  printf '%s\n' "$R" > "$EV/runs/replay-2/replayed-from.txt"
}
fresh; replay_of_recorded outside
run_corpus segments "$EV/runs/replay-2/transcript.jsonl"
check_json "the corpus of a replay's transcript.jsonl holds the recorded transcript's answers as the run named for its file" \
  "[\"$UL#0\",\"$UP#0\",\"$UX#0\",\"$UR#0\"]" "$(corpus_ids)"

fresh; replay_of_recorded outside
run_corpus settle "$EV/runs/replay-2" --keep "$UX#0" --drop "$UR#0"; SETTLE_STATUS=$STATUS
run_corpus segments "$EV/runs/replay-2"
check "from a replay's run directory the owner can settle an answer of the recorded transcript: settle exits 0 and it leaves the corpus" \
  "settle=0 [\"$UL#0\",\"$UP#0\",\"$UX#0\"]" "settle=$SETTLE_STATUS $(corpus_ids)"

fresh; replay_of_recorded inside
run_corpus segments "$EV/runs/replay-2"
check_json "a recorded transcript that is itself a run under runs/ is counted once" \
  "[\"$UL#0\",\"$UP#0\",\"$UX#0\",\"$UR#0\"]" "$(corpus_ids)"

# Settling: the latest line naming an id decides it.
fresh; default_runs; third_run
run_corpus settle "$LIVE" --keep "$UL#0" --drop "$UL#0"
check "settling that keeps and drops one id in one line exits 2, names the id and records nothing" \
  "exit=2 named=1 recorded=0" "exit=$STATUS named=$(seen "$UL#0" "$ERR") recorded=$(settled_lines)"

fresh; default_runs; third_run
run_corpus settle "$LIVE" --keep "$UL#0" --drop "$UX#0"
run_corpus settle "$LIVE" --keep "$UX#0" --drop "$UP#0"; SETTLE_STATUS=$STATUS
run_corpus segments "$LIVE"
check "a later settle that keeps an id an earlier one dropped exits 0, records it, and the id is back in the corpus" \
  "settle=0 recorded=2 [\"$UL#0\",\"$UX#0\"]" "settle=$SETTLE_STATUS recorded=$(settled_lines) $(corpus_ids)"

fresh; default_runs; third_run
run_corpus settle "$LIVE" --keep "$UL#0" --drop "$UX#0"
run_corpus settle "$LIVE" --keep "$UP#0" --drop "$UL#0"; SETTLE_STATUS=$STATUS
run_corpus segments "$LIVE"
check "a later settle that drops an id an earlier one kept exits 0, records it, and the id leaves the corpus" \
  "settle=0 recorded=2 [\"$UP#0\"]" "settle=$SETTLE_STATUS recorded=$(settled_lines) $(corpus_ids)"

# The shared definitions of corpus.jq and replay.jq stay equal.
def_block() { # def_block <file> <name>: the blank-line-separated paragraph holding "def <name>", comments above included
  awk -v RS= -v pat="(^|\n)def $2[:(]" '$0 ~ pat { print; exit }' "$1"
}
for name in first_user_index final_chain owner_text is_owner_record owner_messages first_user_content assistant_text pairs segments_of; do
  check "def $name is the same in corpus.jq and replay.jq" "$(def_block "$HERE/replay.jq" "$name")" "$(def_block "$HERE/corpus.jq" "$name")"
done

exit "$FAILED"
