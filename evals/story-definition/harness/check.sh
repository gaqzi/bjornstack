#!/usr/bin/env bash
# Black-box checks for run.sh, with a stub claude on PATH. No real CLI runs.
# Usage: check.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/harness-check.XXXXXX")"
trap 'rm -rf "$T"' EXIT
FAILED=0

mkdir -p "$T/bin" "$T/evals/config/sources/bjornstack/plugin" "$T/evals/specs"
echo "briefkasten spec" > "$T/evals/specs/briefkasten.md"
echo "Add a CSV download button." > "$T/prompt.txt"
echo "Answer as the owner of this app. Keep answers short." > "$T/standin.txt"

# Stub claude: logs its arguments, one line per call, to $STUB_LOG. A call
# with --plugin-dir is a session turn; the session asks a question for its
# first $STUB_QUESTIONS turns. Any other call is the stand-in, which answers
# for its first $STUB_ANSWERS calls and then says DONE.
cat > "$T/bin/claude" <<'STUB'
#!/usr/bin/env bash
line="$*"
echo "${line//$'\n'/ }" >> "$STUB_LOG"
kind=other
for a in "$@"; do
  [ "$a" != --plugin-dir ] || kind=session
  [ "$a" != --restricted ] || [ "$kind" = session ] || kind=standin
done
n=$(grep -c -- "^STUB_$kind" "$STUB_LOG.count" 2>/dev/null || true)
echo "STUB_$kind" >> "$STUB_LOG.count"
n=$((n + 1))
# Full record of the call: cwd, whether it is empty, config dir, raw arguments.
{
  echo "cwd=$PWD"
  echo "entries=$(ls -A | wc -l | tr -d ' ')"
  echo "config=${CLAUDE_CONFIG_DIR:-}"
  echo "prompt<<"
  echo "$2"
  echo ">>"
} > "$STUB_LOG.$kind.$n"
if [ "$kind" = session ]; then
  text="Which orders count as yesterday's?"
  [ "$n" -le "${STUB_QUESTIONS:-2}" ] || text="Here are the stories."
  [ "$n" -ne 1 ] || echo "written by the session" > session-note.txt
  printf '{"type":"system","subtype":"init","model":"stub","plugins":%s}\n' "${STUB_PLUGINS:-[\"bjornstack@inline\",\"builtin\"]}"
  printf '{"type":"result","session_id":"sid-1","result":"%s %s"}\n' "$text" "turn$n"
elif [ "$kind" = standin ]; then
  text="DONE"
  [ "$n" -gt "${STUB_ANSWERS:-1}" ] || text="Calendar day, store time."
  printf '{"type":"result","result":"%s"}\n' "$text"
else
  printf '{"type":"system","subtype":"init","model":"stub-arm"}\n{"type":"result","result":"away"}\n'
fi
STUB
chmod +x "$T/bin/claude"

run() { # run <name> [run.sh args...]; stdout/stderr to $T/last.out
  local name="$1"; shift
  rm -f "$T"/stub.log*; : > "$T/stub.log"; : > "$T/stub.log.count"
  PATH="$T/bin:$PATH" EVALS_DIR="$T/evals" STUB_LOG="$T/stub.log" \
    CLAUDE_CODE_OAUTH_TOKEN=tok ANTHROPIC_API_KEY="" "$HERE/run.sh" "$name" "$@" \
    > "$T/$name.out" 2>&1
}

check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then echo "ok   $1"; else
    echo "FAIL $1"; echo "  expected: $2"; echo "  actual:   $3"; FAILED=1
  fi
}

# Scenario: a stand-in answers each question until the session asks none.
STUB_QUESTIONS=2 STUB_ANSWERS=2 run standin --prompt "$T/prompt.txt" --stand-in "$T/standin.txt"
check "stand-in run exits 0" "0" "$?"
R="$T/evals/runs/standin"
check "session turns in transcript.jsonl" "6" "$(wc -l < "$R/transcript.jsonl" | tr -d ' ')"
check "stand-in turns in standin.jsonl" "3" "$(wc -l < "$R/standin.jsonl" | tr -d ' ')"
check "first session call starts with the skill and the prompt" \
  "-p /bjornstack:story-definition Add a CSV download button. --restricted --plugin-dir $T/evals/config/sources/bjornstack/plugin --tools Read,Write,Edit --permission-mode acceptEdits --allowedTools Read(/$T/evals/config/sources/bjornstack/plugin/**) --output-format stream-json --verbose" \
  "$(grep -- '--plugin-dir' "$T/stub.log" | head -n 1)"
check "session is resumed with the stand-in's answer" \
  "-p Calendar day, store time. --resume sid-1" \
  "$(grep -- '--plugin-dir' "$T/stub.log" | sed -n 2p | sed 's/ --restricted.*//')"
check "stand-in calls carry the stand-in file; session calls do not" "3 0" \
  "$(grep -v -- '--plugin-dir' "$T/stub.log" | grep -c "Answer as the owner of this app. Keep answers short.") $(grep -- '--plugin-dir' "$T/stub.log" | grep -c "Answer as the owner")"

check "stand-in call gets the prompt file text" "1" \
  "$(grep -c "Add a CSV download button." "$T/stub.log.standin.2")"
check "stand-in call gets the session's latest turn" "1" \
  "$(grep -c "Which orders count as yesterday's? turn2" "$T/stub.log.standin.2")"
check "stand-in call does not get the earlier turn" "0" \
  "$(grep -c "turn1" "$T/stub.log.standin.2")"
check "session runs from an empty directory" "entries=0" "$(sed -n 2p "$T/stub.log.session.1")"
check "stand-in runs from its own empty directory" "yes entries=0" \
  "$([ "$(sed -n 1p "$T/stub.log.standin.1")" != "$(sed -n 1p "$T/stub.log.session.1")" ] && echo yes) $(sed -n 2p "$T/stub.log.standin.1")"
check "session turns carry the normal config (no CLAUDE_CONFIG_DIR)" "config=" "$(sed -n 3p "$T/stub.log.session.1")"

# The cap: a stand-in that never says DONE stops after 20 answers.
STUB_QUESTIONS=99 STUB_ANSWERS=99 run capped --prompt "$T/prompt.txt" --stand-in "$T/standin.txt"
check "run stops after 20 answers" "21" \
  "$(grep -c -- '--plugin-dir' "$T/stub.log")"

# Scenario: an owner-away run with any first prompt.
run away --prompt "$T/prompt.txt" --owner-away
check "owner-away prompt ends with the away line" \
  "The owner is away for this session" "$(tail -n 1 "$T/evals/runs/away/prompt.txt")"
check "owner-away run starts one session and no stand-in" "1" "$(wc -l < "$T/stub.log" | tr -d ' ')"
check "owner-away session call has --restricted --plugin-dir <frozen>" "1" \
  "$(grep -c -- "--restricted --plugin-dir $T/evals/config/sources/bjornstack/plugin" "$T/stub.log")"
check "owner-away prompt sent to claude ends with the away line" "The owner is away for this session" \
  "$(awk '/^prompt<</{f=1;next} /^>>$/{f=0} f' "$T/stub.log.session.1" | grep . | tail -n 1)"
check "owner-away run has no standin.jsonl" "no" "$([ -e "$T/evals/runs/away/standin.jsonl" ] && echo yes || echo no)"

# Scenario: briefkasten runs are unchanged.
run brief --owner-away
check "briefkasten run uses the arm's CLAUDE_CONFIG_DIR path (no --plugin-dir)" "0" \
  "$(grep -c -- '--plugin-dir' "$T/stub.log")"
check "briefkasten run uses the arm's CLAUDE_CONFIG_DIR" "config=$T/evals/config/bjornstack-arm" \
  "$(sed -n 3p "$T/stub.log.other.1")"
check "briefkasten prompt holds the spec" "/bjornstack:story-definition briefkasten spec" \
  "$(head -n 1 "$T/evals/runs/brief/prompt.txt")"

# Isolation: a session that loads another plugin fails the run.
STUB_PLUGINS='["bjornstack@inline","builtin","other@market"]' run leaky --prompt "$T/prompt.txt"
check "an extra plugin in the init event exits 1" "1" "$?"
STUB_PLUGINS='[{"name":"other@builtin-tools"}]' run leaky2 --prompt "$T/prompt.txt"
check "a plugin named like builtin exits 1" "1" "$?"

# Usage errors.
run u1 --stand-in "$T/standin.txt"; check "--stand-in without --prompt exits 2" "2" "$?"
run u2 --prompt "$T/prompt.txt" --stand-in "$T/standin.txt" --owner-away; check "--stand-in with --owner-away exits 2" "2" "$?"
check "usage line is printed without --prompt" "1" "$(grep -c '^usage: run.sh' "$T/u1.out")"
check "usage line is printed with --owner-away" "1" "$(grep -c '^usage: run.sh' "$T/u2.out")"

exit "$FAILED"
