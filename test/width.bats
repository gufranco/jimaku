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
  page="$(JIMAKU_TERMINAL=1 jm_test_run help)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "version never prints a line wider than 80 columns" {
  # Arrange
  local page widest

  # Act
  page="$(JIMAKU_TERMINAL=1 jm_test_run version)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "doctor never prints a line wider than 80 columns" {
  # Arrange
  local page widest

  # Act
  page="$(JIMAKU_TERMINAL=1 jm_test_run doctor || true)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "an error longer than 80 columns wraps between words" {
  # Arrange
  local message="the subtitle provider answered with a page that was not a subtitle, so nothing was saved for this video"

  # Act
  JIMAKU_TERMINAL=1 run jm_test_call jm_error "${message}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "${lines[0]}" == "jimaku: the subtitle provider answered with a page that was not a subtitle, so" ]]
  [[ "${lines[1]}" == "nothing was saved for this video" ]]
}

@test "an error sent to a pipe stays on one line, however long" {
  # Arrange
  local message="the subtitle provider answered with a page that was not a subtitle, so nothing was saved for this video"

  # Act
  run jm_test_call jm_error "${message}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "jimaku: ${message}" ]]
}

@test "a word wider than 80 columns stays whole on its own line" {
  # Arrange
  local folder="/Volumes/Archive/Films/The-Complete-Collection-Of-Every-Restored-Print-1968-To-1985"

  # Act
  JIMAKU_TERMINAL=1 run jm_test_call jm_say 8 "Videos: 3 in ${folder}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "Videos: 3 in" ]]
  [[ "${lines[1]}" == "        ${folder}" ]]
}

@test "a doctor row too wide for 80 columns puts its detail on the next line" {
  # Arrange
  local found="/opt/homebrew/opt/uutils-coreutils/libexec/uubin/sed"

  # Act
  JIMAKU_TERMINAL=1 run jm_test_call jm_doctor_row sed ok "${found}, uutils 0.12.0"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "sed                ok" ]]
  [[ "${lines[1]}" == "  ${found}, uutils 0.12.0" ]]
}

@test "a doctor row that fits in 80 columns stays on one line" {
  # Arrange
  local expected="file               ok       /usr/bin/file, bsd"

  # Act
  JIMAKU_TERMINAL=1 run jm_test_call jm_doctor_row file ok "/usr/bin/file, bsd"

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
