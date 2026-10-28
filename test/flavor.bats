#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/jm-flavor.XXXXXX")"
}

teardown() {
  rm -rf "${WORK}"
}

fake_tool() {
  local path="$1"
  local text="$2"
  mkdir -p "${path%/*}"
  printf '#!/bin/sh\n{ set +x; } 2>/dev/null\nprintf "%%s\\n" "%s"\nexit 1\n' "${text}" >"${path}"
  chmod +x "${path}"
  printf '%s\n' "${path}"
}

flavor_of() {
  local tool
  tool="$(fake_tool "${WORK}/bin/$1" "$2")"
  JM_OS="${3:-Darwin}" jm_test_call jm_tool_flavor "${tool}"
}

@test "GNU coreutils reads as gnu with its version" {
  # Arrange
  local text="mv (GNU coreutils) 9.5"

  # Act
  run flavor_of mv "${text}"

  # Assert
  [[ "${output}" == "gnu 9.5" ]]
}

@test "Ubuntu's GNU coreutils without the GNU word reads as gnu" {
  # Arrange
  local text="mv (coreutils) 9.7"

  # Act
  run flavor_of mv "${text}" Linux

  # Assert
  [[ "${output}" == "gnu 9.7" ]]
}

@test "uutils coreutils reads as uutils with its version" {
  # Arrange
  local text="mv (uutils coreutils) 0.12.0"

  # Act
  run flavor_of mv "${text}"

  # Assert
  [[ "${output}" == "uutils 0.12.0" ]]
}

@test "mawk reads as mawk" {
  # Arrange
  local text="mawk 1.3.4 20260129"

  # Act
  run flavor_of awk "${text}" Linux

  # Assert
  [[ "${output}" == "mawk 1.3.4" ]]
}

@test "the BSD awk reads as bsd with its date stamp" {
  # Arrange
  local text="awk version 20200816"

  # Act
  run flavor_of awk "${text}"

  # Assert
  [[ "${output}" == "bsd 20200816" ]]
}

@test "BusyBox reads as busybox" {
  # Arrange
  local text="BusyBox v1.36.1 (2024-06-10) multi-call binary."

  # Act
  run flavor_of mkdir "${text}" Linux

  # Assert
  [[ "${output}" == "busybox 1.36.1" ]]
}

@test "a tool that refuses --version on macOS reads as bsd" {
  # Arrange
  local text="mv: illegal option -- -"

  # Act
  run flavor_of mv "${text}" Darwin

  # Assert
  [[ "${output}" == "bsd" ]]
}

@test "a tool that refuses --version on FreeBSD reads as bsd" {
  # Arrange
  local text="mv: illegal option -- -"

  # Act
  run flavor_of mv "${text}" FreeBSD

  # Assert
  [[ "${output}" == "bsd" ]]
}

@test "a tool that refuses --version on Linux reads as unknown" {
  # Arrange
  local text="usage: mv source target"

  # Act
  run flavor_of mv "${text}" Linux

  # Assert
  [[ "${output}" == "unknown" ]]
}

@test "a uutils tool that refuses --version is named by where it lives" {
  # Arrange
  local tool
  tool="$(fake_tool "${WORK}/uutils-coreutils/uubin/mv" "unrecognized option '--version'")"

  # Act
  JM_OS=Darwin run jm_test_call jm_tool_flavor "${tool}"

  # Assert
  [[ "${output}" == "uutils" ]]
}

@test "the host system decides when JM_OS is not set" {
  # Arrange
  local tool expected=unknown
  tool="$(fake_tool "${WORK}/bin/mv" "usage: mv source target")"
  [[ "$(uname -s || true)" != Darwin ]] || expected=bsd

  # Act
  run jm_test_call jm_tool_flavor "${tool}"

  # Assert
  [[ "${output}" == "${expected}" ]]
}
