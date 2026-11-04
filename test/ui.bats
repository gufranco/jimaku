#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/jm-ui.XXXXXX")"
  WORK="$(cd "${WORK}" && pwd -P)"
  unset JIMAKU_LANGUAGE KODOUGU_THEME KODOUGU_ACCENT JIMAKU_THEME NO_COLOR
  FILMS="${WORK}/films"
  mkdir -p "${FILMS}"
  : >"${FILMS}/Charade (1963).mkv"
  : >"${FILMS}/Nosferatu (1922).mkv"
  export JIMAKU_FAKE_LOG="${WORK}/calls.log"
  export JIMAKU_TEST_GUM=1
  export JIMAKU_TEST_GUM_LOG="${WORK}/gum.log"
  export JIMAKU_TEST_GUM_ANSWERS="${WORK}/answers"
  export JIMAKU_INTERACTIVE=1
  : >"${JIMAKU_TEST_GUM_LOG}"
  jm_test_fake_subliminal
}

teardown() {
  rm -rf "${WORK}"
}

answers() {
  printf '%s\n' "$@" >"${JIMAKU_TEST_GUM_ANSWERS}"
}

called() {
  grep -q -F -- "$1" "${JIMAKU_TEST_GUM_LOG}"
}

@test "the folder and language are asked for with gum, then fetched after a yes" {
  # Arrange
  answers "${FILMS}" "pt-BR" "yes"

  # Act
  run jm_test_run </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${FILMS}/Charade (1963).pt-BR.srt" ]]
  [[ "${output}" == *"download subtitles for videos and save them as UTF-8"* ]]
  [[ "${output}" == *"Saved pt-BR subtitles for 2 videos."* ]]
  called "input --header Folder or video"
  called "choose --header Subtitle language"
  called "spin --spinner dot"
}

@test "an empty folder answer fetches for the current folder" {
  # Arrange
  answers "" "pt-BR" "yes"
  cd "${FILMS}"

  # Act
  run jm_test_run </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${FILMS}/Charade (1963).pt-BR.srt" ]]
  called "--placeholder ${FILMS}"
}

@test "another language is typed as a code" {
  # Arrange
  answers "other" "nl" "yes"

  # Act
  run jm_test_run "${FILMS}" </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${FILMS}/Charade (1963).nl.srt" ]]
}

@test "a typed code that is not a language is asked for again" {
  # Arrange
  answers "other" "not a code" "en" "yes"

  # Act
  run jm_test_run "${FILMS}" </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"ERROR jimaku: 'not a code' is not a language code such as pt-BR or en."* ]]
  [[ -f "${FILMS}/Charade (1963).en.srt" ]]
}

@test "three bad codes stop the run" {
  # Arrange
  answers "other" "1" "other" "2" "other" "3"

  # Act
  run jm_test_run "${FILMS}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"no language was chosen"* ]]
}

@test "a cancelled language choice stops the run" {
  # Arrange
  answers "<cancel>"

  # Act
  run jm_test_run "${FILMS}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "a no at the confirmation downloads nothing" {
  # Arrange
  answers "no"

  # Act
  run jm_test_run --language en "${FILMS}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ ! -f "${FILMS}/Charade (1963).en.srt" ]]
  [[ "${output}" == *"ERROR jimaku: stopped: nothing was downloaded."* ]]
}

@test "a dry run shows the summary and asks nothing" {
  # Arrange
  answers "<cancel>"

  # Act
  run jm_test_run --dry-run --language en --no-force "${FILMS}" </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"dry run, nothing is downloaded"* ]]
  [[ "${output}" == *"Nothing was downloaded."* ]]
}

@test "one video summarises as a video" {
  # Arrange
  answers "yes"

  # Act
  run jm_test_run --language en --no-force "${FILMS}/Charade (1963).mkv" </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"skip a video that has one"* ]]
  [[ "${output}" == *"Saved en subtitles for 1 video."* ]]
}

@test "a video with no subtitle makes the closing line a warning" {
  # Arrange
  answers "yes"

  # Act
  JIMAKU_FAKE_NONE="Nosferatu" run jm_test_run --language en "${FILMS}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"WARN jimaku: no en subtitle found for"* ]]
  [[ "${output}" == *"WARN jimaku: saved en subtitles for 1 of 2 videos."* ]]
}

@test "no saved subtitle at all is a warning" {
  # Arrange
  answers "yes"

  # Act
  JIMAKU_FAKE_NONE=".mkv" run jm_test_run --language en "${FILMS}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"WARN jimaku: no en subtitle was saved."* ]]
}

@test "a failing subliminal under the spinner is reported" {
  # Arrange
  answers "yes"

  # Act
  JIMAKU_FAKE_FAIL="Charade" run jm_test_run --language en "${FILMS}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"ERROR jimaku: subliminal failed for"* ]]
}

@test "doctor draws its rows in a table" {
  # Arrange
  local expected="Ready. Every tool jimaku needs is here."

  # Act
  run jm_test_run doctor </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${expected}"* ]]
}

@test "doctor reports a missing tool below the table" {
  # Arrange
  local farm
  farm="$(jm_test_farm iconv)"

  # Act
  run jm_test_run_path "${farm}" doctor </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"ERROR jimaku: a required tool is missing."* ]]
}

@test "doctor fails without gum" {
  # Arrange
  local farm
  farm="$(jm_test_farm gum)"

  # Act
  JIMAKU_TEST_GUM=0 run jm_test_run_path "${farm}" doctor </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"gum                missing  install with: brew install gum"* ]]
}

@test "version shows the version and platform as badges" {
  # Arrange
  local version
  version="$(sed -n 's/^JIMAKU_VERSION="\(.*\)"$/\1/p' "${REPO_DIR}/lib/core.sh")"

  # Act
  run jm_test_run version </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "jimaku ${version} platform "* ]]
}

@test "help is formatted with gum" {
  # Arrange
  local expected="## Usage"

  # Act
  run jm_test_run help </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${expected}"* ]]
  called "format --theme pink"
}

@test "--theme picks the palette over the environment" {
  # Arrange
  local theme="nord"

  # Act
  KODOUGU_THEME=dracula JIMAKU_THEME=gruvbox run jm_test_run --theme "${theme}" version </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  called "--background #88C0D0"
}

@test "--theme= with a value picks the palette" {
  # Arrange
  local option="--theme=tokyo-night"

  # Act
  run jm_test_run "${option}" version </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  called "--background #7AA2F7"
}

@test "an unknown theme stops before anything runs" {
  # Arrange
  local theme="solarized"

  # Act
  KODOUGU_THEME="${theme}" run jm_test_run --language en "${FILMS}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"got: solarized"* ]]
}

@test "--theme without a value stops with the usage hint" {
  # Arrange
  local option="--theme"

  # Act
  run jm_test_run version "${option}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"option '--theme' needs a value. run 'jimaku help' for usage."* ]]
}

@test "--theme after -- names a video folder" {
  # Arrange
  mkdir -p "${WORK}/--theme"

  # Act
  run from_work jm_test_run --dry-run --language en -- --theme </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"No videos in --theme."* ]]
}

from_work() {
  (cd "${WORK}" && "$@")
}
