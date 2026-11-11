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

jm_fetch_run() {
  jm_fr2_video="$1"
  shift
  if ! jm_ui_err; then
    subliminal "$@" -- "${jm_fr2_video}" 2>&1 </dev/null
    return
  fi
  jm_fr2_out="$(mktemp "${TMPDIR:-/tmp}/jimaku-said.XXXXXX")"
  jm_fr2_status=0
  jm_ui_spin "Searching for ${jm_fr2_video##*/}" "${jm_fr2_out}.err" jm_fetch_into "${jm_fr2_out}" "${jm_fr2_video}" "$@" ||
    jm_fr2_status=$?
  cat "${jm_fr2_out}"
  rm -f "${jm_fr2_out}" "${jm_fr2_out}.err"
  return "${jm_fr2_status}"
}

jm_fetch_into() {
  jm_fi_out="$1"
  jm_fi_video="$2"
  shift 2
  subliminal "$@" -- "${jm_fi_video}" >"${jm_fi_out}" 2>&1 </dev/null
}

jm_kept() {
  [ "${JM_FORCE}" = no ] && [ -f "${1%.*}.${JM_LANGUAGE}.srt" ] || return 1
  [ "${JM_JSON}" = yes ] || jm_say "$1: kept the ${JM_LANGUAGE} subtitle already there."
  JM_KEPT=$((JM_KEPT + 1))
  jm_json_video "$1" kept
}

jm_fetch_replacing() {
  JM_REPLACED=""
  [ "${JM_FORCE}" = yes ] && [ -f "${JM_FRESH}" ] || return 0
  jm_backup "${JM_FRESH}" || return 1
  JM_REPLACED="${JM_BACKUP}"
}

jm_fetch_unreplaced() {
  [ -n "${JM_REPLACED}" ] || return 0
  cmp -s "${JM_FRESH}" "${JM_REPLACED}" && rm -f "${JM_REPLACED}"
  return 0
}

jm_fetch_failed() {
  JM_FAILED=$((JM_FAILED + 1))
  jm_json_video "$1" failed
}

jm_fetch_saved() {
  [ "${JM_JSON}" = yes ] || jm_say "$1: saved a subtitle in ${JM_LANGUAGE}."
  [ -z "${JM_REPLACED}" ] || [ "${JM_JSON}" = yes ] || jm_say "${JM_FRESH}: kept the replaced subtitle as ${JM_REPLACED}."
  JM_SAVED=$((JM_SAVED + 1))
  jm_json_video "$1" saved
  jm_fetch_stem "$1"
}

jm_fetch_missed() {
  jm_fetch_unreplaced
  jm_warning "no ${JM_LANGUAGE} subtitle found for $1."
  JM_MISSED=$((JM_MISSED + 1))
  jm_json_video "$1" missed
}

jm_fetch() {
  jm_fe_video="$1"
  jm_kept "${jm_fe_video}" && return 0
  JM_FRESH="${jm_fe_video%.*}.${JM_LANGUAGE}.srt"
  jm_fetch_replacing || {
    jm_fetch_failed "${jm_fe_video}"
    return 0
  }
  set -- download -l "${JM_LANGUAGE}" -e utf-8
  [ "${JM_FORCE}" = no ] || set -- "$@" -f
  case "${JM_CATEGORIES}:${JM_HEARING}" in
  yes:yes) set -- "$@" -C hi,n,fo ;;
  yes:no) set -- "$@" -C n,fo,hi ;;
  no:yes) set -- "$@" -hi ;;
  *) ;;
  esac
  if ! jm_fe_said="$(jm_fetch_run "${jm_fe_video}" "$@")"; then
    jm_fetch_unreplaced
    jm_error "subliminal failed for ${jm_fe_video}."
    jm_said subliminal "${jm_fe_said}"
    jm_fetch_failed "${jm_fe_video}"
    return 0
  fi
  jm_fe_count="$(jm_fetch_count "${jm_fe_said}")"
  [ "${jm_fe_count:-0}" -eq 0 ] || {
    jm_fetch_saved "${jm_fe_video}"
    return 0
  }
  jm_fetch_missed "${jm_fe_video}"
}
