# Input checks shared by run.sh, rex-run.sh and freeze.sh. Sourced, not run.
#
# Needs $USAGE set by the sourcing script; the refusals print it and exit 2.
#   resolve_file <path>             a file's path through every symlink; a
#                                   file in a missing directory resolves to
#                                   the path as given
#   resolve <path>                  a symlink's target through every symlink:
#                                   the physical path of a directory, or of a file
#   check_arm <value>               refuse an --arm value that is not a plain
#                                   name (letters, digits, '.', '_' and '-',
#                                   not starting with '-')
#   check_under <option> <file> <allowed>
#                                   refuse a --prompt or --stand-in file that
#                                   does not resolve under <allowed>, a
#                                   directory path ending in '/'

resolve_file() {
  local P="$1" D
  while [ -L "$P" ]; do
    D="$(cd -P "$(dirname "$P")" && pwd -P)"
    P="$(readlink "$P")"
    case "$P" in /*) ;; *) P="$D/$P" ;; esac
  done
  if D="$(cd -P "$(dirname "$P")" 2>/dev/null && pwd -P)"; then
    echo "$D/$(basename "$P")"
  else
    echo "$P"
  fi
}

resolve() {
  local P
  P="$(resolve_file "$1")"
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

check_under() {
  local RESOLVED
  RESOLVED="$(resolve_file "$2")"
  case "$RESOLVED" in
    "$3"*) ;;
    *) echo "$USAGE" >&2; echo "refused: $1 '$2' resolves to $RESOLVED, outside $3" >&2; exit 2 ;;
  esac
}
