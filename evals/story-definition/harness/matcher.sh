# Sourced by replay.sh. run_matcher <who> <prompt>: asks the matcher
# (claude -p, no tools, in an empty temp dir) and prints its result text
# with any code-fence lines removed. When claude exits non-zero, or its
# output is not the JSON envelope with a string result, it prints
# "<who>: ..." to stderr and returns 1. It never prints the raw output.
run_matcher() {
  local who="$1" prompt="$2" dir out result status=0
  dir="$(mktemp -d "${TMPDIR:-/tmp}/replay-matcher.XXXXXX")"
  out="$(cd "$dir" && env -u ANTHROPIC_API_KEY claude -p "$prompt" --restricted --tools "" --output-format json --no-session-persistence < /dev/null 2> /dev/null)" || status=$?
  rm -rf "$dir"
  if [ "$status" != 0 ]; then echo "$who: the matcher (claude -p) exited $status" >&2; return 1; fi
  result="$(printf '%s' "$out" | jq -er 'select(type == "object" and .is_error != true and (.result | type) == "string") | .result' 2> /dev/null | sed '/^```/d')" || { echo "$who: the matcher's output is not the expected JSON" >&2; return 1; }
  printf '%s' "$result"
}
