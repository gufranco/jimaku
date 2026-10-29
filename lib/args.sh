#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

jm_args_bad_language() {
  jm_cli_hint "'$1' is not a language code such as pt-BR or en"
  return 1
}

jm_args_language() {
  case "$1" in
  '' | -*)
    jm_cli_hint "option '--language' needs a value"
    return 1
    ;;
  *) ;;
  esac
  jm_language_valid "$1" || jm_args_bad_language "$1" || return 1
  JM_LANGUAGE="$1"
}

jm_args_target() {
  if [ -n "$1" ]; then
    "$1" "$2"
    return
  fi
  if [ -z "$2" ]; then
    jm_cli_hint "the video or folder name is empty"
    return 1
  fi
  JM_TARGETS=$((JM_TARGETS + 1))
}

jm_args_one() {
  case "$2" in
  --) JM_ARGS_DONE=yes ;;
  --dry-run) JM_DRY_RUN=yes ;;
  --json) JM_JSON=yes ;;
  --force) JM_FORCE=yes ;;
  --no-force) JM_FORCE=no ;;
  --hearing-impaired) JM_HEARING=yes ;;
  --no-hearing-impaired) JM_HEARING=no ;;
  --language) JM_ARGS_PENDING=yes ;;
  --language=*) jm_args_language "${2#--language=}" ;;
  --*=*)
    jm_cli_hint "unknown option '${2%%=*}'"
    return 1
    ;;
  -?*)
    jm_cli_hint "unknown option '$2'"
    return 1
    ;;
  *) jm_args_target "$1" "$2" ;;
  esac
}

jm_args_walk() {
  jm_aw_visit="$1"
  shift
  JM_ARGS_DONE=no
  JM_ARGS_PENDING=no
  for jm_aw_arg in "$@"; do
    if [ "${JM_ARGS_PENDING}" = yes ]; then
      JM_ARGS_PENDING=no
      jm_args_language "${jm_aw_arg}" || return 1
    elif [ "${JM_ARGS_DONE}" = yes ]; then
      jm_args_target "${jm_aw_visit}" "${jm_aw_arg}" || return 1
    else
      jm_args_one "${jm_aw_visit}" "${jm_aw_arg}" || return 1
    fi
  done
  [ "${JM_ARGS_PENDING}" = no ] && return 0
  jm_cli_hint "option '--language' needs a value"
  return 1
}
