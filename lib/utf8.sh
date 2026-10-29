#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

jm_has_bom() {
  jm_hb_head="$(od -An -tx1 -N3 "$1" 2>/dev/null | tr -d ' \n')"
  [ "${jm_hb_head}" = efbbbf ]
}

jm_strip_bom() {
  jm_sb_mark="$(printf '\357\273\277')"
  if sed "1s/^${jm_sb_mark}//" "$1" >"$1.jimaku" 2>/dev/null; then
    mv -f "$1.jimaku" "$1"
    return 0
  fi
  rm -f "$1.jimaku"
  return 1
}

jm_utf8_from() {
  if iconv -f "$2" -t UTF-8 "$1" >"$1.jimaku" 2>/dev/null && [ -s "$1.jimaku" ]; then
    mv -f "$1.jimaku" "$1"
    jm_has_bom "$1" && jm_strip_bom "$1"
    [ "${JM_JSON}" = yes ] || jm_say 0 "$1: converted from $2 to UTF-8."
    return 0
  fi
  rm -f "$1.jimaku"
  return 1
}

jm_utf8() {
  jm_u8_found="$(file -b --mime-encoding "$1" 2>/dev/null)" || jm_u8_found=""
  case "${jm_u8_found}" in
  '')
    jm_warning "could not tell the encoding of $1, so it stays as it is."
    return 0
    ;;
  utf-8 | us-ascii)
    jm_has_bom "$1" && jm_strip_bom "$1"
    return 0
    ;;
  *) ;;
  esac
  for jm_u8_from in "${jm_u8_found}" WINDOWS-1252 ISO-8859-1; do
    jm_utf8_from "$1" "${jm_u8_from}" && return 0
  done
  jm_warning "could not convert $1 to UTF-8, so it stays as it is."
  return 0
}
