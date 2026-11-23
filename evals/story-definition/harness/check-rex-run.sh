#!/usr/bin/env bash
# Black-box checks for rex-run.sh, with a stub rex on PATH and a stub run.sh
# beside a copy of rex-run.sh. No real rex or claude runs. There are no
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
      (cd "$cwd" && env -i PATH=/usr/bin:/bin STUB_LOG="$STUB_LOG" STUB_EXIT="${STUB_EXIT:-0}" STUB_MKRUN="${STUB_MKRUN:-}" "$@") > "$STUB_LOG.tab" 2>&1
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
  : > "$T/stub.log"; rm -f "$T/stub.log.runsh" "$T/stub.log.freezesh" "$T/stub.log.tab" "$T/stub.log.status" "$T/stub.log.tmpwait"
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
run r1 --prompt "$T/my prompt.txt" --owner-away
check "successful run exits 0" "0" "$?"
check "prints the run directory under the default eval home's runs/" "$EV/runs/r1" "$(cat "$T/out")"
check "opens a tab named bjornstack-evals in REX_SESSION, direct, in the eval home with EVALS_DIR set to it" \
  "[window][new][bjornstack-evals][--keep-open][--json][--focus=false][--shell=none][-s][sess-1][-c][$EV][--][env][EVALS_DIR=$EV][PATH=$T/bin:$PATH][HOME=$T/home][$H/run.sh][r1][--prompt][$T/my prompt.txt][--owner-away]" \
  "$(grep '^\[window\]\[new\]' "$T/stub.log")"
check "waits on the new block in REX_SESSION, without a time limit" \
  "[wait][-s][sess-1][blk-7]" "$(grep '^\[wait\]' "$T/stub.log")"
check "run.sh gets exactly the given arguments, one word each, from the eval home" \
  "cwd=$EVP|arg=r1|arg=--prompt|arg=$T/my prompt.txt|arg=--owner-away|evals=$EV|path=$T/bin:$PATH|home=$T/home" \
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
run r3 --prompt "$T/a b; touch $T/pwned"
check "a ';' in an argument runs no second command" "no" "$([ -e "$T/pwned" ] && echo yes || echo no)"
check "that argument arrives as one word" "arg=$T/a b; touch $T/pwned" "$(sed -n 4p "$T/stub.log.runsh")"

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
check "a refused first word says rex-run.sh runs only run.sh and freeze.sh" "1" \
  "$(grep -c '^refused: rex-run.sh runs only run.sh and freeze.sh' "$T/err")"

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

exit "$FAILED"
