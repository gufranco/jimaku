#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

jm_choose_target() {
  if ! jm_interactive; then
    printf '.\n'
    return 0
  fi
  jm_ct_here="$(pwd -P)"
  jm_prompt "Folder or video" "${jm_ct_here}"
}

jm_summary_where() {
  if [ "${JM_TARGETS}" -gt 1 ]; then
    printf 'Videos: %s in %s places\n' "${JM_FOUND}" "${JM_TARGETS}"
  elif [ "${JM_PLACE_KIND}" = video ]; then
    printf 'Video:  %s\n' "${JM_PLACE}"
  else
    printf 'Videos: %s in %s\n' "${JM_FOUND}" "${JM_PLACE}"
  fi
}

jm_summary() {
  printf '\n'
  jm_summary_where
  printf 'Plan:   %s subtitles, saved as UTF-8 next to each video\n' "${JM_LANGUAGE}"
  if [ "${JM_FORCE}" = yes ]; then
    printf '        any subtitle already there is replaced\n'
  else
    printf '        a video that already has one is skipped\n'
  fi
  [ "${JM_HEARING}" = no ] || printf '        subtitles for the hearing impaired come first\n'
  [ "${JM_DRY_RUN}" = no ] || printf '        dry run: list each video and download nothing\n'
  printf '\n'
}

jm_report() {
  jm_re_count="$(jm_plural "${JM_FOUND}" video)"
  if [ "${JM_DRY_RUN}" = yes ]; then
    printf 'Dry run: %s would get a %s subtitle. Nothing was downloaded.\n' "${jm_re_count}" "${JM_LANGUAGE}"
    return 0
  fi
  [ "${JM_SAVED}" -eq "${JM_FOUND}" ] || jm_re_count="${JM_SAVED} of ${jm_re_count}"
  if [ "${JM_SAVED}" -eq 0 ]; then
    printf 'No %s subtitle was saved.\n' "${JM_LANGUAGE}"
  else
    printf 'Saved %s subtitles for %s.\n' "${JM_LANGUAGE}" "${jm_re_count}"
  fi
  [ "${JM_MISSED}" -eq 0 ] && [ "${JM_FAILED}" -eq 0 ]
}

jm_nothing() {
  if [ "${JM_TARGETS}" -gt 1 ]; then
    printf 'No videos found.\n'
  else
    printf 'No videos in %s.\n' "${JM_PLACE}"
  fi
}

jm_start() {
  jm_args_walk "" "$@" || return 1
  if [ "${JM_TARGETS}" -eq 0 ]; then
    jm_sr_target="$(jm_choose_target)" || return 1
    [ "${JM_ARGS_DONE}" = yes ] || set -- "$@" --
    set -- "$@" "${jm_sr_target}"
    JM_TARGETS=1
  fi
  jm_args_walk jm_tally_target "$@" || return 1
  if [ "${JM_FOUND}" -eq 0 ]; then
    jm_nothing
    return 0
  fi
  if [ "${JM_DRY_RUN}" = yes ]; then
    jm_summary
    jm_args_walk jm_show_target "$@"
    jm_report
    return
  fi
  jm_fetch_ready || return 1
  jm_summary
  jm_args_walk jm_fetch_target "$@"
  jm_report
}
