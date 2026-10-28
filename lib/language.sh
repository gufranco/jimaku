#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

jm_language_valid() {
  case "$1" in
  [A-Za-z][A-Za-z] | [A-Za-z][A-Za-z][A-Za-z]) return 0 ;;
  [A-Za-z][A-Za-z]-?* | [A-Za-z][A-Za-z][A-Za-z]-?*) jm_language_region "${1#*-}" ;;
  *) return 1 ;;
  esac
}

jm_language_region() {
  case "$1" in
  *[!A-Za-z0-9-]*) return 1 ;;
  *) return 0 ;;
  esac
}

jm_language_menu() {
  cat <<'MENU'
en English
es Spanish
pt-BR Brazilian Portuguese
fr French
de German
it Italian
pt European Portuguese
ru Russian
ar Arabic
ja Japanese
ko Korean
zh Chinese
MENU
}

jm_language_show() {
  printf 'Common subtitle languages:\n' >&2
  jm_language_menu | awk '{ code = $1; $1 = ""; printf "  %2d) %-6s%s\n", NR, code, $0 }' >&2
}

jm_language_pick() {
  case "$1" in
  *[!0-9]*) jm_language_valid "$1" && printf '%s\n' "$1" ;;
  *) jm_language_menu | awk -v n="$1" 'NR == n + 0 { print $1; found = 1 } END { exit !found }' ;;
  esac
}

jm_language_ask() {
  jm_la_tries=0
  jm_language_show
  while [ "${jm_la_tries}" -lt 3 ]; do
    jm_la_answer="$(jm_prompt "Language, a number or a code" "${JM_DEFAULT_LANGUAGE}")" || return 1
    if jm_la_code="$(jm_language_pick "${jm_la_answer}")"; then
      JM_LANGUAGE="${jm_la_code}"
      return 0
    fi
    jm_error "'${jm_la_answer}' is not a number from the list or a language code such as pt-BR or en."
    jm_la_tries=$((jm_la_tries + 1))
  done
  jm_cli_hint "no language was chosen"
  return 1
}

jm_language_settle() {
  [ -z "${JM_LANGUAGE}" ] || return 0
  if [ -n "${JIMAKU_LANGUAGE:-}" ]; then
    if jm_language_valid "${JIMAKU_LANGUAGE}"; then
      JM_LANGUAGE="${JIMAKU_LANGUAGE}"
      return 0
    fi
    jm_cli_hint "JIMAKU_LANGUAGE is '${JIMAKU_LANGUAGE}', which is not a language code such as pt-BR or en"
    return 1
  fi
  if jm_interactive; then
    jm_language_ask
    return
  fi
  JM_LANGUAGE="${JM_DEFAULT_LANGUAGE}"
}
