#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d /tmp/jm-width.XXXXXX)"
  WORK="$(cd "${WORK}" && pwd -P)"
  unset JIMAKU_LANGUAGE
  jm_test_fake_subliminal
}

teardown() {
  rm -rf "${WORK}"
}

widest_line() {
  awk '{ if (length($0) > widest) { widest = length($0) } } END { print widest + 0 }'
}

@test "help never prints a line wider than 80 columns" {
  # Arrange
  local page widest

  # Act
  page="$(jm_test_run help)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "version never prints a line wider than 80 columns" {
  # Arrange
  local page widest

  # Act
  page="$(jm_test_run version)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "an error stays on one line, however long" {
  # Arrange
  local message="the subtitle provider answered with a page that was not a subtitle, so nothing was saved for this video"

  # Act
  run jm_test_call jm_error "${message}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "jimaku: ${message}" ]]
}

@test "a doctor row stays on one line, however long" {
  # Arrange
  local expected="sed                ok       /opt/homebrew/opt/gnu-sed/libexec/gnubin/sed, gnu 4.10"

  # Act
  run jm_test_call jm_doctor_row "sed" ok "/opt/homebrew/opt/gnu-sed/libexec/gnubin/sed, gnu 4.10"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "internal JM_ variables from the environment change nothing" {
  # Arrange
  local films="${WORK}/films"
  mkdir -p "${films}"
  : >"${films}/Carnival of Souls (1962).mkv"

  # Act
  JM_LANGUAGE=xx JM_DEFAULT_LANGUAGE=fr JM_FORCE=no run jm_test_run --dry-run "${films}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Plan:   en subtitles, saved as UTF-8 next to each video"* ]]
  [[ "${output}" == *"any subtitle already there is replaced"* ]]
  [[ "${output}" == *"Dry run: 1 video would get a subtitle in en. Nothing was downloaded."* ]]
}
