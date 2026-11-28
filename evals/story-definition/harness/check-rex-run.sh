#!/usr/bin/env bash
# Black-box checks for rex-run.sh, with a stub rex on PATH and stub run.sh,
# freeze.sh, replay.sh and a clashing corpus.sh stub beside a copy of rex-run.sh.
# No real rex or claude runs. rex-run.sh never calls corpus.sh: the stub is
# there only so a call shows (scenario: no corpus scan runs around an eval,
# at the end). What corpus.sh decides is covered in check-corpus.sh. There are no
# unit-layer cases: rex-run.sh holds no rules beyond the run-name check,
# which is a black-box case below (refusals).
# Usage: check-rex-run.sh
set -uo pipefail

# `git rebase --exec` exports GIT_DIR and friends; left set, `git init` in a
# temp dir would re-init the caller's repo. Start from a clean git environment.
unset $(git rev-parse --local-env-vars)

HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/rex-run-check.XXXXXX")"
T="$(cd "$T" && pwd)"   # a TMPDIR ending in / would give "//", which rex-run.sh's own path drops
trap 'rm -rf "$T"' EXIT
FAILED=0

H="$T/repo/evals/story-definition/harness"
EV="$T/home/workspace/bjornstack-evals"   # the default eval home under the temp HOME
mkdir -p "$T/bin" "$H" "$EV"
EVP="$(cd "$EV" && pwd -P)"   # run.sh reports its physical directory
cp "$HERE/rex-run.sh" "$H/rex-run.sh"
cp "$HERE/inputs.sh" "$H/inputs.sh"
# replay.jq sits beside rex-run.sh, which reads it for the owner-message check.
cp "$HERE/replay.jq" "$H/replay.jq"
# Prompt and stand-in files rex-run.sh may pass on live under the repo's evals/story-definition/.
SD="$T/repo/evals/story-definition"
mkdir -p "$SD/prompts"
echo "a prompt" > "$SD/my prompt.txt"
echo "a stand-in" > "$SD/my standin.txt"
echo "a prompt" > "$SD/a b; touch pwned"
# The repo holding rex-run.sh, for --freeze: one commit, one file.
echo content > "$T/repo/file.txt"
git -C "$T/repo" init -q
git -C "$T/repo" add -A
git -C "$T/repo" -c user.name=t -c user.email=t@example.com commit -q -m one
COMMIT="$(git -C "$T/repo" rev-parse HEAD)"

# Stub run.sh: records its cwd, each argument on its own line and EVALS_DIR;
# exits $STUB_EXIT and prints a failure line when it is not 0. $STUB_MKRUN
# makes it create its run directory under EVALS_DIR/runs, when none exists.
cat > "$H/run.sh" <<'STUB'
#!/usr/bin/env bash
{ echo "cwd=$(pwd -P)"; printf 'arg=%s\n' "$@"; echo "evals=$EVALS_DIR"; echo "path=$PATH"; echo "home=${HOME-unset}"; } > "$STUB_LOG.runsh"
[ -z "${STUB_MKRUN:-}" ] || [ -e "$EVALS_DIR/runs/$1" ] || mkdir -p "$EVALS_DIR/runs/$1"
echo "run $1 started"
if [ "${STUB_EXIT:-0}" -ne 0 ]; then
  for i in $(seq 1 30); do echo "line $i"; done
  echo "$EVALS_DIR/runs/$1 exists; pick a new run name" >&2
fi
exit "${STUB_EXIT:-0}"
STUB
chmod +x "$H/run.sh"

# Stub freeze.sh: records its cwd, each argument on its own line and EVALS_DIR;
# exits $STUB_EXIT and prints a failure line when it is not 0.
cat > "$H/freeze.sh" <<'STUB'
#!/usr/bin/env bash
{ echo "cwd=$(pwd -P)"; printf 'arg=%s\n' "$@"; echo "evals=$EVALS_DIR"; } > "$STUB_LOG.freezesh"
echo "freeze started"
if [ "${STUB_EXIT:-0}" -ne 0 ]; then
  echo "freeze failed on $1" >&2
fi
exit "${STUB_EXIT:-0}"
STUB
chmod +x "$H/freeze.sh"

# Stub replay.sh: records each argument on its own line, EVALS_DIR and
# REX_SESSION; with $STUB_UNSETTLED it leaves that text in the run dir's
# unsettled.txt (a settle failed); exits $STUB_EXIT and prints a failure line when it is not 0.
cat > "$H/replay.sh" <<'STUB'
#!/usr/bin/env bash
{ printf 'arg=%s\n' "$@"; echo "evals=$EVALS_DIR"; echo "session=${REX_SESSION-unset}"; } > "$STUB_LOG.replaysh"
echo "replay $1 started"
if [ -n "${STUB_UNSETTLED:-}" ]; then
  mkdir -p "$EVALS_DIR/runs/$1"
  printf '%s\n' "$STUB_UNSETTLED" > "$EVALS_DIR/runs/$1/unsettled.txt"
fi
if [ "${STUB_EXIT:-0}" -ne 0 ]; then
  for i in $(seq 1 30); do echo "line $i"; done
  echo "replay failed on $1" >&2
fi
exit "${STUB_EXIT:-0}"
STUB
chmod +x "$H/replay.sh"

# Stub corpus.sh: logs one line to $STUB_LOG (the call, EVALS_DIR and its
# arguments); with $STUB_CORPUS_SAY it prints a clash list on stdout and a
# note on stderr and exits 1. rex-run.sh must never call it.
cat > "$H/corpus.sh" <<'STUB'
#!/usr/bin/env bash
{ line="[corpus.sh]"; for a in "$@"; do line="$line[$a]"; done; echo "$line evals=$EVALS_DIR" >> "$STUB_LOG"; }
[ -z "${STUB_CORPUS_SAY:-}" ] || { echo "clash: answer 1 vs answer 2"; echo "corpus note" >&2; exit 1; }
exit 0
STUB
chmod +x "$H/corpus.sh"

# Stub rex. It logs each argument in brackets, one call per line.
# `window new` (the tab; plain `run` is not a stub case): without --shell=none it joins the words and has
# `sh -c` read them, as rex's login shell would; it runs the command after
# -- in -c's directory, keeps the output for `capture` and the status for
# `wait` (it has run to its end before `wait` is asked, as a run.sh that
# fails at once has), and writes the creation result as JSON. $STUB_RUN_FAIL makes it
# fail before creating anything. `wait <block>` exits with that status.
# `wait` also records what $TMPDIR holds when it is asked. `window close` is only logged. $STUB_NO_WINDOW makes the creation result
# lack window_id (block_ids stay).
cat > "$T/bin/rex" <<'STUB'
#!/usr/bin/env bash
line=
for a in "$@"; do line="$line[$a]"; done
echo "$line" >> "$STUB_LOG"
sub="$1"; shift
case "$sub" in
  window)
    [ "$1" != close ] || exit 0
    [ "$1" = new ] || { echo "stub: only window new and close" >&2; exit 1; }
    shift
    [ -z "${STUB_RUN_FAIL:-}" ] || { echo "dial: connect: operation not permitted" >&2; exit 1; }
    cwd=.; direct=
    while [ $# -gt 0 ] && [ "$1" != -- ]; do
      [ "$1" != -c ] || cwd="$2"
      [ "$1" != --shell=none ] || direct=1
      [ "$1" != --wait ] || { echo "stub: --wait is not allowed" >&2; exit 1; }
      shift
    done
    shift
    if [ -n "${STUB_NO_WINDOW:-}" ]; then
      printf '{\n  "block_ids": [\n    "blk-7"\n  ],\n  "revision": 12\n}\n'
    else
      printf '{\n  "window_id": "win-7",\n  "block_ids": [\n    "blk-7"\n  ],\n  "revision": 12\n}\n'
    fi
    if [ -n "$direct" ]; then
      # Directly started: no login shell, so only a minimal environment.
      (cd "$cwd" && env -i PATH=/usr/bin:/bin STUB_LOG="$STUB_LOG" STUB_EXIT="${STUB_EXIT:-0}" STUB_MKRUN="${STUB_MKRUN:-}" STUB_UNSETTLED="${STUB_UNSETTLED:-}" "$@") > "$STUB_LOG.tab" 2>&1
    else
      (cd "$cwd" && sh -c "$*") > "$STUB_LOG.tab" 2>&1
    fi
    echo $? > "$STUB_LOG.status"
    ;;
  wait) ls -A "$TMPDIR" > "$STUB_LOG.tmpwait"; exit "$(cat "$STUB_LOG.status")" ;;
  capture) cat "$STUB_LOG.tab" ;;
esac
STUB
chmod +x "$T/bin/rex"

# run <rex-run.sh args...>; stdout to $T/out, stderr to $T/err. HOME is the
# temp dir, so the real ~/workspace is never touched. $EH, when set, is
# BJORNSTACK_EVALS_HOME. A caller's EVALS_DIR is set to a decoy: it must not matter.
run() {
  : > "$T/stub.log"; rm -f "$T/stub.log.runsh" "$T/stub.log.freezesh" "$T/stub.log.replaysh" "$T/stub.log.tab" "$T/stub.log.status" "$T/stub.log.tmpwait"
  rm -rf "$T/tmpd"; mkdir "$T/tmpd"   # rex-run.sh's TMPDIR: it and the stubs write nothing here
  env -u BJORNSTACK_EVALS_HOME ${EH:+BJORNSTACK_EVALS_HOME="$EH"} \
    PATH="$T/bin:$PATH" STUB_LOG="$T/stub.log" REX_SESSION=sess-1 TMPDIR="$T/tmpd" \
    HOME="$T/home" EVALS_DIR="$T/decoy" "$H/rex-run.sh" "$@" > "$T/out" 2> "$T/err"
}

# files: the eval home's file list, for comparing before and after a run.
files() { (cd "$EV" && find . | sort | tr '\n' ' '); }
# calls: the order of the rex calls that open, wait for, read and close the tab.
calls() {
  sed -n -e 's/^\[window\]\[new\].*/new/p' -e 's/^\[wait\].*/wait/p' \
    -e 's/^\[capture\].*/capture/p' -e 's/^\[window\]\[close\].*/close/p' "$T/stub.log" | tr '\n' ' ' | sed 's/ $//'
}

check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then echo "ok   $1"; else
    echo "FAIL $1"; echo "  expected: $2"; echo "  actual:   $3"; FAILED=1
  fi
}

# Scenario: an agent starts a run in a new rex tab and gets its result.
run r1 --prompt "$SD/my prompt.txt" --owner-away
check "successful run exits 0" "0" "$?"
check "prints the run directory under the default eval home's runs/" "$EV/runs/r1" "$(cat "$T/out")"
check "opens a tab named bjornstack-evals in REX_SESSION, direct, in the eval home with EVALS_DIR set to it" \
  "[window][new][bjornstack-evals][--keep-open][--json][--focus=false][--shell=none][-s][sess-1][-c][$EV][--][env][EVALS_DIR=$EV][PATH=$T/bin:$PATH][HOME=$T/home][$H/run.sh][r1][--prompt][$SD/my prompt.txt][--owner-away]" \
  "$(grep '^\[window\]\[new\]' "$T/stub.log")"
check "waits on the new block in REX_SESSION, without a time limit" \
  "[wait][-s][sess-1][blk-7]" "$(grep '^\[wait\]' "$T/stub.log")"
check "run.sh gets exactly the given arguments, one word each, from the eval home" \
  "cwd=$EVP|arg=r1|arg=--prompt|arg=$SD/my prompt.txt|arg=--owner-away|evals=$EV|path=$T/bin:$PATH|home=$T/home" \
  "$(paste -sd'|' "$T/stub.log.runsh")"
check "a successful run prints no tab output" "" "$(cat "$T/err")"
check "a successful run closes the tab once, after the wait" "new wait close" \
  "$(calls | sed 's/ capture//')"
check "a successful run closes window win-7 in REX_SESSION" \
  "[window][close][-s][sess-1][win-7]" "$(grep '^\[window\]\[close\]' "$T/stub.log")"
check "a successful run writes no rex-tab.log and no logs/ directory" "0 no" \
  "$(find "$EV" -name rex-tab.log | wc -l | tr -d ' ') $([ -e "$EV/logs" ] && echo yes || echo no)"

check "a successful run leaves its TMPDIR empty" "" "$(ls -A "$T/tmpd")"
check "a run writes no file of its own, even while it waits" "" "$(cat "$T/stub.log.tmpwait")"

mkdir -p "$EV/runs"   # the stub makes only runs/<name>; runs/ itself is not rex-run.sh's
FILES_BEFORE="$(files)"
STUB_MKRUN=1 run s1
check "a successful run with a run directory exits 0 and prints it" "0 $EV/runs/s1" "$? $(cat "$T/out")"
check "a successful run adds nothing to the eval home but the stub run.sh's run directory" \
  "$FILES_BEFORE" "$(files | sed 's#\./runs/s1 ##')"
check "a successful run with a run directory writes no rex-tab.log in it" "" "$(ls "$EV/runs/s1")"

# The eval home can be moved with BJORNSTACK_EVALS_HOME.
mkdir -p "$T/custom"
EH="$T/custom" run r5
check "BJORNSTACK_EVALS_HOME names the eval home for the run directory" "$T/custom/runs/r5" "$(cat "$T/out")"
check "BJORNSTACK_EVALS_HOME names the tab's directory and EVALS_DIR" \
  "[-c][$T/custom][--][env][EVALS_DIR=$T/custom]" \
  "$(grep '^\[window\]\[new\]' "$T/stub.log" | grep -o '\[-c\]\[[^]]*\]\[--\]\[env\]\[EVALS_DIR=[^]]*\]')"
check "the tab gets the caller's PATH, which a directly started tab would lack" \
  "path=$T/bin:$PATH" "$(grep '^path=' "$T/stub.log.runsh")"

# A missing eval home is named and never created.
EH="$T/nowhere" run r6
check "a missing eval home exits non-zero" "1" "$?"
check "a missing eval home is named, with no rex call" "1 0" \
  "$(grep -c -F "$T/nowhere" "$T/err") $(grep -c . "$T/stub.log")"
check "a missing eval home is not created" "no" "$([ -e "$T/nowhere" ] && echo yes || echo no)"
mv "$EV" "$EV.away"
run r7
check "a missing default eval home exits non-zero and names it" "1 1" \
  "$? $(grep -c -F "$EV" "$T/err")"
check "a missing default eval home is not created" "no" "$([ -e "$EV" ] && echo yes || echo no)"
mv "$EV.away" "$EV"

# Scenario: a failing run is reported as failing.
STUB_EXIT=3 run r2
check "failing run exits with run.sh's status" "3" "$?"
check "failing run prints no run directory" "" "$(cat "$T/out")"
check "failing run prints the tab's last 20 lines" \
  "line 12 line 13 line 14 line 15 line 16 line 17 line 18 line 19 line 20 line 21 line 22 line 23 line 24 line 25 line 26 line 27 line 28 line 29 line 30 $EV/runs/r2 exists; pick a new run name" \
  "$(grep -v '^run ' "$T/err" | head -n 20 | tr '\n' ' ' | sed 's/ $//')"

check "a failing run leaves its TMPDIR empty, and wrote nothing while it waited" "|" \
  "$(ls -A "$T/tmpd")|$(cat "$T/stub.log.tmpwait")"
check "a failing run closes the tab once, after the capture" "new wait capture close" "$(calls)"
check "a failing run closes window win-7 in REX_SESSION" \
  "[window][close][-s][sess-1][win-7]" "$(grep '^\[window\]\[close\]' "$T/stub.log")"
check "a failing run writes no rex-tab.log and no logs/ directory" "0 no" \
  "$(find "$EV" -name rex-tab.log | wc -l | tr -d ' ') $([ -e "$EV/logs" ] && echo yes || echo no)"

FILES_BEFORE="$(files)"
STUB_EXIT=3 run f2
check "a failing run leaves the eval home's file list as it was" "$FILES_BEFORE" "$(files)"

STUB_MKRUN=1 STUB_EXIT=3 run f1
check "a failing run with a run directory exits with run.sh's status" "3" "$?"
check "a failing run with a run directory writes no rex-tab.log in it" "" "$(ls "$EV/runs/f1")"
check "a failing run with a run directory closes the tab once, after the capture" \
  "new wait capture close" "$(calls)"

# A re-run of an existing name leaves the old run directory as it was.
mkdir -p "$EV/runs/old1"; echo kept > "$EV/runs/old1/result.txt"
STUB_MKRUN=1 STUB_EXIT=3 run old1
check "a re-run of an existing run name exits with run.sh's status" "3" "$?"
check "a re-run of an existing run name writes nothing into the old run directory" \
  "result.txt" "$(ls "$EV/runs/old1")"

check "reads the tab's output from the new block" \
  "[capture][-s][sess-1][-b][blk-7][--trim]" "$(grep '^\[capture\]' "$T/stub.log")"
check "run.sh's own failure is named as such" "1" "$(grep -c '^run.sh exited 3' "$T/err")"

check "the tab gets the caller's HOME, which claude needs to find the normal config" \
  "home=$T/home" "$(grep '^home=' "$T/stub.log.runsh")"

# A creation result without window_id: nothing can be closed, and no close
# call may carry an empty target (rex matches ids by suffix).
STUB_NO_WINDOW=1 STUB_MKRUN=1 run n1
check "a successful run without window_id exits 0 and prints the run directory" "0 $EV/runs/n1" "$? $(cat "$T/out")"
check "a successful run without window_id makes no close call" "new wait" "$(calls)"
check "a successful run without window_id says on stderr it could not close the tab bjornstack-evals" "1" \
  "$(grep -c 'could not close the tab bjornstack-evals' "$T/err")"
STUB_NO_WINDOW=1 STUB_EXIT=3 run n2
check "a failing run without window_id exits with run.sh's status" "3" "$?"
check "a failing run without window_id makes no close call" "new wait capture" "$(calls)"

# A status of 1 is ambiguous (rex wait also returns 1 when it cannot tell), and says so.
STUB_EXIT=1 run r8
check "an exit status of 1 says it may be rex's" "1 1" \
  "$? $(grep -c 'run.sh exited 1 (or rex could not tell' "$T/err")"
check "an exit status of 1 prints the tab's last lines and closes the tab once, after the capture" \
  "line 30 new wait capture close" "$(grep '^line 30$' "$T/err") $(calls)"

# A prompt path holding a space and a ';' reaches run.sh as one word and runs nothing.
run r3 --prompt "$SD/a b; touch pwned"
check "a ';' in an argument runs no second command" "no" "$([ -e "$EV/pwned" ] && echo yes || echo no)"
check "that argument arrives as one word" "arg=$SD/a b; touch pwned" "$(sed -n 4p "$T/stub.log.runsh")"

# run.sh's options are checked before rex is called: --arm a plain name, --prompt
# and --stand-in files that resolve under the repo's evals/story-definition/.
refuse_option() { # refuse_option <description> <run.sh args...>
  local d="$1"; shift
  run refopt "$@"
  check "$d is refused with exit 2 and no rex call" "2 0" "$? $(grep -c . "$T/stub.log")"
}
mkdir -p "$T/outside-dir" "$T/repo/evals/other"
echo "outside" > "$T/outside.txt"
echo "outside" > "$T/outside-dir/p.txt"
echo "outside" > "$T/repo/evals/other/p.txt"
echo "outside" > "$T/repo/README.txt"
ln -s "$T/outside-dir" "$SD/linked"
for bad in "../evil" "a/b" "/abs" "-x" "a b" "a;b"; do
  refuse_option "--arm '$bad'" --arm "$bad"
done
for outside in "$T/outside.txt" "$T/repo/README.txt" "$T/repo/evals/other/p.txt" "$SD/../other/p.txt" "$SD/linked/p.txt"; do
  refuse_option "--prompt $outside" --prompt "$outside"
  refuse_option "--stand-in $outside" --prompt "$SD/my prompt.txt" --stand-in "$outside"
done
echo "a prompt" > "$SD/hard source.txt"
ln "$SD/hard source.txt" "$SD/hard prompt.txt"
refuse_option "--prompt with a hard-linked file" --prompt "$SD/hard prompt.txt"
refuse_option "--stand-in with a hard-linked file" --prompt "$SD/my standin.txt" --stand-in "$SD/hard prompt.txt"
run refopt --arm plain-name_1.x --prompt "$SD/my prompt.txt" --stand-in "$SD/my standin.txt"
check "a plain --arm name and --prompt and --stand-in files under evals/story-definition/ pass to run.sh" "0 yes" \
  "$? $([ -e "$T/stub.log.runsh" ] && echo yes || echo no)"
mkdir -p "$SD/prompts/nested"
echo "nested" > "$SD/prompts/nested/p.txt"
run refopt --prompt "$SD/prompts/nested/p.txt"
check "a --prompt file in a subdirectory of evals/story-definition/ passes to run.sh" "0" "$?"

# rex itself failing is not reported as a run.sh failure.
STUB_RUN_FAIL=1 run r4
check "a rex failure exits non-zero" "1" "$?"
check "a rex failure is named as rex's, with no run.sh claim" "1 0" \
  "$(grep -c '^rex window new failed' "$T/err") $(grep -c 'run.sh exited' "$T/err")"
check "a rex failure prints no run directory" "" "$(cat "$T/out")"

# rex-run.sh runs nothing but run.sh: anything else as the first word is refused.
for refused in "/bin/ls" "../run.sh" "--arm" "a;b" "a b" ""; do
  run "$refused" extra
  check "refuses '$refused' with exit 2 and no rex call" "2 0" \
    "$? $(grep -c . "$T/stub.log")"
done
run
check "refuses no arguments with exit 2" "2" "$?"
run "/bin/ls" extra
check "a refused first word says rex-run.sh runs only run.sh, freeze.sh and replay.sh" "1" \
  "$(grep -c '^refused: rex-run.sh runs only run.sh, freeze.sh and replay.sh' "$T/err")"
check "the header comment of rex-run.sh names run.sh, freeze.sh and replay.sh" "yes" \
  "$(sed -n 2,3p "$HERE/rex-run.sh" | grep -q 'run.sh, freeze.sh and replay.sh' && echo yes || echo no)"

# Scenario: --freeze starts the freeze, and nothing but the freeze.
HP="$(cd "$H" && pwd -P)"
run --freeze "$COMMIT"
check "--freeze with a commit exits 0 and prints the full commit id" "0 $COMMIT" "$? $(cat "$T/out")"
check "--freeze opens the bjornstack-evals tab, direct, in the harness directory, running freeze.sh with the commit id" \
  "[window][new][bjornstack-evals][--keep-open][--json][--focus=false][--shell=none][-s][sess-1][-c][$H][--][env][EVALS_DIR=$EV][PATH=$T/bin:$PATH][HOME=$T/home][$H/freeze.sh][$COMMIT]" \
  "$(grep '^\[window\]\[new\]' "$T/stub.log")"
check "freeze.sh gets the full commit id as its only argument, and EVALS_DIR set to the eval home" \
  "cwd=$HP|arg=$COMMIT|evals=$EV" "$(paste -sd'|' "$T/stub.log.freezesh")"
check "--freeze waits, then closes the tab once" "new wait close" "$(calls)"

run --freeze "$(git -C "$T/repo" rev-parse --short HEAD)"
check "--freeze resolves a short id to the full commit id" "0 $COMMIT|arg=$COMMIT" \
  "$? $(cat "$T/out")|$(grep '^arg=' "$T/stub.log.freezesh")"

STUB_EXIT=3 run --freeze "$COMMIT"
check "a failing freeze exits with freeze.sh's status" "3" "$?"
check "a failing freeze prints no commit id, the tab's output and closes the tab once, after the capture" \
  "|1|new wait capture close" \
  "$(cat "$T/out")|$(grep -c 'freeze failed on' "$T/err")|$(calls)"
check "a failing freeze names freeze.sh, not run.sh" "1 0" \
  "$(grep -c '^freeze.sh exited 3' "$T/err") $(grep -c 'run.sh exited' "$T/err")"
STUB_EXIT=1 run --freeze "$COMMIT"
check "a freeze status of 1 says it may be rex's, naming freeze.sh" "1 1" \
  "$? $(grep -c 'freeze.sh exited 1 (or rex could not tell' "$T/err")"

# Only a commit of the repo holding rex-run.sh is frozen: anything else is refused before rex.
refuse_freeze() { # refuse_freeze <description> <freeze args...>
  local d="$1"; shift
  run --freeze "$@"
  check "--freeze $d exits 2 with the freeze usage on stderr and no rex call" "2 1 0" \
    "$? $(grep -c -- 'usage: rex-run.sh --freeze <commit>' "$T/err") $(grep -c . "$T/stub.log")"
}
refuse_freeze "with no argument"
refuse_freeze "with two arguments" "$COMMIT" "$COMMIT"
refuse_freeze "with an unresolvable argument" deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
refuse_freeze "with an argument starting with '-'" -x
refuse_freeze "with a tree name" "HEAD^{tree}"
refuse_freeze "with a blob name" "HEAD:file.txt"

# Scenario: --replay starts a supervised replay of a recorded transcript in a tab.
# Fixtures: the first user record, an isMeta caveat, an assistant record, a
# turn end, the owner's answer, and the /exit records (which are not owner messages).
# Records chain by parentUuid as in a real transcript; only records on the chain
# from the last record to the root count, so an abandoned sibling does not.
FX="$T/home/.claude/projects/fx"   # a transcript rex-run.sh accepts: under ~/.claude/projects/
mkdir -p "$FX"
FIRST='{"type":"user","uuid":"u1","parentUuid":null,"message":{"role":"user","content":"<command-message>x:y</command-message>\n<command-name>/x:y</command-name>\n<command-args>spec</command-args>"}}'
CAVEAT='{"type":"user","uuid":"u2","parentUuid":"u1","isMeta":true,"message":{"role":"user","content":"<local-command-caveat>Caveat: ignore</local-command-caveat>"}}'
ASSISTANT='{"type":"assistant","uuid":"a1","parentUuid":"u2","message":{"role":"assistant","content":[{"type":"text","text":"question?"}]}}'
TURN='{"type":"system","uuid":"s1","parentUuid":"a1","subtype":"turn_duration","durationMs":5}'
ANSWER='{"type":"user","uuid":"u3","parentUuid":"s1","message":{"role":"user","content":"answer"}}'
EXITREC='{"type":"user","uuid":"u4","parentUuid":"u3","message":{"role":"user","content":"<command-name>/exit</command-name>\n<command-message>exit</command-message>\n<command-args></command-args>"}}'
printf '%s\n' "$FIRST" "$CAVEAT" "$ASSISTANT" "$TURN" "$ANSWER" "$EXITREC" > "$FX/11111111-2222-4333-8444-555555555555.jsonl"
printf '%s\n' "$FIRST" "$CAVEAT" "$ASSISTANT" "$TURN" "$EXITREC" > "$FX/no-owner.jsonl"
# The only owner message is an abandoned sibling: the chain from the last record runs past it.
DRAFT='{"type":"user","uuid":"d1","parentUuid":"s1","message":{"role":"user","content":"an abandoned draft"}}'
EXIT_AFTER_TURN="${EXITREC/\"parentUuid\":\"u3\"/\"parentUuid\":\"s1\"}"
printf '%s\n' "$FIRST" "$CAVEAT" "$ASSISTANT" "$TURN" "$DRAFT" "$EXIT_AFTER_TURN" > "$FX/abandoned-owner.jsonl"
# Compacted: a compact_boundary has parentUuid null and the record before the
# compaction as logicalParentUuid; an isCompactSummary user record (string
# content) follows it.
BOUNDARY='{"type":"system","subtype":"compact_boundary","uuid":"cb1","parentUuid":null,"logicalParentUuid":"LOGICAL"}'
SUMMARYREC='{"type":"user","isCompactSummary":true,"uuid":"cs1","parentUuid":"cb1","message":{"role":"user","content":"This session is being continued. Summary of what was said."}}'
AFTER_ASSISTANT='{"type":"assistant","uuid":"a2","parentUuid":"cs1","message":{"role":"assistant","content":[{"type":"text","text":"next question?"}]}}'
AFTER_EXIT='{"type":"user","uuid":"u9","parentUuid":"a2","message":{"role":"user","content":"<command-name>/exit</command-name>\n<command-message>exit</command-message>\n<command-args></command-args>"}}'
# The only owner message sits before the boundary.
printf '%s\n' "$FIRST" "$CAVEAT" "$ASSISTANT" "$TURN" "$ANSWER" "${BOUNDARY/LOGICAL/u3}" "$SUMMARYREC" "$AFTER_ASSISTANT" "$AFTER_EXIT" > "$FX/22222222-3333-4444-8555-666666666666.jsonl"
# The only string user record after the boundary is the summary.
printf '%s\n' "$FIRST" "$CAVEAT" "$ASSISTANT" "$TURN" "${BOUNDARY/LOGICAL/s1}" "$SUMMARYREC" "$AFTER_ASSISTANT" "$AFTER_EXIT" > "$FX/compacted-summary-only.jsonl"
GOOD="$FX/11111111-2222-4333-8444-555555555555.jsonl"
REPLAY_USAGE="usage: rex-run.sh --replay <run-name> <transcript>"
# abspath <path>: the physical form of an absolute path, or the path itself when it is relative.
abspath() { case "$1" in /*) echo "$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")" ;; *) echo "$1" ;; esac; }

run --replay rp1 "$GOOD"
check "--replay with a good transcript exits 0 and prints the run directory under runs/" "0 $EV/runs/rp1" "$? $(cat "$T/out")"
check "--replay opens a run.sh-like tab running replay.sh with the run name and the transcript, REX_SESSION in its env" \
  "[window][new][bjornstack-evals][--keep-open][--json][--focus=false][--shell=none][-s][sess-1][-c][$EV][--][env][EVALS_DIR=$EV][PATH=$T/bin:$PATH][HOME=$T/home][REX_SESSION=sess-1][$H/replay.sh][rp1][$GOOD]" \
  "$(grep '^\[window\]\[new\]' "$T/stub.log")"
check "--replay waits on the new block in REX_SESSION, without a time limit" \
  "[wait][-s][sess-1][blk-7]" "$(grep '^\[wait\]' "$T/stub.log")"
check "replay.sh gets the run name and the transcript, EVALS_DIR and REX_SESSION" \
  "arg=rp1|arg=$GOOD|evals=$EV|session=sess-1" "$(paste -sd'|' "$T/stub.log.replaysh")"
check "--replay waits, then closes the tab once" "new wait close" "$(calls)"
check "a successful --replay prints no tab output" "" "$(cat "$T/err")"

(cd "$FX" && run --replay rp2 11111111-2222-4333-8444-555555555555.jsonl)
check "--replay turns a relative transcript path into an absolute one" "$(abspath "$GOOD")" \
  "$(abspath "$(sed -n 's/^arg=//;2p' "$T/stub.log.replaysh")")"

run --replay rpc "$FX/22222222-3333-4444-8555-666666666666.jsonl"
check "--replay accepts a compacted transcript whose only owner message sits before the boundary" "0 $EV/runs/rpc" "$? $(cat "$T/out")"

STUB_UNSETTLED="unsettled: id-7 id-9" run --replay rpu "$GOOD"
check "a replay with an unsettled.txt prints the run directory, then the file's content, and exits 0" \
  "0 $EV/runs/rpu|unsettled: id-7 id-9" "$? $(paste -sd'|' "$T/out")"

run --replay rpn "$GOOD"
check "a replay without an unsettled.txt prints the run directory only" "$EV/runs/rpn" "$(cat "$T/out")"

STUB_EXIT=3 run --replay rp3 "$GOOD"
check "a failing replay exits with replay.sh's status" "3" "$?"
check "a failing replay prints no run directory" "" "$(cat "$T/out")"
check "a failing replay prints the tab's last 20 lines, then the status message naming replay.sh" \
  "line 12 line 13 line 14 line 15 line 16 line 17 line 18 line 19 line 20 line 21 line 22 line 23 line 24 line 25 line 26 line 27 line 28 line 29 line 30 replay failed on rp3 replay.sh exited 3" \
  "$(grep -v '^replay rp3 started' "$T/err" | tr '\n' ' ' | sed 's/ $//')"
check "a failing replay closes the tab once, after the capture" "new wait capture close" "$(calls)"

# Refusals: exit 2, the replay usage line and the refusal's own problem text on stderr, and no rex call.
refuse_replay() { # refuse_replay <description> <problem text> <--replay args...>
  local d="$1" problem="$2"; shift 2
  run --replay "$@"
  check "--replay $d exits 2 with the replay usage and '$problem' on stderr and no rex call" "2 1 1 0" \
    "$? $(grep -c -F -- "$REPLAY_USAGE" "$T/err") $(grep -c -F -- "$problem" "$T/err") $(grep -c . "$T/stub.log")"
}
refuse_replay "with no arguments" "--replay takes a run name and a transcript"
refuse_replay "with a run name and no transcript" "--replay takes a run name and a transcript" rp4
refuse_replay "with a transcript that does not exist" "is not a readable file" rp4 "$FX/missing.jsonl"
refuse_replay "with a transcript that is a directory" "is not a readable file" rp4 "$FX"
refuse_replay "with a transcript holding no owner message" "holds no owner message" rp4 "$FX/no-owner.jsonl"
refuse_replay "with a transcript whose only owner message is an abandoned sibling" "holds no owner message" rp4 "$FX/abandoned-owner.jsonl"
for bad in "" "-x" "a/b" "a b" "a;b"; do
  refuse_replay "with the run name '$bad'" "run name '$bad' is not a plain name" "$bad" "$GOOD"
done
mkdir -p "$EV/runs/taken1"
refuse_replay "with a compacted transcript whose only string user record after the boundary is the summary" "holds no owner message" rp4 "$FX/compacted-summary-only.jsonl"
refuse_replay "with a run name that exists under runs/" "run name 'taken1' already exists" taken1 "$GOOD"
mkdir -p "$EV/live/taken2"
refuse_replay "with a run name that exists under live/" "run name 'taken2' already exists" taken2 "$GOOD"
rmdir "$EV/runs/taken1" "$EV/live/taken2"
run --replay rp4 "$FX/no-owner.jsonl"
check "a refusal for a transcript with no owner message says so" "1" "$(grep -c 'owner message' "$T/err")"

# Only transcripts under <eval home>/runs/ or ~/.claude/projects/ are replayed.
mkdir -p "$EV/runs/src-run" "$T/elsewhere" "$EV/live/src-live"
cp "$GOOD" "$EV/runs/src-run/transcript.jsonl"
cp "$GOOD" "$T/elsewhere/good.jsonl"
cp "$GOOD" "$EV/live/src-live/good.jsonl"
cp "$GOOD" "$T/home/.claude/elsewhere-good.jsonl"
ln -s "$T/elsewhere" "$FX/linkdir"
# Only the two exact shapes: <eval home>/runs/<name>/transcript.jsonl and
# ~/.claude/projects/<slug>/<uuid>.jsonl, each at exactly that depth.
mkdir -p "$EV/runs/x/workdir" "$T/home/.claude/projects/a/b"
cp "$GOOD" "$EV/runs/x/workdir/t.jsonl"
cp "$GOOD" "$EV/runs/x/other.jsonl"
cp "$GOOD" "$EV/runs/transcript.jsonl"
cp "$GOOD" "$T/home/.claude/projects/x.jsonl"
cp "$GOOD" "$T/home/.claude/projects/a/b/c.jsonl"
cp "$GOOD" "$FX/notauuid.jsonl"
run --replay rp6 "$EV/runs/src-run/transcript.jsonl"
check "--replay accepts <eval home>/runs/<name>/transcript.jsonl" "0 $EV/runs/rp6" "$? $(cat "$T/out")"
run --replay rp8 "$GOOD"
check "--replay accepts ~/.claude/projects/<slug>/<uuid>.jsonl" "0 $EV/runs/rp8" "$? $(cat "$T/out")"
refuse_replay "with a transcript outside the eval home and ~/.claude/projects/" "refused:" rp7 "$T/elsewhere/good.jsonl"
refuse_replay "with a transcript nested below runs/<name>/ (runs/x/workdir/t.jsonl)" "refused:" rp7 "$EV/runs/x/workdir/t.jsonl"
refuse_replay "with runs/<name>/other.jsonl" "refused:" rp7 "$EV/runs/x/other.jsonl"
refuse_replay "with runs/transcript.jsonl" "refused:" rp7 "$EV/runs/transcript.jsonl"
refuse_replay "with projects/x.jsonl" "refused:" rp7 "$T/home/.claude/projects/x.jsonl"
refuse_replay "with projects/a/b/c.jsonl" "refused:" rp7 "$T/home/.claude/projects/a/b/c.jsonl"
refuse_replay "with projects/<slug>/notauuid.jsonl" "refused:" rp7 "$FX/notauuid.jsonl"
refuse_replay "with a transcript under <eval home>/live/" "refused:" rp7 "$EV/live/src-live/good.jsonl"
refuse_replay "with a transcript that leaves ~/.claude/projects/ through .." "refused:" rp7 "$T/home/.claude/projects/../elsewhere-good.jsonl"
refuse_replay "with a transcript that leaves ~/.claude/projects/ through a symlinked directory" "refused:" rp7 "$FX/linkdir/good.jsonl"

EH="$T/nowhere" run --replay rp5 "$GOOD"
check "--replay with a missing eval home exits 1, names it and makes no rex call" "1 1 0" \
  "$? $(grep -c -F "$T/nowhere" "$T/err") $(grep -c . "$T/stub.log")"

# The README says what --replay is and is not.
README="$HERE/README.md"
check "the README documents --replay" "yes" "$(grep -q -e '--replay' "$README" && echo yes || echo no)"
check "the README says --replay is a supervised replay for fix rounds" "yes" \
  "$(grep -i 'supervised replay' "$README" | grep -qi 'fix round' && echo yes || echo no)"
check "the README says --replay is not a live run" "yes" "$(grep -qi 'not a live run' "$README" && echo yes || echo no)"
check "the README says the owner's final check before the epic is done is a live run" "yes" \
  "$(grep -i 'final check' "$README" | grep -qi 'live run' && echo yes || echo no)"

check "the README says where the plugin sits in a replay: .bjornstack in the session's working directory" "yes" \
  "$(grep -q -e '\.bjornstack' "$README" && echo yes || echo no)"
check "the README says a replay loads the plugin from live/<run-name>/.bjornstack" "yes" \
  "$(grep -i 'replay loads the plugin' "$README" | grep -q -e 'live/<run-name>/\.bjornstack' && echo yes || echo no)"
check "the README does not mention replay-notes.txt" "no" "$(grep -q -e 'replay-notes.txt' "$README" && echo yes || echo no)"

# The README states the owner-message rule and the rewind rule.
for term in isMeta local-command queued_command isCompactSummary; do
  check "the README's owner-message rule names $term" "yes" "$(grep -q -e "$term" "$README" && echo yes || echo no)"
done
check "the README says a rewound branch is skipped, following the parent chain" "yes" \
  "$(grep -q -e 'parentUuid' -e 'parent chain' "$README" && echo yes || echo no)"
check "the README's chain rule names logicalParentUuid for a compaction boundary" "yes" \
  "$(grep -q -e 'logicalParentUuid' "$README" && echo yes || echo no)"

# The README states the matching rule, the pre-fill, the display on a pull-in
# and the letter labels.
check "the README says a segment matches only if, read against the turn alone, it means what it meant against its recorded turn" "yes" \
  "$(grep -qi 'read against the turn alone' "$README" && echo yes || echo no)"
check "the README says a yes or praise matches only the same proposal" "yes" \
  "$(grep -i 'praise' "$README" | grep -qi 'same proposal' && echo yes || echo no)"
check "the README says a turn some questions of which are covered is pre-filled" "yes" "$(grep -qi 'pre-fill' "$README" && echo yes || echo no)"
check "the README says the pre-fill holds an empty marker for each uncovered question" "yes" "$(grep -qi 'empty marker' "$README" && echo yes || echo no)"
check "the README says the pre-fill is not sent: no enter" "yes" "$(grep -i 'pre-fill' "$README" | grep -qi 'no enter' && echo yes || echo no)"
check "the README says the pre-fill's labels follow the turn's numbers or letters" "yes" \
  "$(grep -i 'pre-fill' "$README" | grep -qi 'numbers or letters' && echo yes || echo no)"
check "the README says the pre-fill is unlabelled paragraphs when the labelling is mixed or absent" "yes" \
  "$(grep -qi 'unlabelled paragraphs' "$README" && echo yes || echo no)"
check "the README says pre-filled segments are not counted as replayed and the owner's message is recorded as the owner's" "yes" \
  "$(grep -qi 'not counted as replayed' "$README" && echo yes || echo no)"
check "the README says a pull-in shows the recorded turn it answered for each matched and refused segment" "yes" \
  "$(grep -qi 'recorded turn it answered' "$README" && grep -qi 'refused near-match' "$README" && echo yes || echo no)"
check "the README says the display goes to the driver tab only" "yes" "$(grep -qi 'driver tab' "$README" && echo yes || echo no)"
check "the README names the refused field of the matcher's answer" "yes" "$(grep -qF '"refused"' "$README" && echo yes || echo no)"
check "the README says only a numeric label is a label and a word or letter before a colon stays in the text" "yes" \
  "$(grep -qi 'only a numeric label' "$README" && grep -qi 'a word or letter before a colon' "$README" && echo yes || echo no)"
check "the README says a pre-filled segment is marked used" "yes" \
  "$(grep -i 'pre-fill' "$README" | grep -qiE 'marked used|(are|become) used' && echo yes || echo no)"
check "the README no longer says pre-filled segments stay unused" "no" \
  "$(grep -i 'pre-fill' "$README" | grep -qi 'stay unused' && echo yes || echo no)"
check "the README no longer says a bad label on a fully covered turn pulls the owner in without a pre-fill" "no" \
  "$(grep -qi 'or with a bad label, pull the owner in' "$README" && echo yes || echo no)"

# The README states how clashes are met: no scan, the later answer of a run
# stands, and the owner settles after the run.
check "the README says the later answer of one run stands" "yes" \
  "$(grep -qi 'later answer' "$README" && grep -i 'later answer' "$README" | grep -qi 'one run' && echo yes || echo no)"
check "the README says the owner's answer stands over the shown answers" "yes" \
  "$(tr '\n' ' ' < "$README" | tr -s ' ' | grep -qi "owner's answer stands over the shown answers" && echo yes || echo no)"
check "the README says that rule is for a turn that asked one question" "yes" \
  "$(grep -i 'a turn that asked one question' "$README" | grep -qi "owner's answer stands" && echo yes || echo no)"
check "the README says the clash ids are dropped at exit with corpus.sh settle --drop" "yes" \
  "$(grep -q -e 'corpus.sh settle <run> --drop' "$README" && echo yes || echo no)"
check "the README leaves a several-question turn for corpus.sh settle" "yes" \
  "$(tr '\n' ' ' < "$README" | tr -s ' ' | grep -io 'a turn that asked several questions.*' | grep -q 'corpus.sh settle' && echo yes || echo no)"
check "the README says the owner settles after the run with corpus.sh settle" "yes" \
  "$(grep -i 'after the run' "$README" | grep -q 'corpus.sh settle' && echo yes || echo no)"
check "the README says corpus.sh clashes lists what to settle" "yes" \
  "$(grep -i 'to settle' "$README" | grep -q 'corpus.sh clashes' && echo yes || echo no)"

# Scenario: no corpus scan runs around an eval. The stub clashes and exits 1;
# nothing of it may show, and nothing is refused.
corpus_calls() { grep -c '^\[corpus\.sh\]' "$T/stub.log"; }

STUB_CORPUS_SAY=1 run --replay nc1 "$GOOD"
STATUS=$?
check "a replay starts although a clashing corpus.sh is present: the tab opens, waits and closes, the run directory is printed, exit 0" \
  "0 $EV/runs/nc1 new wait close" "$STATUS $(cat "$T/out") $(calls | sed 's/ capture//')"
check "a replay calls no corpus.sh: the stub log holds no corpus.sh line" "0" "$(corpus_calls)"
check "a replay's stderr carries nothing from corpus.sh" "" "$(grep -e 'clash' -e 'corpus' "$T/err")"

STUB_CORPUS_SAY=1 run nc2
STATUS=$?
check "a run calls no corpus.sh, exits 0 and prints the run directory only" "0 0 $EV/runs/nc2" "$STATUS $(corpus_calls) $(cat "$T/out")"
check "a run's stderr carries nothing from corpus.sh" "" "$(grep -e 'clash' -e 'corpus' "$T/err")"

STUB_CORPUS_SAY=1 run nc3 --prompt "$SD/my prompt.txt" --owner-away
check "an owner-away run calls no corpus.sh" "0" "$(corpus_calls)"
STUB_CORPUS_SAY=1 run nc3b --prompt "$SD/my prompt.txt" --owner-away
check "an owner-away run's stdout is the run directory and its stderr holds nothing from corpus.sh" "$EV/runs/nc3b|" \
  "$(cat "$T/out")|$(grep -e 'clash' -e 'corpus' "$T/err")"

STUB_EXIT=3 STUB_CORPUS_SAY=1 run nc4
STATUS=$?
check "a failed run keeps run.sh's exit status, prints no run directory and calls no corpus.sh" "3 [] 0" \
  "$STATUS [$(cat "$T/out")] $(corpus_calls)"
check "a failed run's stderr carries nothing from corpus.sh" "" "$(grep -e 'clash' -e 'corpus' "$T/err")"

STUB_EXIT=3 STUB_CORPUS_SAY=1 run --replay nc5 "$GOOD"
check "a failed replay calls no corpus.sh and its stderr carries nothing from it" "0 " "$(corpus_calls) $(grep -e 'clash' -e 'corpus' "$T/err")"

STUB_CORPUS_SAY=1 run --freeze "$COMMIT"
check "--freeze calls no corpus.sh" "0" "$(corpus_calls)"

check "the header comment of rex-run.sh does not mention the corpus" "0" \
  "$(sed -n '/^set -euo/q;p' "$HERE/rex-run.sh" | grep -ci 'corpus')"

# rex-run.sh shares its input checks: it sources inputs.sh and defines no resolve_file of its own.
check "rex-run.sh sources inputs.sh from its own directory" "1" \
  "$(grep -v '^[[:space:]]*#' "$HERE/rex-run.sh" | grep -cE '^[[:space:]]*(source|\.) +"\$HERE/inputs\.sh"')"
check "rex-run.sh defines no resolve_file of its own" "0" \
  "$(grep -cE '^[[:space:]]*(resolve_file[[:space:]]*\(\)|function +resolve_file)' "$HERE/rex-run.sh")"

# A prompt under a directory that does not exist is refused as not resolving.
run refopt --prompt "$SD/nodir/p.txt"; rc=$?
check "a --prompt under a missing directory exits 2" "2" "$rc"
check "a --prompt under a missing directory is refused as a path that does not resolve" "1" \
  "$(grep -c "^refused: --prompt '$SD/nodir/p.txt' does not resolve" "$T/err")"

exit "$FAILED"
