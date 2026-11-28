#!/usr/bin/env bash
# Black-box checks for run.sh, with a stub claude on PATH. No real CLI runs.
# Usage: check.sh
set -uo pipefail

# `git rebase --exec` exports GIT_DIR and friends; left set, `git init` in a
# temp dir would re-init the caller's repo. Start from a clean git environment.
unset $(git rev-parse --local-env-vars)

HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/harness-check.XXXXXX")"
trap 'rm -rf "$T"' EXIT
FAILED=0

# run.sh runs from a copy inside a temp repo, so the repo it finds is the temp
# one and "under the repo's evals/story-definition/" means $SD.
SD="$T/repo/evals/story-definition"
mkdir -p "$SD/harness" "$SD/prompts"
cp "$HERE/run.sh" "$SD/harness/run.sh"
git -C "$T/repo" init -q

mkdir -p "$T/bin" "$T/tmpd" "$T/evals/config/sources/bjornstack/plugin" "$T/evals/config/sources/bjornstack/strategies" \
  "$T/evals/config/sources/bjornstack/tenets" "$T/evals/specs"
echo "0123456789abcdef0123456789abcdef01234567" > "$T/evals/config/sources/bjornstack.commit"
echo "briefkasten spec" > "$T/evals/specs/briefkasten.md"
echo "Add a CSV download button." > "$SD/prompt.txt"
echo "Answer as the owner of this app. Keep answers short." > "$SD/standin.txt"

# The init event's plugins list in the shape the real CLI emits: the frozen
# copy of the plugin plus builtins. Stubs use it unless STUB_PLUGINS is set.
COPY="$T/evals/config/sources/bjornstack"
FROZEN="$COPY/plugin"
# The frozen copy's layout: the plugin reaches the rule files through
# symlinks to its siblings, as freeze.sh leaves them.
echo "strategy" > "$COPY/strategies/s.md"
echo "tenet" > "$COPY/tenets/t.md"
ln -s ../strategies "$COPY/plugin/strategies"
ln -s ../tenets "$COPY/plugin/tenets"
export REAL_PLUGINS="[{\"name\":\"bjornstack\",\"path\":\"$FROZEN\",\"source\":\"bjornstack@inline\",\"version\":\"0.1.0\"},{\"name\":\"cc-plugin-agents-md\",\"path\":\"builtin\",\"source\":\"cc-plugin-agents-md@builtin\"},{\"name\":\"cc-plugin-telemetry\",\"path\":\"builtin\",\"source\":\"cc-plugin-telemetry@builtin\"}]"

# Stub security: logs its arguments, one call per line, to $STUB_LOG.security
# and prints the token. With STUB_KEYCHAIN_MISSING=1 it fails the way the real
# one does for a missing item.
cat > "$T/bin/security" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "$STUB_LOG.security"
if [ "${STUB_KEYCHAIN_MISSING:-}" = 1 ]; then
  echo "security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain." >&2
  exit 44
fi
echo "tok-from-keychain"
STUB
chmod +x "$T/bin/security"

# Stub claude: logs its arguments, one line per call, to $STUB_LOG. A call
# with --plugin-dir is a session turn; the session asks a question for its
# first $STUB_QUESTIONS turns. Any other call is the stand-in, which answers
# for its first $STUB_ANSWERS calls and then says DONE.
cat > "$T/bin/claude" <<'STUB'
#!/usr/bin/env bash
line="$*"
echo "${line//$'\n'/ }" >> "$STUB_LOG"
kind=other
printf '%s\n' "$@" > "$STUB_LOG.args.$$"
for a in "$@"; do
  [ "$a" != --plugin-dir ] || kind=session
  [ "$a" != --restricted ] || [ "$kind" = session ] || kind=standin
done
n=$(grep -c -- "^STUB_$kind" "$STUB_LOG.count" 2>/dev/null || true)
echo "STUB_$kind" >> "$STUB_LOG.count"
n=$((n + 1))
mv "$STUB_LOG.args.$$" "$STUB_LOG.$kind.$n.args"
prompt="$2"
[ "${*: -2:1}" != -- ] || prompt="${*: -1}"
# Full record of the call: cwd, whether it is empty, config dir, raw arguments.
{
  echo "cwd=$PWD"
  echo "entries=$(ls -A | wc -l | tr -d ' ')"
  echo "config=${CLAUDE_CONFIG_DIR:-}"
  echo "prompt<<"
  echo "$prompt"
  echo ">>"
  echo "token=${CLAUDE_CODE_OAUTH_TOKEN:-}"
  echo "apikey=${ANTHROPIC_API_KEY-unset}"
} > "$STUB_LOG.$kind.$n"
if [ "$kind" = session ]; then
  text="Which orders count as yesterday's?"
  [ "$n" -le "${STUB_QUESTIONS:-2}" ] || text="Here are the stories."
  [ "$n" -ne 1 ] || echo "written by the session" > session-note.txt
  # With STUB_REWRITE_COMMIT the session replaces the commit id mid-run.
  [ -z "${STUB_REWRITE_COMMIT:-}" ] || echo "$STUB_REWRITE_COMMIT" > "$EVALS_DIR/config/sources/bjornstack.commit"
  printf '{"type":"system","subtype":"init","model":"stub","plugins":%s}\n' "${STUB_PLUGINS:-$REAL_PLUGINS}"
  printf '{"type":"result","session_id":"sid-1","result":"%s %s"}\n' "$text" "turn$n"
elif [ "$kind" = standin ]; then
  text="DONE"
  [ "$n" -gt "${STUB_ANSWERS:-1}" ] || text="${STUB_ANSWER_TEXT:-Calendar day, store time.}"
  printf '{"type":"result","result":"%s"}\n' "$text"
else
  printf '{"type":"system","subtype":"init","model":"stub-arm"}\n{"type":"result","result":"away"}\n'
fi
STUB
chmod +x "$T/bin/claude"

run() { # run <name> [run.sh args...]; stdout/stderr to $T/last.out
  local name="$1"; shift
  rm -f "$T"/stub.log*; : > "$T/stub.log"; : > "$T/stub.log.count"
  rm -rf "$T/tmpd"; mkdir "$T/tmpd"   # run.sh's TMPDIR: its temp directories must not outlive it
  PATH="$T/bin:$PATH" EVALS_DIR="$T/evals" STUB_LOG="$T/stub.log" TMPDIR="$T/tmpd" \
    ANTHROPIC_API_KEY=from-env "$SD/harness/run.sh" "$name" "$@" \
    > "$T/$name.out" 2>&1
}

check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then echo "ok   $1"; else
    echo "FAIL $1"; echo "  expected: $2"; echo "  actual:   $3"; FAILED=1
  fi
}

# Scenario: a stand-in answers each question until the session asks none.
STUB_QUESTIONS=2 STUB_ANSWERS=2 run standin --prompt "$SD/prompt.txt" --stand-in "$SD/standin.txt"
check "stand-in run exits 0" "0" "$?"
R="$T/evals/runs/standin"
check "session turns in transcript.jsonl" "6" "$(wc -l < "$R/transcript.jsonl" | tr -d ' ')"
check "stand-in turns in standin.jsonl" "3" "$(wc -l < "$R/standin.jsonl" | tr -d ' ')"
check "first session call starts with the skill and the prompt" \
  "-p /bjornstack:story-definition Add a CSV download button. --restricted --plugin-dir $T/evals/config/sources/bjornstack/plugin --tools Read,Write,Edit --permission-mode acceptEdits --allowedTools Read(/$T/evals/config/sources/bjornstack/**) --add-dir $T/evals/config/sources/bjornstack --disallowedTools Write(/$T/evals/config/sources/bjornstack/**),Edit(/$T/evals/config/sources/bjornstack/**) --output-format stream-json --verbose" \
  "$(grep -- '--plugin-dir' "$T/stub.log" | head -n 1 | sed 's/ --strict-mcp-config//')"
check "session is resumed with the stand-in's answer as the last argument, after --" \
  "--|Calendar day, store time." "$(tail -n 2 "$T/stub.log.session.2.args" | paste -sd'|' -)"
check "session is resumed from the first turn's session id" "--resume|sid-1" \
  "$(grep -x -A1 -e '--resume' "$T/stub.log.session.2.args" | paste -sd'|' -)"
check "resumed session calls carry --add-dir <frozen>" "1" \
  "$(grep -- '--plugin-dir' "$T/stub.log" | sed -n 2p | grep -c -- "--add-dir $T/evals/config/sources/bjornstack ")"
# What a --restricted session's file tools may reach: the resolved target of
# every symlink under plugin/ must lie under the --add-dir argument, under
# the Read rule's path, and under the Write and Edit deny rules' paths.
SESSION1="$(grep -- '--plugin-dir' "$T/stub.log" | head -n 1)"
arg_add() { echo "$SESSION1" | sed -n 's/.*--add-dir \([^ ]*\).*/\1/p'; }
# A rule's leading // marks an absolute path: strip the one / the syntax adds.
arg_rule() { echo "$SESSION1" | sed -n "s/.*$1(\\/\\(\\/[^ )]*\\)\\/\\*\\*).*/\\1/p" | head -n 1; }
covered() { # covered <dir>: does every symlink under plugin/ resolve under <dir>?
  local base out="" l t
  base="$(cd -P "$1" 2>/dev/null && pwd -P)"
  [ -n "$base" ] || { echo "no"; return; }
  for l in "$COPY"/plugin/*; do
    [ -L "$l" ] || continue
    t="$(cd -P "$l" && pwd -P)"
    case "$t/" in "$base"/*) out="$out yes" ;; *) out="$out no" ;; esac
  done
  echo "${out# }"
}
check "the plugin's symlinks resolve under the --add-dir argument" "yes yes" "$(covered "$(arg_add)")"
check "the plugin's symlinks resolve under the Read rule's path" "yes yes" "$(covered "$(arg_rule Read)")"
check "the plugin's symlinks resolve under the Write deny rule's path" "yes yes" "$(covered "$(arg_rule Write)")"
check "the plugin's symlinks resolve under the Edit deny rule's path" "yes yes" "$(covered "$(arg_rule Edit)")"
check "stand-in calls carry no --add-dir" "0" \
  "$(grep -v -- '--plugin-dir' "$T/stub.log" | grep -c -- '--add-dir')"
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
STUB_QUESTIONS=99 STUB_ANSWERS=99 run capped --prompt "$SD/prompt.txt" --stand-in "$SD/standin.txt"
check "run stops after 20 answers" "21" \
  "$(grep -c -- '--plugin-dir' "$T/stub.log")"

# Scenario: an owner-away run with any first prompt.
run away --prompt "$SD/prompt.txt" --owner-away
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

# Scenario: run.sh takes the token from the Keychain only.
tokline() { grep '^token=' "$T/stub.log.$1"; }
secline() { cat "$T/stub.log.security" 2>/dev/null; }
USER=evaluser run tok --prompt "$SD/prompt.txt"
check "security is called once with the service and the account" \
  "find-generic-password -a evaluser -s bjornstack-evals -w" "$(secline)"
check "session call gets the token from the Keychain" "token=tok-from-keychain" "$(tokline session.1)"
check "session call has no ANTHROPIC_API_KEY" "apikey=unset" "$(grep '^apikey=' "$T/stub.log.session.1")"
STUB_QUESTIONS=1 STUB_ANSWERS=1 run tok2 --prompt "$SD/prompt.txt" --stand-in "$SD/standin.txt"
check "stand-in call gets the token from the Keychain" "token=tok-from-keychain" "$(tokline standin.1)"
check "stand-in call has no ANTHROPIC_API_KEY" "apikey=unset" "$(grep '^apikey=' "$T/stub.log.standin.1")"
CLAUDE_CODE_OAUTH_TOKEN=from-env run tok3 --prompt "$SD/prompt.txt"
check "a token in the caller's environment is not used" "token=tok-from-keychain" "$(tokline session.1)"
run tok4 --owner-away
check "an arm run does not get the token" "token=" "$(tokline other.1)"
check "an arm run makes no security call" "" "$(secline)"

rc=$(unset USER; run nouser --prompt "$SD/prompt.txt"; echo $?)
check "with USER unset run.sh exits 0" "0" "$rc"
check "with USER unset security gets the login name" \
  "find-generic-password -a $(id -un) -s bjornstack-evals -w" "$(secline)"

namesfix() { # counts of lines naming the service, the account, setup-token, add-generic-password
  echo "$(grep -c -F 'bjornstack-evals' "$1") $(grep -c -F "$2" "$1") $(grep -c -F 'claude setup-token' "$1") $(grep -c -F 'security add-generic-password' "$1")"
}
USER=evaluser STUB_KEYCHAIN_MISSING=1 run nokey --prompt "$SD/prompt.txt"
check "a missing Keychain entry exits non-zero" "1" "$([ "$?" -ne 0 ] && echo 1 || echo 0)"
check "a missing Keychain entry names service, account and both steps" "1 1 1 1" "$(namesfix "$T/nokey.out" evaluser)"
check "a missing Keychain entry starts no claude call" "0" "$(wc -l < "$T/stub.log" | tr -d ' ')"

# Isolation: an init plugin list with anything but the frozen copy and
# builtins fails the run before the stand-in starts. The real shape passes
# (every --prompt run above uses it).
REFUSED_NAMES=(marketplace-plugin unfrozen-path builtin-source-bad-path builtin-path-bad-source old-string-shape)
REFUSED_LISTS=(
  "[{\"name\":\"other\",\"path\":\"/Users/x/.claude/plugins/cache/market/other\",\"source\":\"other@market\",\"version\":\"1.0.0\"}]"
  "[{\"name\":\"bjornstack\",\"path\":\"/Users/x/elsewhere/plugin\",\"source\":\"bjornstack@inline\",\"version\":\"0.1.0\"}]"
  "[{\"name\":\"cc-plugin-x\",\"path\":\"/Users/x/elsewhere\",\"source\":\"cc-plugin-x@builtin\"}]"
  "[{\"name\":\"cc-plugin-x\",\"path\":\"builtin\",\"source\":\"cc-plugin-x@market\"}]"
  "[\"bjornstack@inline\",\"builtin\"]"
)
for i in "${!REFUSED_NAMES[@]}"; do
  n="${REFUSED_NAMES[$i]}"
  STUB_PLUGINS="${REFUSED_LISTS[$i]}" run "refused-$n" --prompt "$SD/prompt.txt" --stand-in "$SD/standin.txt"
  check "init plugins $n exits 1" "1" "$?"
  check "init plugins $n starts no stand-in call" "0" "$(grep -c '^STUB_standin' "$T/stub.log.count")"
done

# Scenario: a run records the plugin commit it loaded.
check "a --prompt run writes plugin-commit.txt as a copy of bjornstack.commit" \
  "0123456789abcdef0123456789abcdef01234567" "$(cat "$T/evals/runs/standin/plugin-commit.txt" 2>&1)"
check "an owner-away --prompt run writes plugin-commit.txt too" \
  "0123456789abcdef0123456789abcdef01234567" "$(cat "$T/evals/runs/away/plugin-commit.txt" 2>&1)"
check "an arm run without --prompt writes no plugin-commit.txt" "no" \
  "$([ -e "$T/evals/runs/brief/plugin-commit.txt" ] && echo yes || echo no)"

# plugin-commit.txt is the id as of run start: a rewrite during the session does not reach it.
STUB_REWRITE_COMMIT="fedcba9876543210fedcba9876543210fedcba98" run rewritten --prompt "$SD/prompt.txt"
check "plugin-commit.txt holds the id from run start when the session rewrites bjornstack.commit" \
  "0123456789abcdef0123456789abcdef01234567" "$(cat "$T/evals/runs/rewritten/plugin-commit.txt" 2>&1)"
echo "0123456789abcdef0123456789abcdef01234567" > "$T/evals/config/sources/bjornstack.commit"

mv "$T/evals/config/sources/bjornstack.commit" "$T/commit.away"
run nocommit --prompt "$SD/prompt.txt"
check "a --prompt run without bjornstack.commit exits non-zero" "1" "$([ "$?" -ne 0 ] && echo 1 || echo 0)"
check "a --prompt run without bjornstack.commit names the file" "1" "$(grep -c 'bjornstack.commit' "$T/nocommit.out")"
check "a --prompt run without bjornstack.commit starts no claude call" "0" "$(wc -l < "$T/stub.log" | tr -d ' ')"
mv "$T/commit.away" "$T/evals/config/sources/bjornstack.commit"

# Scenario: the stand-in's answer is data, never an option. Whatever it
# starts with, it comes after "--" as the last argument.
ANSWERS_NAMES=(dashed-option dash-space)
ANSWERS_TEXT=("--x=1" "- not a list")
for i in "${!ANSWERS_NAMES[@]}"; do
  STUB_ANSWER_TEXT="${ANSWERS_TEXT[$i]}" STUB_QUESTIONS=1 STUB_ANSWERS=1 \
    run "answer-${ANSWERS_NAMES[$i]}" --prompt "$SD/prompt.txt" --stand-in "$SD/standin.txt"
  check "a stand-in answer '${ANSWERS_TEXT[$i]}' is the last argument of the resumed call, after --" \
    "--|${ANSWERS_TEXT[$i]}" "$(tail -n 2 "$T/stub.log.session.2.args" | paste -sd'|' -)"
done

# Scenario: no claude call loads MCP servers from the user's config.
STUB_QUESTIONS=1 STUB_ANSWERS=1 run mcp-session --prompt "$SD/prompt.txt" --stand-in "$SD/standin.txt"
check "every claude call of a stand-in run (session, stand-in, resume, stand-in) carries --strict-mcp-config" "0 4" \
  "$(grep -vc -- '--strict-mcp-config' "$T/stub.log") $(grep -c . "$T/stub.log")"
run mcp-arm --owner-away
check "the claude call of an arm run carries --strict-mcp-config" "0 1" \
  "$(grep -vc -- '--strict-mcp-config' "$T/stub.log") $(grep -c . "$T/stub.log")"

# Scenario: stand-in calls leave no session behind, and no temp directory outlives the run.
STUB_QUESTIONS=1 STUB_ANSWERS=1 run persist --prompt "$SD/prompt.txt" --stand-in "$SD/standin.txt"
check "every stand-in call carries --no-session-persistence" "0 2" \
  "$(grep -v -- '--plugin-dir' "$T/stub.log" | grep -vc -- '--no-session-persistence') $(grep -vc -- '--plugin-dir' "$T/stub.log")"
check "a stand-in run leaves nothing in its TMPDIR" "" "$(ls -A "$T/tmpd")"
check "an owner-away run leaves nothing in its TMPDIR" "" "$(run tmp-away --prompt "$SD/prompt.txt" --owner-away; ls -A "$T/tmpd")"
check "an arm run leaves nothing in its TMPDIR" "" "$(run tmp-arm --owner-away; ls -A "$T/tmpd")"
check "a run that fails on the init plugin list leaves nothing in its TMPDIR" "" \
  "$(STUB_PLUGINS="${REFUSED_LISTS[0]}" run tmp-refused --prompt "$SD/prompt.txt" --stand-in "$SD/standin.txt"; ls -A "$T/tmpd")"

# Scenario: run.sh refuses what it must not pass on. Exit 2 before any
# claude or security call, and no run directory.
REFUSALS=0
refused() { # refused <description> <run name prefix> <run.sh args...>
  local d="$1" n="$2-$REFUSALS"; shift 2
  REFUSALS=$((REFUSALS + 1))
  run "$n" "$@"
  check "$d is refused: exit 2, no claude call, no security call, no run directory" "2 0 0 no" \
    "$? $(grep -c . "$T/stub.log") $(secline | grep -c .) $([ -e "$T/evals/runs/$n" ] && echo yes || echo no)"
}
mkdir -p "$T/outside-dir" "$T/repo/evals/other"
echo "outside" > "$T/outside.txt"
echo "outside" > "$T/outside-dir/p.txt"
echo "outside" > "$T/repo/evals/other/p.txt"
echo "outside" > "$T/repo/README.txt"
ln -s "$T/outside-dir" "$SD/linked"
for bad in "../evil" "a/b" "/abs" "-x" "a b" "a;b"; do
  refused "--arm '$bad'" "arm-bad" --arm "$bad"
done
for flag in --prompt --stand-in; do
  for outside in "$T/outside.txt" "$T/repo/README.txt" "$T/repo/evals/other/p.txt" "$SD/../other/p.txt" "$SD/linked/p.txt"; do
    if [ "$flag" = --prompt ]; then
      refused "$flag $outside" "file-bad" --prompt "$outside"
    else
      refused "$flag $outside" "file-bad" --prompt "$SD/prompt.txt" --stand-in "$outside"
    fi
  done
done
mkdir -p "$SD/prompts/nested"
echo "Nested prompt." > "$SD/prompts/nested/p.txt"
run nested --prompt "$SD/prompts/nested/p.txt"
check "a --prompt file in a subdirectory of evals/story-definition/ is accepted" "0" "$?"

# Usage errors.
run u1 --stand-in "$SD/standin.txt"; check "--stand-in without --prompt exits 2" "2" "$?"
run u2 --prompt "$SD/prompt.txt" --stand-in "$SD/standin.txt" --owner-away; check "--stand-in with --owner-away exits 2" "2" "$?"
check "usage line is printed without --prompt" "1" "$(grep -c '^usage: run.sh' "$T/u1.out")"
check "usage line is printed with --owner-away" "1" "$(grep -c '^usage: run.sh' "$T/u2.out")"

exit "$FAILED"
