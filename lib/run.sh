#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

jm_choose_target() {
  if ! jm_interactive; then
    printf '.\n'
    return 0
  fi
  jm_ct_here="$(pwd -P)"
  if jm_ui_prompts; then
    jm_ui_header
  fi
  jm_prompt "Folder or video" "${jm_ct_here}"
}

jm_summary_where() {
  if [ "${JM_TARGETS}" -gt 1 ]; then
    printf 'Videos: %s in %s places\n' "${JM_FOUND}" "${JM_TARGETS}"
  elif [ "${JM_PLACE_KIND}" = video ]; then
    jm_say "Video:  ${JM_PLACE}"
  else
    jm_say "Videos: ${JM_FOUND} in ${JM_PLACE}"
  fi
}

jm_summary() {
  [ "${JM_JSON}" = no ] || return 0
  if jm_ui_out; then
    jm_summary_drawn
    return
  fi
  printf '\n'
  jm_summary_where
  jm_say "Plan:   ${JM_LANGUAGE} subtitles, saved as UTF-8 next to each video"
  if [ "${JM_FORCE}" = yes ]; then
    printf '        any subtitle already there is replaced and kept as .bak\n'
  else
    printf '        a video that already has one is skipped\n'
  fi
  [ "${JM_HEARING}" = no ] || printf '        subtitles for the hearing impaired come first\n'
  [ "${JM_DRY_RUN}" = no ] || printf '        dry run: list each video and download nothing\n'
  printf '\n'
}

jm_summary_drawn() {
  jm_sd_where="$(jm_summary_where | sed -n '1p')"
  jm_sd_mode="replace a subtitle already there"
  [ "${JM_FORCE}" = yes ] || jm_sd_mode="skip a video that has one"
  [ "${JM_DRY_RUN}" = no ] || jm_sd_mode="dry run, nothing is downloaded"
  jm_sd_value="$(printf '%s' "${jm_sd_where#*:}" | sed 's/^ *//')"
  jm_ui_summary "${jm_sd_where%%:*}:" "${jm_sd_value}" "Plan:" "${JM_LANGUAGE} subtitles, saved as UTF-8" "Mode:" "${jm_sd_mode}"
  if [ "${JM_DRY_RUN}" = yes ] || ! jm_ui_prompts; then
    return 0
  fi
  jm_sd_count="$(jm_plural "${JM_FOUND}" video)"
  if ! jm_ui_confirm "Fetch ${JM_LANGUAGE} subtitles for ${jm_sd_count}?" "Fetch" "Stop"; then
    jm_error "stopped: nothing was downloaded."
    return 1
  fi
}

jm_report_line() {
  if [ "$1" = ok ] && jm_ui_out; then
    jm_ui_done "$2"
    return 0
  fi
  if jm_ui_out; then
    jm_ui_log WARN "$2"
    return 0
  fi
  jm_say "$2"
}

jm_report_json() {
  jm_rj_language=null
  [ -z "${JM_LANGUAGE}" ] || jm_rj_language="$(jm_json_string "${JM_LANGUAGE}")"
  jm_rj_dry=false
  [ "${JM_DRY_RUN}" = no ] || jm_rj_dry=true
  printf '{"language":%s,"dry_run":%s,"found":%s,"saved":%s,"kept":%s,"missed":%s,"failed":%s,"videos":[%s]}\n' \
    "${jm_rj_language}" "${jm_rj_dry}" "${JM_FOUND}" "${JM_SAVED}" "${JM_KEPT}" "${JM_MISSED}" "${JM_FAILED}" "${JM_JSON_VIDEOS}"
  [ "${JM_MISSED}" -eq 0 ] && [ "${JM_FAILED}" -eq 0 ]
}

jm_report() {
  if [ "${JM_JSON}" = yes ]; then
    jm_report_json
    return
  fi
  jm_re_count="$(jm_plural "${JM_FOUND}" video)"
  if [ "${JM_DRY_RUN}" = yes ]; then
    jm_report_line ok "Dry run: ${jm_re_count} would get a subtitle in ${JM_LANGUAGE}. Nothing was downloaded."
    return 0
  fi
  jm_re_wanted=$((JM_FOUND - JM_KEPT))
  if [ "${jm_re_wanted}" -eq 0 ]; then
    jm_report_line ok "Every video already had its ${JM_LANGUAGE} subtitle, so nothing was downloaded."
    return 0
  fi
  jm_re_count="$(jm_plural "${jm_re_wanted}" video)"
  jm_re_state=ok
  [ "${JM_SAVED}" -eq "${jm_re_wanted}" ] || jm_re_state=partial
  [ "${jm_re_state}" = ok ] || jm_re_count="${JM_SAVED} of ${jm_re_count}"
  if [ "${JM_SAVED}" -eq 0 ]; then
    jm_report_line partial "No ${JM_LANGUAGE} subtitle was saved."
  else
    jm_report_line "${jm_re_state}" "Saved ${JM_LANGUAGE} subtitles for ${jm_re_count}."
  fi
  [ "${JM_MISSED}" -eq 0 ] && [ "${JM_FAILED}" -eq 0 ]
}

jm_nothing() {
  if [ "${JM_JSON}" = yes ]; then
    jm_report_json
    return 0
  fi
  if [ "${JM_TARGETS}" -gt 1 ] || [ -z "${JM_PLACE}" ]; then
    printf 'No videos found.\n'
  else
    jm_say "No videos in ${JM_PLACE}."
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
  jm_language_settle || return 1
  if [ "${JM_DRY_RUN}" = yes ]; then
    jm_summary || return 1
    jm_args_walk jm_show_target "$@"
    jm_report
    return
  fi
  jm_fetch_ready || return 1
  jm_summary || return 1
  jm_args_walk jm_fetch_target "$@"
  jm_report
}
