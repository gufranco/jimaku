#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/jm-golden.XXXXXX")"
  WORK="$(cd "${WORK}" && pwd -P)"
  unset JIMAKU_LANGUAGE
  FILMS="${WORK}/films"
  mkdir -p "${FILMS}"
  export JIMAKU_FAKE_LOG="${WORK}/calls.log"
  jm_test_fake_subliminal
}

teardown() {
  rm -rf "${WORK}"
}

@test "a folder run prints the same transcript as the recorded one" {
  # Arrange
  : >"${FILMS}/a.mkv"
  : >"${FILMS}/b.mkv"
  : >"${FILMS}/gone.mkv"
  printf 'caf\351\n' >"${FILMS}/old.srt"
  export JIMAKU_FAKE_NONE=gone

  # Act
  run jm_test_run --language pt-BR "${FILMS}"

  # Assert
  [[ "${status}" -eq 1 ]]
  jm_test_matches_golden folder "${output}"
}

@test "a dry run prints the same transcript as the recorded one" {
  # Arrange
  : >"${FILMS}/a.mkv"
  : >"${FILMS}/b.mkv"

  # Act
  run jm_test_run --dry-run --no-force "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  jm_test_matches_golden dry-run "${output}"
}
