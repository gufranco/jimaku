#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

JIMAKU_VERSION="1.0.0"

jm_version() {
  printf '%s %s\n' "${JM_PROG}" "${JIMAKU_VERSION}"
}

jm_wrap() {
  awk -v width="${JM_WIDTH}" -v indent="$1" '
    function pad(n,   s) {
      s = ""
      while (n-- > 0) { s = s " " }
      return s
    }
    length($0) <= width { print; next }
    {
      match($0, /^ */)
      n = split($0, word, " ")
      out = substr($0, 1, RLENGTH) word[1]
      for (i = 2; i <= n; i++) {
        if (length(out) + 1 + length(word[i]) > width) {
          print out
          out = pad(indent) word[i]
        } else {
          out = out " " word[i]
        }
      }
      print out
    }'
}

jm_terminal() {
  [ "${JIMAKU_TERMINAL:-}" = 1 ] || [ -t 1 ]
}

jm_say() {
  jm_sy_text="$2"
  if [ "${#jm_sy_text}" -le "${JM_WIDTH}" ] || ! jm_terminal; then
    printf '%s\n' "${jm_sy_text}"
    return 0
  fi
  printf '%s\n' "${jm_sy_text}" | jm_wrap "$1"
}

jm_warning() {
  jm_say 0 "${JM_PROG}: warning: $*" >&2
}

jm_error() {
  jm_say 0 "${JM_PROG}: $*" >&2
}

jm_plural() {
  if [ "$1" -eq 1 ]; then
    printf '1 %s\n' "$2"
  else
    printf '%s %ss\n' "$1" "$2"
  fi
}

jm_said() {
  printf '%s\n' "$2" | while IFS= read -r jm_sd_line; do
    [ -z "${jm_sd_line}" ] || jm_error "$1 said: ${jm_sd_line}"
  done
}

jm_expand() {
  case "$1" in
  \~) printf '%s\n' "${HOME}" ;;
  \~/*) printf '%s/%s\n' "${HOME}" "${1#\~/}" ;;
  *) printf '%s\n' "$1" ;;
  esac
}
