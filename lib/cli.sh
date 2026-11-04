#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

jm_usage() {
  if jm_ui_out; then
    jm_usage_text | jm_ui_markdown | jm_gum format --theme "${JM_UI_HELP}"
    return 0
  fi
  jm_usage_text
}

jm_usage_text() {
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
  --json                       print the result as one JSON object, for scripts
  --theme NAME                 colours of the terminal interface, see notes

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

  On a terminal with gum installed, jimaku draws its prompts, summary and
  results with gum. --theme, else JIMAKU_THEME, else KODOUGU_THEME picks the
  colours: kodougu, catppuccin-mocha, catppuccin-latte, dracula, nord,
  gruvbox, tokyo-night or mono. KODOUGU_ACCENT=#RRGGBB replaces only the
  accent, and NO_COLOR turns colour off.

examples:
  jimaku ~/Movies
  jimaku --language en "Night of the Living Dead (1968).mkv"
  jimaku --dry-run .
USAGE
}

jm_cli_hint() {
  jm_error "$1. run '${JM_PROG} help' for usage."
}

jm_cli_version() {
  jm_cv_platform="$(uname -sr)" || jm_cv_platform="unknown"
  if jm_ui_out; then
    jm_cv_text="$(jm_version)"
    jm_cv_badge="$(jm_ui_badge "${JM_UI_ACCENT}" "${jm_cv_text}")"
    jm_cv_chip="$(jm_ui_chip "platform ${jm_cv_platform}")"
    jm_gum join --horizontal "${jm_cv_badge}" " " "${jm_cv_chip}"
    return 0
  fi
  jm_version
  printf 'platform: %s\n' "${jm_cv_platform}"
}

jm_interactive() {
  [ "${JIMAKU_INTERACTIVE:-}" = 1 ] && return 0
  [ -t 0 ]
}

jm_prompt() {
  if jm_ui_prompts; then
    jm_pd_answer="$(jm_ui_input "$1" "$2")" || return 1
    printf '%s\n' "${jm_pd_answer:-$2}"
    return 0
  fi
  printf '%s [%s]: ' "$1" "$2" >&2
  jm_pr_answer=""
  IFS= read -r jm_pr_answer || [ -n "${jm_pr_answer}" ] || return 1
  printf '%s\n' "${jm_pr_answer:-$2}"
}
