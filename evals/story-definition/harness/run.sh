#!/usr/bin/env bash
# Run bjornstack:story-definition once on the briefkasten spec.
#
# Usage: run.sh <run-name> [--owner-away] [--arm <arm>]
#   --owner-away   append "The owner is away for this session"
#   --arm          config dir under tmp/evals/config/ (default bjornstack-arm)
# Output: tmp/evals/runs/<run-name>/ with transcript.jsonl, stderr.log,
#         prompt.txt, model.txt, workdir/ and workdir-path.txt.
# Needs setup.sh and `claude auth login` for the arm first.
set -euo pipefail

NAME="${1:?usage: run.sh <run-name> [--owner-away] [--arm <arm>]}"
shift
AWAY=0
ARM=bjornstack-arm
while [ $# -gt 0 ]; do
  case "$1" in
    --owner-away) AWAY=1 ;;
    --arm) ARM="${2:?--arm needs a value}"; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

REPO="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
E="${EVALS_DIR:-$REPO/tmp/evals}"
OUT="$E/runs/$NAME"
[ ! -e "$OUT" ] || { echo "$OUT exists; pick a new run name" >&2; exit 1; }
mkdir -p "$OUT"
export CLAUDE_CONFIG_DIR="$E/config/$ARM"

# Empty working directory outside any repo, so no CLAUDE.md or beads load.
WORK="$(mktemp -d -t story-eval)"
cd "$WORK"

PROMPT="/bjornstack:story-definition $(cat "$E/specs/briefkasten.md")"
if [ "$AWAY" = 1 ]; then
  PROMPT="$PROMPT

The owner is away for this session"
fi
printf '%s\n' "$PROMPT" > "$OUT/prompt.txt"

# Read is allowed on the frozen plugin copies only; Bash stays denied.
claude -p "$PROMPT" \
  --output-format stream-json --verbose \
  --permission-mode acceptEdits \
  --allowedTools "Read($E/config/sources/**)" \
  > "$OUT/transcript.jsonl" 2> "$OUT/stderr.log"

# The model the CLI picked by default, from the init event.
jq -r 'select(.type=="system" and .subtype=="init") | .model' \
  "$OUT/transcript.jsonl" > "$OUT/model.txt"

# Keep whatever the session wrote in its working directory.
cp -R "$WORK" "$OUT/workdir"
echo "$WORK" > "$OUT/workdir-path.txt"
