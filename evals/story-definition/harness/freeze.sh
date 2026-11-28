#!/usr/bin/env bash
# Freeze the bjornstack plugin from one commit into the eval home: the copy
# a run.sh --prompt run loads, and the file naming the commit it came from.
#
# Usage: freeze.sh <commit>
# Env:
#   EVALS_DIR   the eval home (default <repo>/tmp/evals)
# Replaces config/sources/bjornstack (.claude-plugin, plugin/, strategies/
# and tenets/ of the commit: plugin/ links to the last two) and writes
# config/sources/bjornstack.commit with the full commit id. Nothing else in
# the eval home is touched. A commit that does not resolve changes nothing.
# A symlink, to a file or a directory, that is dangling or whose target lies
# outside the copy refuses the freeze. So does a plugin/ that holds hooks/,
# .mcp.json or .lsp.json, or whose plugin/.claude-plugin/plugin.json has a
# hooks or mcpServers key: the copy would run code in a session that only
# means to read rules.
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
# through it finds nothing or leaves the copy. A file link is resolved by its
# own target (following chains), not by the directory it sits in.
ROOT="$(cd -P "$STAGE" && pwd -P)"
resolve() {
  local P="$1" D
  while [ -L "$P" ]; do
    D="$(cd -P "$(dirname "$P")" && pwd -P)"
    P="$(readlink "$P")"
    case "$P" in /*) ;; *) P="$D/$P" ;; esac
  done
  if [ -d "$P" ]; then
    (cd -P "$P" && pwd -P)
  else
    echo "$(cd -P "$(dirname "$P")" && pwd -P)/$(basename "$P")"
  fi
}
while IFS= read -r L; do
  [ -e "$L" ] || { echo "dangling symlink in the frozen copy: ${L#$STAGE/}" >&2; exit 1; }
  T="$(resolve "$L")"
  case "$T/" in "$ROOT"/*) ;; *) echo "symlink leaves the frozen copy: ${L#$STAGE/} -> $T" >&2; exit 1 ;; esac
done < <(find "$STAGE" -type l)

# A plugin that runs code (hooks, MCP or LSP servers) is not frozen.
for F in hooks .mcp.json .lsp.json; do
  [ ! -e "$STAGE/plugin/$F" ] || { echo "plugin/$F in the frozen copy would run code in an eval session; refusing $FULL" >&2; exit 1; }
done
MANIFEST="$STAGE/plugin/.claude-plugin/plugin.json"
if [ -f "$MANIFEST" ]; then
  BAD=$(jq -r '[("hooks", "mcpServers") as $k | select(has($k)) | $k] | join(", ")' "$MANIFEST") \
    || { echo "plugin/.claude-plugin/plugin.json is unreadable or not a JSON object; refusing the freeze" >&2; exit 1; }
  [ -z "$BAD" ] || { echo "plugin/.claude-plugin/plugin.json has $BAD, which would run code in an eval session; refusing the freeze" >&2; exit 1; }
fi

rm -rf "$SRC/bjornstack"
mv "$STAGE" "$SRC/bjornstack"
echo "$FULL" > "$SRC/bjornstack.commit"
