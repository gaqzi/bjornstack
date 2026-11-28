# Input checks shared by run.sh, rex-run.sh and freeze.sh. Sourced, not run.
#
# Needs $USAGE set by the sourcing script; the refusals print it and exit 2.
#   resolve_file <path>             a file's path through every symlink;
#                                   fails, printing nothing, when its
#                                   directory does not resolve
#   resolve <path>                  a symlink's target through every symlink:
#                                   the physical path of a directory, or of a
#                                   file; fails as resolve_file does
#   check_arm <value>               refuse an --arm value that is not a plain
#                                   name (letters, digits, '.', '_' and '-',
#                                   not starting with '-')
#   check_under <option> <file> <allowed>
#                                   print the file's resolved path, and
#                                   refuse (exit 2, nothing printed) a
#                                   --prompt or --stand-in file that does not
#                                   resolve, does not resolve under <allowed>,
#                                   a directory path ending in '/', or has
#                                   more than one hard link (its content
#                                   could change through the other name).
#                                   Call it as P="$(check_under ...)" || exit $?
#                                   and read exactly P: an exit inside $(...)
#                                   leaves only the subshell, and a second
#                                   resolve could see a swapped link.
#   link_count <file>               the file's hard-link count (macOS or Linux)

resolve_file() {
  local P="$1" D
  while [ -L "$P" ]; do
    D="$(cd -P "$(dirname "$P")" 2> /dev/null && pwd -P)" || return 1
    P="$(readlink "$P")"
    case "$P" in /*) ;; *) P="$D/$P" ;; esac
  done
  D="$(cd -P "$(dirname "$P")" 2> /dev/null && pwd -P)" || return 1
  echo "$D/$(basename "$P")"
}

resolve() {
  local P
  P="$(resolve_file "$1")" || return 1
  if [ -d "$P" ]; then
    (cd -P "$P" && pwd -P)
  else
    echo "$P"
  fi
}

check_arm() {
  case "$1" in
    "" | . | .. | -* | *[!A-Za-z0-9._-]*) echo "$USAGE" >&2; echo "refused: --arm '$1' is not a plain name" >&2; exit 2 ;;
  esac
}

link_count() {
  stat -f %l "$1" 2>/dev/null || stat -c %h "$1"
}

check_under() {
  local RESOLVED LINKS
  RESOLVED="$(resolve_file "$2")" || { echo "$USAGE" >&2; echo "refused: $1 '$2' does not resolve (its directory is missing)" >&2; exit 2; }
  case "$RESOLVED" in
    "$3"*) ;;
    *) echo "$USAGE" >&2; echo "refused: $1 '$2' resolves to $RESOLVED, outside $3" >&2; exit 2 ;;
  esac
  if [ -f "$RESOLVED" ]; then
    LINKS="$(link_count "$RESOLVED")"
    [ "$LINKS" -le 1 ] || { echo "$USAGE" >&2; echo "refused: $1 '$2' has $LINKS hard links" >&2; exit 2; }
  fi
  echo "$RESOLVED"
}
