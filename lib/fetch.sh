#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

jm_fetch_ready() {
  if ! command -v subliminal >/dev/null 2>&1; then
    jm_error "subliminal is not installed: ${JM_INSTALL_HINT}."
    return 1
  fi
  JM_CATEGORIES=no
  jm_fr_help="$(subliminal download --help 2>/dev/null </dev/null)" || true
  case "${jm_fr_help}" in
  *--subtitle-categories*) JM_CATEGORIES=yes ;;
  *) ;;
  esac
  return 0
}

jm_fetch_count() {
  printf '%s\n' "$1" | awk '$1 == "Downloaded" && $2 ~ /^[0-9]+$/ { print $2; exit }'
}

jm_fetch_stem() {
  jm_fs_stem="${1%.*}"
  for jm_fs_file in "${jm_fs_stem}".*.[Ss][Rr][Tt] "${jm_fs_stem}".[Ss][Rr][Tt]; do
    [ -f "${jm_fs_file}" ] && jm_utf8 "${jm_fs_file}"
  done
  return 0
}

jm_fetch() {
  jm_fe_video="$1"
  set -- download -l "${JM_LANGUAGE}" -e utf-8
  [ "${JM_FORCE}" = no ] || set -- "$@" -f
  case "${JM_CATEGORIES}:${JM_HEARING}" in
  yes:yes) set -- "$@" -C hi,n,fo ;;
  yes:no) set -- "$@" -C n,fo,hi ;;
  no:yes) set -- "$@" -hi ;;
  *) ;;
  esac
  if ! jm_fe_said="$(subliminal "$@" -- "${jm_fe_video}" 2>&1 </dev/null)"; then
    jm_error "subliminal failed for ${jm_fe_video}."
    jm_said subliminal "${jm_fe_said}"
    JM_FAILED=$((JM_FAILED + 1))
    return 0
  fi
  jm_fe_count="$(jm_fetch_count "${jm_fe_said}")"
  if [ "${jm_fe_count:-0}" -eq 0 ]; then
    jm_warning "no ${JM_LANGUAGE} subtitle found for ${jm_fe_video}."
    JM_MISSED=$((JM_MISSED + 1))
    return 0
  fi
  printf '%s: saved a subtitle in %s.\n' "${jm_fe_video}" "${JM_LANGUAGE}"
  JM_SAVED=$((JM_SAVED + 1))
  jm_fetch_stem "${jm_fe_video}"
}
