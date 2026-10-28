#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

JIMAKU_VERSION="1.0.0"

jm_version() {
  printf '%s %s\n' "${JM_PROG}" "${JIMAKU_VERSION}"
}

jm_warning() {
  printf '%s: warning: %s\n' "${JM_PROG}" "$*" >&2
}

jm_error() {
  printf '%s: %s\n' "${JM_PROG}" "$*" >&2
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
