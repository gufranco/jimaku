#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

bats_require_minimum_version 1.5.0

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/jm-json.XXXXXX")"
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

@test "--json prints each video and the subtitles a run saved as one JSON object" {
  # Arrange
  : >"${FILMS}/a.mkv"
  : >"${FILMS}/b.mkv"
  local expected="{\"language\":\"en\",\"dry_run\":false,\"found\":2,\"saved\":2,\"missed\":0,\"failed\":0,\"videos\":[{\"video\":\"${FILMS}/a.mkv\",\"result\":\"saved\"},{\"video\":\"${FILMS}/b.mkv\",\"result\":\"saved\"}]}"

  # Act
  run jm_test_run --json "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
  [[ -f "${FILMS}/a.en.srt" ]]
}

@test "--json with --dry-run lists the videos as planned and downloads nothing" {
  # Arrange
  : >"${FILMS}/a.mkv"
  local expected="{\"language\":\"pt-BR\",\"dry_run\":true,\"found\":1,\"saved\":0,\"missed\":0,\"failed\":0,\"videos\":[{\"video\":\"${FILMS}/a.mkv\",\"result\":\"planned\"}]}"

  # Act
  run jm_test_run --json --dry-run --language pt-BR "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
  [[ ! -e "${JIMAKU_FAKE_LOG}" ]]
}

@test "--json names a video with no subtitle and one subliminal failed on, and the run fails" {
  # Arrange
  : >"${FILMS}/gone.mkv"
  : >"${FILMS}/broken.mkv"
  export JIMAKU_FAKE_NONE=gone JIMAKU_FAKE_FAIL=broken
  local expected="{\"language\":\"en\",\"dry_run\":false,\"found\":2,\"saved\":0,\"missed\":1,\"failed\":1,\"videos\":[{\"video\":\"${FILMS}/broken.mkv\",\"result\":\"failed\"},{\"video\":\"${FILMS}/gone.mkv\",\"result\":\"missed\"}]}"

  # Act
  run --separate-stderr jm_test_run --json "${FILMS}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
  [[ "${stderr}" == *"jimaku: warning: no en subtitle found for ${FILMS}/gone.mkv."* ]]
}

@test "--json on a folder with no videos reports zero videos" {
  # Arrange
  local expected="{\"language\":\"en\",\"dry_run\":false,\"found\":0,\"saved\":0,\"missed\":0,\"failed\":0,\"videos\":[]}"

  # Act
  run jm_test_run --json --language en "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "--json escapes a quote and a backslash in a video name" {
  # Arrange
  local name='say "hi" \ now.mkv'
  : >"${FILMS}/${name}"
  local expected="{\"language\":\"en\",\"dry_run\":true,\"found\":1,\"saved\":0,\"missed\":0,\"failed\":0,\"videos\":[{\"video\":\"${FILMS}/say \\\"hi\\\" \\\\ now.mkv\",\"result\":\"planned\"}]}"

  # Act
  run jm_test_run --json --dry-run "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
}
