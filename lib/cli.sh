#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

jm_usage() {
  cat <<'USAGE'
jimaku - download subtitles for videos and save them as UTF-8

usage:
  jimaku                       ask for the folder or video, then fetch
  jimaku [options] [video|folder...]
                               fetch a subtitle for each video given and for
                               every video in each folder, the current one
                               when none is given
  jimaku doctor                check the tools jimaku needs
  jimaku version               print the version
  jimaku help                  print this page

options:
  --language CODE              the subtitle language, an IETF code such as
                               en, pt-BR or es (default JIMAKU_LANGUAGE,
                               else asked on a terminal, else en)
  --force | --no-force         replace a subtitle that is already there, or
                               skip a video that has one (default yes)
  --hearing-impaired | --no-hearing-impaired
                               put subtitles for the hearing impaired first,
                               or last (default no)
  --dry-run                    list every video and download nothing

environment:
  JIMAKU_LANGUAGE              the subtitle language when --language is not
                               given, such as pt-BR

notes:
  subliminal searches the subtitle providers and saves each subtitle next to
  its video, named after it. jimaku then makes sure every subtitle beside the
  videos is UTF-8 without a byte order mark, converting the ones in Latin-1,
  Windows-1252 or UTF-16, so old players and TVs show accents right. A video
  with no subtitle found is named and makes the run fail. Hidden files and
  subfolders are left alone. Outside a terminal and without a target, jimaku
  works on the current folder. Without --language or JIMAKU_LANGUAGE, jimaku
  lists common languages on a terminal and asks for a number or a code, and
  uses en outside one. English is en: a region such as en-US matches no
  subtitle, since the providers list English without one. -- ends the
  options, and a folder named help, doctor or version is reached by giving
  its path, such as ./help.

examples:
  jimaku ~/Movies
  jimaku --language en "Night of the Living Dead (1968).mkv"
  jimaku --dry-run .
USAGE
}

jm_cli_hint() {
  jm_say 0 "${JM_PROG}: $1. run '${JM_PROG} help' for usage." >&2
}

jm_cli_version() {
  jm_version
  jm_cv_platform="$(uname -sr)" || jm_cv_platform="unknown"
  printf 'platform: %s\n' "${jm_cv_platform}"
}

jm_interactive() {
  [ "${JIMAKU_INTERACTIVE:-}" = 1 ] && return 0
  [ -t 0 ]
}

jm_prompt() {
  printf '%s [%s]: ' "$1" "$2" >&2
  jm_pr_answer=""
  IFS= read -r jm_pr_answer || [ -n "${jm_pr_answer}" ] || return 1
  printf '%s\n' "${jm_pr_answer:-$2}"
}
