#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

jm_doctor_row() {
  if jm_ui_out; then
    case "$2" in
    ok) jm_dw_state="@ok:ok" ;;
    *) jm_dw_state="@bad:$2" ;;
    esac
    JM_DOCTOR_ROWS="${JM_DOCTOR_ROWS}$1	${jm_dw_state}	$3
"
    return 0
  fi
  printf '%-18s %-8s %s\n' "$1" "$2" "$3"
}

jm_doctor_report() {
  if ! jm_ui_out; then
    return 0
  fi
  printf 'Tool\tState\tDetail\n%s' "${JM_DOCTOR_ROWS}" | jm_ui_table
  if [ "$1" -ne 0 ]; then
    jm_ui_log ERROR "a required tool is missing. install it and run jimaku doctor again."
    return 0
  fi
  jm_ui_done "Ready. Every tool jimaku needs is here."
}

jm_doctor_gum() {
  jm_dg_found="$(command -v gum 2>/dev/null || true)"
  if [ -z "${jm_dg_found}" ]; then
    jm_doctor_row gum missing "install with: brew install gum, or see https://github.com/charmbracelet/gum"
    return 1
  fi
  jm_dg_raw="$(gum --version 2>/dev/null || true)"
  jm_dg_version="$(jm_flavor_version "${jm_dg_raw}")"
  jm_doctor_row gum ok "${jm_dg_found}${jm_dg_version:+, ${jm_dg_version}}"
}

jm_flavor_version() {
  printf '%s\n' "$1" | awk '{
    for (i = 1; i <= NF; i++) {
      t = $i
      gsub(/[,;()]/, "", t)
      sub(/^v/, "", t)
      if (t ~ /^[0-9]+(\.[0-9]+)+[a-z0-9]*$/ || t ~ /^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$/) { print t; exit }
    }
  }'
}

jm_tool_line() {
  jm_tl_line="$(printf '%s\n' "$1" | awk '/BusyBox|This is not GNU/ { print; exit }')"
  if [ -z "${jm_tl_line}" ]; then
    jm_tl_line="$(printf '%s\n' "$1" | sed -n '1p')"
  fi
  printf '%s\n' "${jm_tl_line}"
}

jm_tool_flavor() {
  jm_tf_raw="$("$1" --version 2>&1 </dev/null)" || true
  jm_tf_text="$(jm_tool_line "${jm_tf_raw}")"
  jm_tf_version="$(jm_flavor_version "${jm_tf_text}")"
  jm_tf_os="${JIMAKU_OS:-}"
  [ -n "${jm_tf_os}" ] || jm_tf_os="$(uname -s)"
  case "${jm_tf_text}" in
  *uutils*) jm_tf_name=uutils ;;
  *BusyBox*) jm_tf_name=busybox ;;
  *"This is not GNU"*)
    jm_tf_name=busybox
    jm_tf_version=""
    ;;
  *GNU* | *"(coreutils)"*) jm_tf_name=gnu ;;
  *mawk*) jm_tf_name=mawk ;;
  *"awk version"*) jm_tf_name=bsd ;;
  *)
    jm_tf_version=""
    case "$1:${jm_tf_os}" in
    *uutils*:* | */cargo/*:*) jm_tf_name=uutils ;;
    *:Darwin | *:*BSD) jm_tf_name=bsd ;;
    *) jm_tf_name=unknown ;;
    esac
    ;;
  esac
  printf '%s%s\n' "${jm_tf_name}" "${jm_tf_version:+ ${jm_tf_version}}"
}

jm_doctor_tool() {
  jm_dt_found="$(command -v "$1" 2>/dev/null || true)"
  if [ -z "${jm_dt_found}" ]; then
    jm_doctor_row "$1" missing "required"
    return 1
  fi
  jm_dt_flavor="$(jm_tool_flavor "${jm_dt_found}")"
  jm_doctor_row "$1" ok "${jm_dt_found}, ${jm_dt_flavor}"
}

jm_doctor_subliminal() {
  jm_ds_found="$(command -v subliminal 2>/dev/null || true)"
  if [ -z "${jm_ds_found}" ]; then
    jm_doctor_row subliminal missing "required: ${JM_INSTALL_HINT}"
    return 1
  fi
  jm_ds_raw="$(subliminal --version 2>&1 </dev/null)" || true
  jm_ds_version="$(jm_flavor_version "${jm_ds_raw}")"
  jm_doctor_row subliminal ok "${jm_ds_found}${jm_ds_version:+, ${jm_ds_version}}"
}

jm_doctor() {
  jm_dr_status=0
  jm_doctor_gum || jm_dr_status=1
  jm_doctor_subliminal || jm_dr_status=1
  for jm_dr_tool in file iconv sed awk; do
    jm_doctor_tool "${jm_dr_tool}" || jm_dr_status=1
  done
  jm_doctor_report "${jm_dr_status}"
  return "${jm_dr_status}"
}
