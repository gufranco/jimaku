#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

jm_is_video() {
  case "$1" in
  *.[Mm][Kk][Vv] | *.[Mm][Pp]4 | *.[Mm]4[Vv] | *.[Aa][Vv][Ii] | *.[Mm][Oo][Vv] | *.[Ww][Mm][Vv]) [ -f "$1" ] ;;
  *.[Ww][Ee][Bb][Mm] | *.[Mm][Pp][Gg] | *.[Mm][Pp][Ee][Gg] | *.[Tt][Ss] | *.[Mm]2[Tt][Ss]) [ -f "$1" ] ;;
  *.[Ff][Ll][Vv] | *.[Oo][Gg][Mm] | *.[Dd][Ii][Vv][Xx] | *.3[Gg][Pp]) [ -f "$1" ] ;;
  *) return 1 ;;
  esac
}

jm_place() {
  JM_PLACE="$1"
  JM_PLACE_KIND="$2"
}

jm_tally_target() {
  jm_tt_path="$(jm_expand "$1")"
  if [ -d "${jm_tt_path}" ]; then
    jm_place "${jm_tt_path}" folder
    for jm_tt_file in "${jm_tt_path}"/*; do
      jm_is_video "${jm_tt_file}" && JM_FOUND=$((JM_FOUND + 1))
    done
    return 0
  fi
  if [ -f "${jm_tt_path}" ]; then
    jm_place "${jm_tt_path}" video
    JM_FOUND=$((JM_FOUND + 1))
    return 0
  fi
  jm_error "no such video or folder: ${jm_tt_path}"
  return 1
}

jm_show_target() {
  jm_st_path="$(jm_expand "$1")"
  if [ -f "${jm_st_path}" ]; then
    printf '%s\n' "${jm_st_path}"
    return 0
  fi
  for jm_st_file in "${jm_st_path}"/*; do
    jm_is_video "${jm_st_file}" && printf '%s\n' "${jm_st_file}"
  done
  return 0
}

jm_fetch_target() {
  jm_ft_path="$(jm_expand "$1")"
  if [ -f "${jm_ft_path}" ]; then
    jm_fetch "${jm_ft_path}"
    return 0
  fi
  for jm_ft_file in "${jm_ft_path}"/*; do
    jm_is_video "${jm_ft_file}" && jm_fetch "${jm_ft_file}"
  done
  for jm_ft_file in "${jm_ft_path}"/*.[Ss][Rr][Tt]; do
    [ -f "${jm_ft_file}" ] && jm_utf8 "${jm_ft_file}"
  done
  return 0
}
