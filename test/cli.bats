#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/jm-cli.XXXXXX")"
  WORK="$(cd "${WORK}" && pwd -P)"
  unset JIMAKU_LANGUAGE JM_LANGUAGE
  jm_test_fake_subliminal
}

teardown() {
  rm -rf "${WORK}"
}

@test "help prints the usage page" {
  # Arrange
  local first="jimaku - download subtitles for videos and save them as UTF-8"

  # Act
  run jm_test_run help

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "${first}" ]]
}

@test "-h and --help print the same page as help" {
  # Arrange
  local page
  page="$(jm_test_run help)"

  # Act
  run jm_test_run -h

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${page}" ]]
  [[ "$(jm_test_run --help || true)" == "${page}" ]]
}

@test "version prints the program, its version and the platform" {
  # Arrange
  local platform
  platform="$(uname -sr)"

  # Act
  run jm_test_run --version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" =~ ^jimaku\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
  [[ "${lines[1]}" == "platform: ${platform}" ]]
}

@test "version and -V print the same lines" {
  # Arrange
  local expected
  expected="$(jm_test_run --version)"

  # Act
  run jm_test_run version

  # Assert
  [[ "${output}" == "${expected}" ]]
  [[ "$(jm_test_run -V || true)" == "${expected}" ]]
}

@test "version reports an unknown platform when uname fails" {
  # Arrange
  jm_test_shim uname "exit 1"

  # Act
  run jm_test_run --version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" == "platform: unknown" ]]
}

@test "doctor lists subliminal with its version and the text tools with their paths" {
  # Arrange
  local iconv_path
  iconv_path="$(command -v iconv)"

  # Act
  run jm_test_run doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "subliminal         ok       ${SHIMS}/subliminal, 2.8.0" ]]
  [[ "${lines[1]}" == "file               ok       "* ]]
  [[ "${lines[2]}" == "iconv              ok       ${iconv_path}, "* ]]
  [[ "${lines[3]}" == "sed                ok       "* ]]
  [[ "${lines[4]}" == "awk                ok       "* ]]
}

@test "doctor fails and says how to install a missing subliminal" {
  # Arrange
  local farm
  farm="$(jm_test_farm subliminal)"

  # Act
  run jm_test_run_path "${farm}" doctor

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${lines[0]}" == "subliminal         missing  required: brew install subliminal, or apt install subliminal" ]]
}

@test "doctor fails and names a missing iconv" {
  # Arrange
  local farm
  farm="$(jm_test_farm iconv)"

  # Act
  run jm_test_run_path "${SHIMS}:${farm}" doctor

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${lines[2]}" == "iconv              missing  required" ]]
}

@test "the tool runs by its bare name from inside its own folder" {
  # Arrange
  local -a shell_words
  read -r -a shell_words <<<"${JM_SHELL:-sh}"
  cd "${REPO_DIR}/bin" || return 1

  # Act
  PATH="${REPO_DIR}/bin:${PATH}" run "${shell_words[@]}" jimaku version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" =~ ^jimaku\ [0-9] ]]
}

@test "an unknown option is named with a hint" {
  # Arrange
  local option="--frobnicate"

  # Act
  run jm_test_run "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "jimaku: unknown option '--frobnicate'. run 'jimaku help' for usage." ]]
}

@test "an unknown short option is named with a hint" {
  # Arrange
  local option="-x"

  # Act
  run jm_test_run "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "jimaku: unknown option '-x'. run 'jimaku help' for usage." ]]
}

@test "a value given to a switch is refused" {
  # Arrange
  local option="--dry-run=yes"

  # Act
  run jm_test_run "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "jimaku: unknown option '--dry-run'. run 'jimaku help' for usage." ]]
}

@test "--language at the end without a value is refused" {
  # Arrange
  local option="--language"

  # Act
  run jm_test_run "${WORK}" "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "jimaku: option '--language' needs a value. run 'jimaku help' for usage." ]]
}

@test "--language followed by another option is refused" {
  # Arrange
  local option="--language"

  # Act
  run jm_test_run "${option}" --dry-run

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "jimaku: option '--language' needs a value. run 'jimaku help' for usage." ]]
}

@test "a language that is not a language code is refused" {
  # Arrange
  local code="pt_BR"

  # Act
  run jm_test_run --language="${code}" "${WORK}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "jimaku: 'pt_BR' is not a language code such as pt-BR or en. run 'jimaku help' for usage." ]]
}

@test "a language with a bad region is refused" {
  # Arrange
  local code="pt-B!"

  # Act
  run jm_test_run --language "${code}" "${WORK}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "jimaku: 'pt-B!' is not a language code such as pt-BR or en. run 'jimaku help' for usage." ]]
}

@test "an empty video or folder name is refused" {
  # Arrange
  local empty=""

  # Act
  run jm_test_run "${empty}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "jimaku: the video or folder name is empty. run 'jimaku help' for usage." ]]
}

@test "a missing video or folder stops the run before anything is fetched" {
  # Arrange
  mkdir -p "${WORK}/films"
  : >"${WORK}/films/a.mkv"
  export FAKE_LOG="${WORK}/calls.log"

  # Act
  run jm_test_run "${WORK}/films" "${WORK}/gone"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "jimaku: no such video or folder: ${WORK}/gone" ]]
  [[ ! -e "${FAKE_LOG}" ]]
}

@test "-- ends the options so a video may start with a dash" {
  # Arrange
  mkdir -p "${WORK}/films"
  : >"${WORK}/films/-odd.mkv"
  cd "${WORK}/films" || return 1

  # Act
  run jm_test_run --dry-run -- -odd.mkv

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Video:  -odd.mkv"* ]]
}

@test "a folder named like a command is reached by its path" {
  # Arrange
  mkdir -p "${WORK}/help"
  : >"${WORK}/help/a.mkv"
  cd "${WORK}" || return 1

  # Act
  run jm_test_run --dry-run ./help

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Videos: 1 in ./help"* ]]
}

help_options() {
  local page
  page="$(jm_test_run help)" || return 1
  awk '/^  --/ { for (i = 1; i <= NF; i++) if (match($i, /^--[a-z0-9][a-z0-9-]*/)) { name = substr($i, RSTART, RLENGTH); if (!seen[name]++) print name } }' <<<"${page}"
}

option_drift() {
  local option name man_form missing="" listed completed
  listed="$(help_options)" || return 1
  completed="$(grep -oE -- "--[a-z0-9][a-z0-9-]*" "${REPO_DIR}/completions/jimaku.bash")" || return 1
  for option in ${listed}; do
    name="${option#--}"
    man_form="\\-\\-${name//-/\\-}"
    grep -qF -- "${man_form}" "${REPO_DIR}/man/jimaku.1" || missing="${missing} man:${option}"
    grep -qE -- "(^|[ \"])${option}( |\"|$)" "${REPO_DIR}/completions/jimaku.bash" || missing="${missing} bash:${option}"
    grep -qE -- "[')]${option}[=\\[]" "${REPO_DIR}/completions/_jimaku" || missing="${missing} zsh:${option}"
    grep -qE -- "-l ${name} " "${REPO_DIR}/completions/jimaku.fish" || missing="${missing} fish:${option}"
  done
  for option in ${completed}; do
    grep -qx -- "${option}" <<<"${listed}" || missing="${missing} help:${option}"
  done
  printf '%s' "${missing}"
}

@test "help, man page and completions list the same options" {
  # Arrange
  local expected=""

  # Act
  run option_drift

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "the man page passes mandoc lint" {
  # Arrange
  local page="${REPO_DIR}/man/jimaku.1"

  # Act
  run mandoc -T lint "${page}"

  # Assert
  [[ "${status}" -eq 0 ]]
}
