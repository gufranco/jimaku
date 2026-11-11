#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

JIMAKU_VERSION="1.4.0"

jm_version() {
  printf '%s %s\n' "${JM_PROG}" "${JIMAKU_VERSION}"
}

jm_say() {
  printf '%s\n' "$1"
}

jm_warning() {
  if jm_ui_err; then
    jm_ui_log WARN "$*"
    return 0
  fi
  jm_say "${JM_PROG}: warning: $*" >&2
}

jm_error() {
  if jm_ui_err; then
    jm_ui_log ERROR "$*"
    return 0
  fi
  jm_say "${JM_PROG}: $*" >&2
}

jm_json_string() {
  printf '%s' "$1" | awk '
    BEGIN { for (i = 1; i < 32; i++) code[sprintf("%c", i)] = sprintf("\\u%04x", i) }
    function escape(s,   r, c, i) {
      r = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") r = r "\\\\"
        else if (c == "\"") r = r "\\\""
        else if (c in code) r = r code[c]
        else r = r c
      }
      return r
    }
    { out = out (NR > 1 ? "\\n" : "") escape($0) }
    END { printf "\"%s\"", out }'
}

jm_json_video() {
  jm_jv_path="$(jm_json_string "$1")"
  JM_JSON_VIDEOS="${JM_JSON_VIDEOS}${JM_JSON_VIDEOS:+,}{\"video\":${jm_jv_path},\"result\":\"$2\"}"
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
