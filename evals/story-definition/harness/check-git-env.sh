#!/usr/bin/env bash
# Black-box checks that each check script ignores the git environment it
# inherits. `git rebase --exec` exports GIT_DIR and friends; a check that runs
# `git -C <temp> init` under them re-inits the caller's repo instead. Each row
# runs one check script with that environment pointing at a decoy repo, then
# expects the decoy's config and HEAD untouched and the script still green.
# There are no unit-layer cases: the rule is about the process environment.
# Usage: check-git-env.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/git-env-check.XXXXXX")"
T="$(cd "$T" && pwd)"
trap 'rm -rf "$T"' EXIT
FAILED=0

ok()   { echo "ok   - $1"; }
fail() { echo "FAIL - $1"; FAILED=1; }

CLEAN=(-u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR -u GIT_PREFIX)

# A main repo with one commit and a linked worktree, built with the
# environment cleared. This is the shape `git rebase --exec` runs in.
make_decoy() {
  local d="$1"
  mkdir -p "$d/main"
  env "${CLEAN[@]}" git -C "$d/main" init -q
  echo x > "$d/main/f"
  env "${CLEAN[@]}" git -C "$d/main" add -A
  env "${CLEAN[@]}" git -C "$d/main" -c user.name=t -c user.email=t@example.com commit -q -m one
  env "${CLEAN[@]}" git -C "$d/main" worktree add -q "$d/wt"
}

# The decoy's state as one value: the main repo's core.bare and the
# linked worktree's HEAD commit.
decoy_state() {
  echo "core.bare=$(env "${CLEAN[@]}" git -C "$1/main" config --get core.bare)"
  echo "HEAD=$(env "${CLEAN[@]}" git -C "$1/wt" rev-parse HEAD)"
}

while read -r script; do
  D="$T/decoy-$script"
  make_decoy "$D"
  before="$(decoy_state "$D")"

  out="$(cd "$D/wt" && GIT_DIR="$D/main/.git/worktrees/wt" GIT_PREFIX= \
         bash "$HERE/$script" 2>&1)"
  code=$?
  after="$(decoy_state "$D")"

  if [ "$before" = "$after" ]; then
    ok "$script leaves the inherited repo's core.bare and HEAD alone"
  else
    fail "$script modified the inherited repo's core.bare or HEAD"
  fi
  if [ "$code" -eq 0 ]; then
    ok "$script passes with the git environment inherited"
  else
    fail "$script exited $code with the git environment inherited"
    echo "$out" | sed 's/^/     /' | tail -n 15
  fi
done <<'ROWS'
check.sh
check-rex-run.sh
check-freeze.sh
ROWS

exit "$FAILED"
