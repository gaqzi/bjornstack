#!/usr/bin/env bash
# Set up the story-definition eval: a fresh config dir for one arm, frozen
# plugin copies, and the spec. Everything goes under tmp/evals/ (gitignored).
#
# Usage: setup.sh <arm> [bjornstack-commit]
#   <arm>               name of the config dir, e.g. bjornstack-arm
#   bjornstack-commit   commit to freeze the bjornstack plugin from (default HEAD)
# Env:
#   WORKFLOW_SRC        marketplace checkout holding the workflow plugin
#                       (default ~/.claude/plugins/marketplaces/gaqzi--private)
#   EVALS_DIR           override the output root (default <repo>/tmp/evals)
#
# No credentials are copied. Log in once per arm afterwards.
set -euo pipefail

ARM="${1:?usage: setup.sh <arm> [bjornstack-commit]}"
COMMIT="${2:-HEAD}"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
E="${EVALS_DIR:-$REPO/tmp/evals}"
WORKFLOW_SRC="${WORKFLOW_SRC:-$HOME/.claude/plugins/marketplaces/gaqzi--private}"
CFG="$E/config/$ARM"
SRC="$E/config/sources"

[ -d "$WORKFLOW_SRC/workflow" ] || { echo "no workflow plugin at $WORKFLOW_SRC" >&2; exit 1; }
[ ! -e "$CFG" ] || { echo "$CFG exists; remove it for a fresh config dir" >&2; exit 1; }

# Frozen plugin copies (shared by arms; refreshed on each setup).
rm -rf "$SRC/bjornstack" "$SRC/gaqzi--private"
mkdir -p "$SRC/bjornstack" "$SRC/gaqzi--private" "$CFG" "$E/specs" "$E/runs"
git -C "$REPO" archive "$COMMIT" .claude-plugin plugin | tar -x -C "$SRC/bjornstack"
cp -R "$WORKFLOW_SRC/.claude-plugin" "$WORKFLOW_SRC/workflow" "$SRC/gaqzi--private/"
git -C "$REPO" rev-parse "$COMMIT" > "$SRC/bjornstack.commit"

cp "$HERE/briefkasten-spec.md" "$E/specs/briefkasten.md"

export CLAUDE_CONFIG_DIR="$CFG"
claude plugin marketplace add "$SRC/bjornstack"
claude plugin marketplace add "$SRC/gaqzi--private"
claude plugin install bjornstack@bjornstack
claude plugin install workflow@gaqzi--private

cat <<MSG

Set up arm '$ARM' (bjornstack plugin frozen from $(cat "$SRC/bjornstack.commit")).
Log in once, interactively (credentials are not copied):
  CLAUDE_CONFIG_DIR=$CFG claude auth login
MSG
