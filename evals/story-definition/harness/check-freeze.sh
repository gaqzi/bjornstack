#!/usr/bin/env bash
# Black-box checks for freeze.sh, run against a temp git repo with a copy of
# freeze.sh beside the harness path it expects. Real git, no rex, no claude.
# There are no unit-layer cases: freeze.sh holds no rules beyond what git
# archive gives it; what it must leave alone is a black-box case below.
# Usage: check-freeze.sh
set -uo pipefail

# `git rebase --exec` exports GIT_DIR and friends; left set, `git init` in a
# temp dir would re-init the caller's repo. Start from a clean git environment.
unset $(git rev-parse --local-env-vars)

HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/freeze-check.XXXXXX")"
T="$(cd "$T" && pwd)"
trap 'rm -rf "$T"' EXIT
FAILED=0

R="$T/repo"
H="$R/evals/story-definition/harness"
EV="$T/evals"
mkdir -p "$H"
cp "$HERE/freeze.sh" "$H/freeze.sh" 2>/dev/null
git -C "$R" init -q
g() { git -C "$R" -c user.name=t -c user.email=t@example.com "$@"; }

# Commit one: the plugin text to freeze. Commit two changes it, so a freeze
# of commit one that read the working tree or HEAD would show.
mkdir -p "$R/.claude-plugin" "$R/plugin/skills" "$R/strategies" "$R/tenets"
echo "strategy one" > "$R/strategies/s.md"
echo "tenet one" > "$R/tenets/t.md"
ln -s ../strategies "$R/plugin/strategies"
ln -s ../tenets "$R/plugin/tenets"
echo "manifest one" > "$R/.claude-plugin/plugin.json"
echo "skill one" > "$R/plugin/skills/a.md"
echo "not plugin" > "$R/README.md"
g add -A; g commit -q -m one
ONE="$(g rev-parse HEAD)"
echo "skill two" > "$R/plugin/skills/a.md"
echo "new two" > "$R/plugin/new.md"
g add -A; g commit -q -m two

# The eval home: a stale frozen copy, and what freeze must not touch.
mkdir -p "$EV/config/sources/bjornstack/plugin" "$EV/config/sources/gaqzi--private" \
  "$EV/config/bjornstack-arm" "$EV/specs" "$EV/runs/r1"
echo stale > "$EV/config/sources/bjornstack/plugin/stale.md"
echo stale > "$EV/config/sources/bjornstack/old-only.txt"
echo oldcommit > "$EV/config/sources/bjornstack.commit"
echo private > "$EV/config/sources/gaqzi--private/p.md"
echo login > "$EV/config/bjornstack-arm/.claude.json"
echo spec > "$EV/specs/briefkasten.md"
echo out > "$EV/runs/r1/transcript.jsonl"

# frozen: the frozen copy's files and contents, for comparing.
frozen() { (cd "$EV/config/sources/bjornstack" && find . -type f | sort | xargs cat | cksum; find . | sort | tr '\n' ' '); }
# rest: every file in the eval home outside the frozen copy and its commit file.
rest() { (cd "$EV" && find . -not -path './config/sources/bjornstack' -not -path './config/sources/bjornstack/*' \
  -not -name bjornstack.commit | sort | while read -r f; do [ -f "$f" ] && cksum "$f" || echo "$f"; done | tr '\n' ' '); }

check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then echo "ok   $1"; else
    echo "FAIL $1"; echo "  expected: $2"; echo "  actual:   $3"; FAILED=1
  fi
}

REST_BEFORE="$(rest)"
EVALS_DIR="$EV" "$H/freeze.sh" "$(git -C "$R" rev-parse --short "$ONE")" > "$T/out" 2> "$T/err"
check "freezing a commit by a short id exits 0" "0" "$?"
check "the frozen copy holds exactly .claude-plugin, plugin/, strategies/ and tenets/ of that commit" \
  ". ./.claude-plugin ./.claude-plugin/plugin.json ./plugin ./plugin/skills ./plugin/skills/a.md ./plugin/strategies ./plugin/tenets ./strategies ./strategies/s.md ./tenets ./tenets/t.md" \
  "$(cd "$EV/config/sources/bjornstack" && find . | sort | tr '\n' ' ' | sed 's/ $//')"
check "the frozen files are the commit's text, not HEAD's" "manifest one|skill one" \
  "$(cat "$EV/config/sources/bjornstack/.claude-plugin/plugin.json" 2>&1)|$(cat "$EV/config/sources/bjornstack/plugin/skills/a.md" 2>&1)"
check "the rule files read through the plugin's symlinks" "strategy one|tenet one" \
  "$(cat "$EV/config/sources/bjornstack/plugin/strategies/s.md" 2>&1)|$(cat "$EV/config/sources/bjornstack/plugin/tenets/t.md" 2>&1)"
check "the old copy's stale files are gone" "no no" \
  "$([ -e "$EV/config/sources/bjornstack/plugin/stale.md" ] && echo yes || echo no) $([ -e "$EV/config/sources/bjornstack/old-only.txt" ] && echo yes || echo no)"
check "bjornstack.commit holds the full commit id" "$ONE" "$(cat "$EV/config/sources/bjornstack.commit")"
check "nothing else in the eval home changes (sibling source, arm config, specs, runs)" "$REST_BEFORE" "$(rest)"

# A commit that does not resolve leaves the frozen copy and its commit file as they were.
FROZEN_BEFORE="$(frozen)"
EVALS_DIR="$EV" "$H/freeze.sh" deadbeefdeadbeefdeadbeefdeadbeefdeadbeef > "$T/out" 2> "$T/err"
check "an unknown commit exits non-zero" "1" "$([ "$?" -ne 0 ] && echo 1 || echo 0)"
check "an unknown commit leaves the frozen copy intact" "$FROZEN_BEFORE" "$(frozen)"
check "an unknown commit leaves bjornstack.commit as it was" "$ONE" "$(cat "$EV/config/sources/bjornstack.commit")"
check "an unknown commit leaves nothing else changed" "$REST_BEFORE" "$(rest)"

# A symlink that does not resolve inside the copy refuses the freeze.
ln -s ../nowhere "$R/plugin/dangling"
g add -A; g commit -q -m three
THREE="$(g rev-parse HEAD)"
EVALS_DIR="$EV" "$H/freeze.sh" "$THREE" > "$T/out" 2> "$T/err"
check "a commit with a dangling symlink exits non-zero" "1" "$([ "$?" -ne 0 ] && echo 1 || echo 0)"
check "a dangling symlink leaves bjornstack.commit as it was" "$ONE" "$(cat "$EV/config/sources/bjornstack.commit")"

exit "$FAILED"
