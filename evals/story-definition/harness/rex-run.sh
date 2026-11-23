#!/usr/bin/env bash
# Start run.sh in a new rex tab and wait for it. The one way an agent
# session starts a harness run: it runs nothing but run.sh.
#
# Usage: rex-run.sh <run-name> [run.sh options]   (the arguments of run.sh)
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
set -euo pipefail

USAGE="usage: rex-run.sh <run-name> [run.sh options]"
# The first word is run.sh's run name, never a command or a path.
case "${1:-}" in
  "" | -* | */* | *[!A-Za-z0-9._-]*) echo "$USAGE" >&2; echo "refused: rex-run.sh runs only run.sh" >&2; exit 2 ;;
esac
: "${REX_SESSION:?REX_SESSION is not set}"

HERE="$(cd "$(dirname "$0")" && pwd)"
E="${BJORNSTACK_EVALS_HOME:-$HOME/workspace/bjornstack-evals}"
[ -d "$E" ] || { echo "eval home $E does not exist; the owner makes it (see the harness README)" >&2; exit 1; }
NAME="$1"

# The command is fixed. --shell=none starts it directly, so rex joins no
# words for a shell to read; each argument stays one word. EVALS_DIR travels
# with the command, set to the eval home. PATH and HOME travel too: a
# tab started directly has no login shell to supply them, and claude finds the
# normal config through HOME. The tab does not take focus.
RUN_DIR="$E/runs/$NAME"
if ! CREATED="$(rex window new bjornstack-evals --keep-open --json --focus=false --shell=none -s "$REX_SESSION" -c "$E" -- \
    env "EVALS_DIR=$E" "PATH=$PATH" "HOME=$HOME" "$HERE/run.sh" "$@")"; then
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
  rex capture -s "$REX_SESSION" -b "$BLOCK" --trim | tail -n 20 >&2 || true
  if [ "$STATUS" -eq 1 ]; then
    echo "run.sh exited 1 (or rex could not tell: rex wait gives 1 then)" >&2
  else
    echo "run.sh exited $STATUS" >&2
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
echo "$RUN_DIR"
