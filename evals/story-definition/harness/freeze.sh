#!/usr/bin/env bash
# Freeze the bjornstack plugin from one commit into the eval home: the copy
# a run.sh --prompt run loads, and the file naming the commit it came from.
#
# Usage: freeze.sh <commit>
# Env:
#   EVALS_DIR   the eval home (default <repo>/tmp/evals)
# Replaces config/sources/bjornstack (.claude-plugin, plugin/, strategies/
# and tenets/ of the commit: plugin/ links to the last two) and writes config/sources/bjornstack.commit with the full commit
# id. Nothing else in the eval home is touched. A commit that does not
# resolve changes nothing.
set -euo pipefail

USAGE="usage: freeze.sh <commit>"
[ $# -eq 1 ] || { echo "$USAGE" >&2; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
E="${EVALS_DIR:-$REPO/tmp/evals}"
SRC="$E/config/sources"

FULL="$(git -C "$REPO" rev-parse --verify --quiet "$1^{commit}")" \
  || { echo "$1 is not a commit of $REPO" >&2; exit 1; }

# Build the new copy beside the old one, so a failure leaves the old one.
mkdir -p "$SRC"
STAGE="$(mktemp -d "$SRC/.bjornstack.new.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
git -C "$REPO" archive "$FULL" .claude-plugin plugin strategies tenets | tar -x -C "$STAGE"

# Every symlink in the copy must resolve inside it, or a session reading
# through it finds nothing.
ROOT="$(cd -P "$STAGE" && pwd -P)"
while IFS= read -r L; do
  if [ -d "$L" ]; then
    T="$(cd -P "$L" && pwd -P)"
  else
    [ -e "$L" ] || { echo "dangling symlink in the frozen copy: ${L#$STAGE/}" >&2; exit 1; }
    T="$(cd -P "$(dirname "$L")" && pwd -P)"
  fi
  case "$T/" in "$ROOT"/*) ;; *) echo "symlink leaves the frozen copy: ${L#$STAGE/} -> $T" >&2; exit 1 ;; esac
done < <(find "$STAGE" -type l)

rm -rf "$SRC/bjornstack"
mv "$STAGE" "$SRC/bjornstack"
echo "$FULL" > "$SRC/bjornstack.commit"
