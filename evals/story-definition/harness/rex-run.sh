#!/usr/bin/env bash
# Start run.sh in a new rex tab and wait for it. The one way an agent
# session starts a harness run: it runs only run.sh and freeze.sh.
#
# Usage: rex-run.sh <run-name> [run.sh options]   (the arguments of run.sh)
#        rex-run.sh --freeze <commit>
# Opens a tab named bjornstack-evals in the rex session $REX_SESSION, runs run.sh there from the
# eval home with exactly these arguments and EVALS_DIR set to the eval home,
# and waits until it ends.
# The eval home is ~/workspace/bjornstack-evals, or $BJORNSTACK_EVALS_HOME. It
# holds every run's output (the token is in the Keychain); the owner makes it, nothing
# here creates it, and a caller's EVALS_DIR is ignored.
# Prints the run directory (<eval home>/runs/<run-name>) and
# exits with run.sh's exit status. The tab closes when run.sh ends. When
# run.sh fails, rex-run.sh first prints the tab's last 20 lines of output
# and the status message to stderr. Nothing else is saved: this script
# writes no file of its own, and the run directory holds what the run needs.
# If rex names no window, the tab is left open and a message says so.
# --freeze <commit> runs freeze.sh the same way instead, in the harness
# directory, with the full id of a commit of the repo holding this script
# (anything else is refused with exit 2 before rex is called), and prints
# that id when it succeeds. freeze.sh replaces the frozen plugin a --prompt
# run loads; run it before a run of new plugin text.
set -euo pipefail

USAGE="usage: rex-run.sh <run-name> [run.sh options]"
FREEZE_USAGE="usage: rex-run.sh --freeze <commit>"
HERE="$(cd "$(dirname "$0")" && pwd)"
FREEZING=0
if [ "${1:-}" = "--freeze" ]; then
  FREEZING=1
  shift
  # One argument that names a commit of this repo; "-x" or a tree or blob is not one.
  COMMIT=
  if [ $# -eq 1 ]; then
    case "$1" in
      -*) ;;
      *) COMMIT="$(git -C "$HERE" rev-parse --verify --quiet "$1^{commit}")" || COMMIT= ;;
    esac
  fi
  [ -n "$COMMIT" ] || { echo "$FREEZE_USAGE" >&2; echo "refused: --freeze takes one commit of the repo holding rex-run.sh" >&2; exit 2; }
  set -- freeze "$COMMIT"
fi
# The first word is run.sh's run name, never a command or a path.
case "${1:-}" in
  "" | -* | */* | *[!A-Za-z0-9._-]*) echo "$USAGE" >&2; echo "refused: rex-run.sh runs only run.sh and freeze.sh" >&2; exit 2 ;;
esac
: "${REX_SESSION:?REX_SESSION is not set}"

E="${BJORNSTACK_EVALS_HOME:-$HOME/workspace/bjornstack-evals}"
[ -d "$E" ] || { echo "eval home $E does not exist; the owner makes it (see the harness README)" >&2; exit 1; }
NAME="$1"

# The command is fixed. --shell=none starts it directly, so rex joins no
# words for a shell to read; each argument stays one word. EVALS_DIR travels
# with the command, set to the eval home. PATH and HOME travel too: a
# tab started directly has no login shell to supply them, and claude finds the
# normal config through HOME. The tab does not take focus.
RUN_DIR="$E/runs/$NAME"
if [ "$FREEZING" = 1 ]; then
  SCRIPT="$HERE/freeze.sh"; TAB_DIR="$HERE"; shift   # freeze.sh takes the commit id only
else
  SCRIPT="$HERE/run.sh"; TAB_DIR="$E"
fi
if ! CREATED="$(rex window new bjornstack-evals --keep-open --json --focus=false --shell=none -s "$REX_SESSION" -c "$TAB_DIR" -- \
    env "EVALS_DIR=$E" "PATH=$PATH" "HOME=$HOME" "$SCRIPT" "$@")"; then
  echo "rex window new failed; no tab was started" >&2
  exit 1
fi
BLOCK="$(printf '%s' "$CREATED" | jq -r '.block_ids[0] // empty' | head -n 1)"
[ -n "$BLOCK" ] || { echo "rex window new failed; it named no block" >&2; exit 1; }
WINDOW="$(printf '%s' "$CREATED" | jq -r '.window_id // empty' | head -n 1)"

# Wait for run.sh with no time limit: a run takes minutes, and rex wait
# gives the child's exit status even though the tab stays open.
set +e
rex wait -s "$REX_SESSION" "$BLOCK"
STATUS=$?
set -e

if [ "$STATUS" -ne 0 ]; then
  RAN="$(basename "$SCRIPT")"
  rex capture -s "$REX_SESSION" -b "$BLOCK" --trim | tail -n 20 >&2 || true
  if [ "$STATUS" -eq 1 ]; then
    echo "$RAN exited 1 (or rex could not tell: rex wait gives 1 then)" >&2
  else
    echo "$RAN exited $STATUS" >&2
  fi
fi

# rex resolves a target by ID suffix, so an empty target must never reach it.
if [ -z "$WINDOW" ]; then
  echo "could not close the tab bjornstack-evals: rex named no window" >&2
else
  rex window close -s "$REX_SESSION" "$WINDOW" \
    || echo "could not close the tab bjornstack-evals ($WINDOW)" >&2
fi

[ "$STATUS" -eq 0 ] || exit "$STATUS"
if [ "$FREEZING" = 1 ]; then echo "$COMMIT"; else echo "$RUN_DIR"; fi
