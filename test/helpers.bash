#!/usr/bin/env bash

JIMAKU_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${JIMAKU_TESTS_DIR}/.." && pwd)"
export JIMAKU_TESTS_DIR REPO_DIR

jm_test_path() {
  if [[ -n "${SHIMS:-}" && -d "${SHIMS}" ]]; then
    printf '%s:%s\n' "${SHIMS}" "${PATH}"
  else
    printf '%s\n' "${PATH}"
  fi
}

jm_test_shim() {
  local name="$1"
  local body="$2"
  local real
  SHIMS="${SHIMS:-${WORK:?}/shims}"
  mkdir -p "${SHIMS}"
  real="$(command -v "${name}" || true)"
  printf '#!/bin/sh\n{ set +x; } 2>/dev/null\nREAL=%q\n%s\n' "${real}" "${body}" >"${SHIMS}/${name}"
  chmod +x "${SHIMS}/${name}"
  export SHIMS
}

jm_test_run() {
  local search_path
  local -a shell_words
  search_path="$(jm_test_path)"
  read -r -a shell_words <<<"${JIMAKU_TEST_SHELL:-sh}"
  PATH="${search_path}" "${shell_words[@]}" "${REPO_DIR}/bin/jimaku" "$@"
}

jm_test_run_path() {
  local search_path="$1"
  local -a shell_words
  shift
  read -r -a shell_words <<<"${JIMAKU_TEST_SHELL:-sh}"
  PATH="${search_path}" "${shell_words[@]}" "${REPO_DIR}/bin/jimaku" "$@"
}

jm_test_call() {
  local search_path
  local -a shell_words
  search_path="$(jm_test_path)"
  read -r -a shell_words <<<"${JIMAKU_TEST_SHELL:-sh}"
  PATH="${search_path}" "${shell_words[@]}" "${JIMAKU_TESTS_DIR}/call.sh" "$@"
}

jm_test_farm() {
  local farm="${WORK:?}/farm"
  local dir tool name excluded
  local -a dirs
  mkdir -p "${farm}"
  IFS=: read -r -a dirs <<<"${PATH}"
  for dir in "${dirs[@]}"; do
    [[ -d "${dir}" ]] || continue
    for tool in "${dir}"/*; do
      name="${tool##*/}"
      [[ -x "${tool}" && ! -e "${farm}/${name}" ]] || continue
      for excluded in "$@"; do
        [[ "${name}" == "${excluded}" ]] && continue 2
      done
      ln -s "${tool}" "${farm}/${name}"
    done
  done
  printf '%s\n' "${farm}"
}

jm_test_files() {
  local dir="$1"
  local name
  shift
  mkdir -p "${dir}"
  for name in "$@"; do
    printf '%s\n' "${name}" >"${dir}/${name}"
  done
}

jm_test_tree() {
  local listing
  listing="$(cd "$1" && find . -mindepth 1)" || return 1
  LC_ALL=C sort <<<"${listing}"
}

jm_test_fake_subliminal() {
  SHIMS="${SHIMS:-${WORK:?}/shims}"
  mkdir -p "${SHIMS}"
  cp -f "${JIMAKU_TESTS_DIR}/fake-subliminal.sh" "${SHIMS}/subliminal"
  chmod +x "${SHIMS}/subliminal"
  export SHIMS
}

jm_test_bytes() {
  local dump
  dump="$(od -An -tx1 -v "$1")" || return 1
  tr -d ' \n' <<<"${dump}"
}

jm_test_matches_golden() {
  local name="$1"
  local actual="$2"
  local os golden normalized
  os="$(uname -s)"
  golden="${JIMAKU_TESTS_DIR}/golden/${name}.${os}.txt"
  normalized="${actual//"${WORK}"/WORK}"
  if [[ "${JIMAKU_TEST_RECORD:-}" == "1" ]]; then
    mkdir -p "${JIMAKU_TESTS_DIR}/golden"
    printf '%s\n' "${normalized}" >"${golden}"
  fi
  diff <(printf '%s\n' "${normalized}") "${golden}"
}
