#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${JM_LIB:?}/state.sh"

# shellcheck disable=SC2034
jm_ui_set() {
  JM_UI_ACCENT="$1"
  JM_UI_OK="$2"
  JM_UI_WARN="$3"
  JM_UI_ERR="$4"
  JM_UI_MUTED="$5"
  JM_UI_TEXT="$6"
  JM_UI_SURFACE="$7"
  JM_UI_HELP="$8"
}

jm_ui_palette() {
  case "$1" in
  kodougu) jm_ui_set "#F25D94" "#50FA7B" "#FFB86C" "#FF5555" "#6C7086" "#CDD6F4" "#313244" pink ;;
  catppuccin-mocha) jm_ui_set "#CBA6F7" "#A6E3A1" "#FAB387" "#F38BA8" "#6C7086" "#CDD6F4" "#313244" dark ;;
  catppuccin-latte) jm_ui_set "#8839EF" "#40A02B" "#FE640B" "#D20F39" "#8C8FA1" "#4C4F69" "#CCD0DA" light ;;
  dracula) jm_ui_set "#BD93F9" "#50FA7B" "#FFB86C" "#FF5555" "#6272A4" "#F8F8F2" "#44475A" dracula ;;
  nord) jm_ui_set "#88C0D0" "#A3BE8C" "#EBCB8B" "#BF616A" "#4C566A" "#D8DEE9" "#3B4252" dark ;;
  gruvbox) jm_ui_set "#FE8019" "#B8BB26" "#FABD2F" "#FB4934" "#928374" "#EBDBB2" "#3C3836" dark ;;
  tokyo-night) jm_ui_set "#7AA2F7" "#9ECE6A" "#E0AF68" "#F7768E" "#565F89" "#C0CAF5" "#292E42" tokyo-night ;;
  mono) jm_ui_set "" "" "" "" "" "" "" ascii ;;
  *) return 1 ;;
  esac
}

jm_ui_is_colour() {
  case "$1" in
  \#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]) return 0 ;;
  *) return 1 ;;
  esac
}

# shellcheck disable=SC2034
jm_ui_setup() {
  if ! jm_ui_palette "${JM_THEME}"; then
    jm_ui_palette mono
    JM_UI_PROBLEM="--theme must be one of ${JM_UI_THEMES}, got: ${JM_THEME}"
    return 1
  fi
  if [ -n "${JM_ACCENT}" ] && ! jm_ui_is_colour "${JM_ACCENT}"; then
    JM_UI_PROBLEM="KODOUGU_ACCENT must be a colour such as #CBA6F7, got: ${JM_ACCENT}"
    return 1
  fi
  if [ -n "${JM_ACCENT}" ]; then
    JM_UI_ACCENT="${JM_ACCENT}"
  fi
  if [ -n "${NO_COLOR:-}" ]; then
    jm_ui_palette mono
  fi
}

jm_ui_forced() {
  [ "${JIMAKU_TEST_GUM:-}" = 1 ]
}

jm_ui_has_gum() {
  command -v gum >/dev/null 2>&1
}

jm_ui_prompts() {
  jm_ui_forced && return 0
  [ -t 0 ] && [ -t 2 ] && jm_ui_has_gum
}

jm_ui_err() {
  jm_ui_forced && return 0
  [ "${JM_UI_STEP}" = 1 ] && return 0
  [ -t 2 ] && jm_ui_has_gum
}

jm_ui_out() {
  jm_ui_forced && return 0
  [ -t 1 ] && jm_ui_has_gum
}

jm_gum() {
  if [ -n "${JM_UI_TEXT}" ]; then
    CLICOLOR_FORCE=1 gum "$@"
    return
  fi
  gum "$@"
}

jm_ui_ink() {
  jm_ui_colour="$1"
  shift
  if [ -z "${jm_ui_colour}" ]; then
    jm_gum style "$@"
    return
  fi
  jm_gum style --foreground "${jm_ui_colour}" "$@"
}

jm_ui_header() {
  jm_uh_name=$(jm_ui_ink "${JM_UI_ACCENT}" --bold -- "jimaku")
  jm_uh_number=$(jm_version | sed -n '1p')
  jm_uh_number="${jm_uh_number#jimaku }"
  jm_uh_version=$(jm_ui_ink "${JM_UI_MUTED}" -- "${jm_uh_number}")
  jm_uh_tagline=$(jm_ui_ink "${JM_UI_TEXT}" -- "${JM_TAGLINE}")
  jm_uh_top=$(jm_gum join --horizontal "${jm_uh_name}" "  " "${jm_uh_version}")
  jm_uh_body=$(jm_gum join --vertical "${jm_uh_top}" "${jm_uh_tagline}")
  printf '\n' >&2
  jm_gum style --border rounded --border-foreground "${JM_UI_ACCENT}" --padding "0 2" -- "${jm_uh_body}" >&2
  printf '\n' >&2
}

jm_ui_title() {
  printf '\n' >&2
  jm_ui_ink "${JM_UI_ACCENT}" --bold -- "$1" >&2
  printf '\n' >&2
}

jm_ui_titled() {
  if jm_ui_prompts; then
    jm_ui_title "$1"
  fi
}

jm_ui_lower_first() {
  printf '%s\n' "$1" | awk 'NR == 1 { a = substr($0, 1, 1); b = substr($0, 2, 1); if (a != tolower(a) && b != toupper(b)) { $0 = tolower(a) substr($0, 2) } } { print }'
}

jm_ui_log() {
  jm_ul_level="$1"
  jm_ul_text=$(jm_ui_lower_first "$2")
  case "${jm_ul_level}" in
  ERROR) jm_ul_colour="${JM_UI_ERR}" ;;
  WARN) jm_ul_colour="${JM_UI_WARN}" ;;
  *) jm_ul_colour="${JM_UI_OK}" ;;
  esac
  jm_ul_lines=$(printf '%s jimaku: %s\n' "${jm_ul_level}" "${jm_ul_text}" | jm_wrap 2)
  jm_ul_first=$(printf '%s\n' "${jm_ul_lines}" | sed -n '1p')
  jm_ul_rest=$(printf '%s\n' "${jm_ul_lines}" | sed '1d')
  jm_ul_label=$(jm_ui_ink "${jm_ul_colour}" --bold -- "${jm_ul_level}")
  printf '%s%s\n' "${jm_ul_label}" "${jm_ul_first#"${jm_ul_level}"}" >&2
  if [ -n "${jm_ul_rest}" ]; then
    printf '%s\n' "${jm_ul_rest}" >&2
  fi
}

jm_ui_choose() {
  jm_uc_header="$1"
  shift
  jm_gum choose --header "${jm_uc_header}" --cursor "> " --height 14 \
    --cursor.foreground "${JM_UI_ACCENT}" --selected.foreground "${JM_UI_ACCENT}" \
    --header.foreground "${JM_UI_TEXT}" "$@"
}

jm_ui_input() {
  jm_ui_header_text="$1"
  jm_ui_placeholder="$2"
  shift 2
  jm_gum input --header "${jm_ui_header_text}" --placeholder "${jm_ui_placeholder}" --prompt "> " \
    --prompt.foreground "${JM_UI_ACCENT}" --cursor.foreground "${JM_UI_ACCENT}" \
    --header.foreground "${JM_UI_TEXT}" --placeholder.foreground "${JM_UI_MUTED}" "$@"
}

jm_ui_write() {
  jm_gum write --header "$1" --placeholder "$2" --width 72 --height 8 --show-line-numbers \
    --cursor.foreground "${JM_UI_ACCENT}" --header.foreground "${JM_UI_TEXT}" \
    --placeholder.foreground "${JM_UI_MUTED}"
}

jm_ui_confirm() {
  jm_ucf_prompt="$1"
  jm_ucf_yes="$2"
  jm_ucf_no="$3"
  shift 3
  jm_gum confirm "${jm_ucf_prompt}" --affirmative "${jm_ucf_yes}" --negative "${jm_ucf_no}" \
    --prompt.foreground "${JM_UI_TEXT}" --selected.background "${JM_UI_ACCENT}" \
    --unselected.background "${JM_UI_SURFACE}" "$@"
}

jm_ui_summary() {
  jm_us2_pairs=$(($# / 2))
  while [ "${jm_us2_pairs}" -gt 0 ]; do
    jm_us2_label=$(printf '%-7s' "$1")
    jm_us2_label=$(jm_ui_ink "${JM_UI_MUTED}" -- "${jm_us2_label}")
    jm_us2_value=$(jm_ui_ink "${JM_UI_TEXT}" --bold -- "$2")
    shift 2
    set -- "$@" "${jm_us2_label} ${jm_us2_value}"
    jm_us2_pairs=$((jm_us2_pairs - 1))
  done
  printf '\n'
  jm_gum style --border rounded --border-foreground "${JM_UI_MUTED}" --padding "0 1" -- "$@"
  printf '\n'
}

jm_ui_spin() {
  jm_us_title="$1"
  jm_us_log="$2"
  shift 2
  (JM_UI_STEP=1 && "$@") 2>"${jm_us_log}" &
  jm_us_pid=$!
  if ! jm_ui_spin_wait "${jm_us_title}" "${jm_us_pid}"; then
    kill "${jm_us_pid}" 2>/dev/null
    exit 130
  fi
  jm_us_status=0
  wait "${jm_us_pid}" || jm_us_status=$?
  cat "${jm_us_log}" >&2
  return "${jm_us_status}"
}

jm_ui_spin_wait() {
  # shellcheck disable=SC2016
  jm_uw_loop='while kill -0 "$1" 2>/dev/null; do sleep 0.1; done'
  jm_gum spin --spinner dot --spinner.foreground "${JM_UI_ACCENT}" --title.foreground "${JM_UI_TEXT}" --title "$1" -- sh -c "${jm_uw_loop}" _ "$2" >&2
}

jm_ui_table() {
  jm_ut_line="-"
  if [ -n "${JM_UI_TEXT}" ]; then
    jm_ut_line=$(printf '\342\224\200')
  fi
  jm_ut_body=$(jm_ui_table_body "${jm_ut_line}")
  jm_gum style --border rounded --border-foreground "${JM_UI_MUTED}" --padding "0 1" -- "${jm_ut_body}"
}

jm_ui_table_body() {
  awk -F '\t' -v acc="${JM_UI_ACCENT}" -v ok="${JM_UI_OK}" -v warn="${JM_UI_WARN}" \
    -v bad="${JM_UI_ERR}" -v txt="${JM_UI_TEXT}" -v mut="${JM_UI_MUTED}" -v dash="$1" \
    -f "${JM_LIB}/table.awk"
}

jm_ui_done() {
  printf '\n'
  jm_ui_ink "${JM_UI_OK}" --bold -- "$1"
}

jm_ui_badge() {
  jm_ub_colour="$1"
  shift
  if [ -z "${jm_ub_colour}" ]; then
    jm_gum style --bold --underline --padding "0 1" -- "$*"
    return
  fi
  jm_gum style --background "${jm_ub_colour}" --foreground "#1E1E2E" --bold --padding "0 1" -- "$*"
}

jm_ui_chip() {
  if [ -z "${JM_UI_SURFACE}" ]; then
    jm_gum style --padding "0 1" -- "$1"
    return
  fi
  jm_gum style --background "${JM_UI_SURFACE}" --foreground "${JM_UI_TEXT}" --padding "0 1" -- "$1"
}

jm_ui_danger() {
  jm_ud_title=$(jm_ui_ink "${JM_UI_ERR}" --bold -- "$1")
  shift
  jm_gum style --border thick --border-foreground "${JM_UI_ERR}" --padding "0 1" -- "${jm_ud_title}" "$@" >&2
}

jm_ui_markdown() {
  awk '
    NR == 1 {
      split($0, head, " - ")
      printf "# %s\n\n%s\n", head[1], head[2]
      next
    }
    /^[a-z][a-z ]*:$/ {
      if (open) { print "```" }
      printf "\n## %s\n\n```text\n", toupper(substr($0, 1, 1)) substr($0, 2, length($0) - 2)
      open = 1
      next
    }
    { print }
    END { if (open) { print "```" } }
  '
}
