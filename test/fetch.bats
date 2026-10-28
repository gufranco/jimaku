#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/jm-fetch.XXXXXX")"
  WORK="$(cd "${WORK}" && pwd -P)"
  unset JIMAKU_LANGUAGE JM_LANGUAGE
  FILMS="${WORK}/films"
  mkdir -p "${FILMS}"
  export FAKE_LOG="${WORK}/calls.log"
  jm_test_fake_subliminal
}

teardown() {
  rm -rf "${WORK}"
}

videos() {
  local name
  for name in "$@"; do
    : >"${FILMS}/${name}"
  done
}

subtitle_source() {
  # shellcheck disable=SC2059
  printf "$1" >"${WORK}/source.srt"
  export FAKE_SOURCE="${WORK}/source.srt"
}

download_calls() {
  grep '^download -l' "${FAKE_LOG}"
}

@test "a single video gets an English subtitle by default, saved as UTF-8 next to it" {
  # Arrange
  videos "Night of the Living Dead (1968).mkv"

  # Act
  run jm_test_run "${FILMS}/Night of the Living Dead (1968).mkv"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == $'\n'"Video:  ${FILMS}/Night of the Living Dead (1968).mkv"$'\n'"Plan:   en subtitles, saved as UTF-8 next to each video"$'\n'"        any subtitle already there is replaced"$'\n\n'"${FILMS}/Night of the Living Dead (1968).mkv: saved a subtitle in en."$'\n'"Saved en subtitles for 1 video." ]]
  [[ -f "${FILMS}/Night of the Living Dead (1968).en.srt" ]]
}

@test "subliminal is asked for the language, UTF-8, a forced download and plain subtitles first" {
  # Arrange
  videos a.mkv

  # Act
  run jm_test_run "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  run download_calls
  [[ "${output}" == "download -l en -e utf-8 -f -C n,fo,hi -- ${FILMS}/a.mkv" ]]
}

@test "--language, --no-force and --hearing-impaired change what subliminal is asked" {
  # Arrange
  videos a.mkv

  # Act
  run jm_test_run --language pt-BR --no-force --hearing-impaired "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Plan:   pt-BR subtitles, saved as UTF-8 next to each video"$'\n'"        a video that already has one is skipped"$'\n'"        subtitles for the hearing impaired come first"* ]]
  run download_calls
  [[ "${output}" == "download -l pt-BR -e utf-8 -C hi,n,fo -- ${FILMS}/a.mkv" ]]
}

@test "an older subliminal without subtitle categories gets -hi for the hearing impaired" {
  # Arrange
  videos a.mkv

  # Act
  FAKE_CATEGORIES=no run jm_test_run --language=es --force --hearing-impaired "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  run download_calls
  [[ "${output}" == "download -l es -e utf-8 -f -hi -- ${FILMS}/a.mkv" ]]
}

@test "an older subliminal without subtitle categories gets no preference by default" {
  # Arrange
  videos a.mkv

  # Act
  FAKE_CATEGORIES=no run jm_test_run --no-hearing-impaired "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  run download_calls
  [[ "${output}" == "download -l en -e utf-8 -f -- ${FILMS}/a.mkv" ]]
}

@test "a folder fetches for each video in it and leaves other files, hidden files and subfolders alone" {
  # Arrange
  videos b.MP4 a.mkv notes.txt .hidden.mkv
  mkdir -p "${FILMS}/extras.mkv"

  # Act
  run jm_test_run "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Videos: 2 in ${FILMS}"* ]]
  [[ "${output}" == *"Saved en subtitles for 2 videos." ]]
  run download_calls
  [[ "${output}" == "download -l en -e utf-8 -f -C n,fo,hi -- ${FILMS}/a.mkv"$'\n'"download -l en -e utf-8 -f -C n,fo,hi -- ${FILMS}/b.MP4" ]]
}

@test "every video extension subliminal reads is picked up" {
  # Arrange
  videos a.avi b.m4v c.mov d.wmv e.webm f.mpg g.mpeg h.ts i.m2ts j.flv k.ogm l.divx m.3gp

  # Act
  run jm_test_run --dry-run "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Videos: 13 in ${FILMS}"* ]]
}

@test "several videos and folders are counted as places" {
  # Arrange
  videos a.mkv
  mkdir -p "${WORK}/more"
  : >"${WORK}/more/b.mkv"
  : >"${WORK}/c.mkv"

  # Act
  run jm_test_run --dry-run "${FILMS}" "${WORK}/more" "${WORK}/c.mkv"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Videos: 3 in 3 places"* ]]
  [[ "${output}" == *"Dry run: 3 videos would get a subtitle in en. Nothing was downloaded." ]]
}

@test "a dry run lists every video and never calls subliminal" {
  # Arrange
  videos a.mkv b.mkv

  # Act
  run jm_test_run --dry-run "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"        dry run: list each video and download nothing"$'\n\n'"${FILMS}/a.mkv"$'\n'"${FILMS}/b.mkv"$'\n'"Dry run: 2 videos would get a subtitle in en. Nothing was downloaded." ]]
  [[ ! -e "${FAKE_LOG}" ]]
}

@test "a dry run works without subliminal installed" {
  # Arrange
  videos a.mkv
  local farm
  farm="$(jm_test_farm subliminal)"

  # Act
  run jm_test_run_path "${farm}" --dry-run "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Dry run: 1 video would get a subtitle in en. Nothing was downloaded." ]]
}

@test "a run without subliminal stops before any video and says how to install it" {
  # Arrange
  videos a.mkv
  local farm
  farm="$(jm_test_farm subliminal)"

  # Act
  run jm_test_run_path "${farm}" "${FILMS}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"jimaku: subliminal is not installed: brew install subliminal, or apt install subliminal." ]]
}

@test "a folder with no videos says so and succeeds" {
  # Arrange
  videos notes.txt

  # Act
  run jm_test_run "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "No videos in ${FILMS}." ]]
}

@test "several places with no videos say so together" {
  # Arrange
  mkdir -p "${WORK}/more"

  # Act
  run jm_test_run "${FILMS}" "${WORK}/more"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "No videos found." ]]
}

@test "a video with no subtitle out there is a warning and fails the run" {
  # Arrange
  videos a.mkv rare.mkv

  # Act
  FAKE_NONE=rare run jm_test_run "${FILMS}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"jimaku: warning: no en subtitle found for ${FILMS}/rare.mkv."$'\n'"Saved en subtitles for 1 of 2 videos." ]]
}

@test "subliminal failing on a video is reported with what it said" {
  # Arrange
  videos a.mkv

  # Act
  FAKE_FAIL=a.mkv run jm_test_run "${FILMS}/a.mkv"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"jimaku: subliminal failed for ${FILMS}/a.mkv."$'\n'"jimaku: subliminal said: Error: every provider failed"$'\n'"jimaku: subliminal said: Try again later"$'\n'"No en subtitle was saved." ]]
}

@test "a Latin-1 subtitle is converted to UTF-8" {
  # Arrange
  videos a.mkv
  subtitle_source '1\n00:00:01,000 --> 00:00:02,000\nOl\341, cora\347\343o\n'

  # Act
  run jm_test_run "${FILMS}/a.mkv"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${FILMS}/a.en.srt: converted from iso-8859-1 to UTF-8."* ]]
  local bytes
  bytes="$(jm_test_bytes "${FILMS}/a.en.srt")"
  [[ "${bytes}" == *"4f6cc3a12c20636f7261c3a7c3a36f0a" ]]
}

@test "a Windows-1252 subtitle the file tool cannot name is converted through the fallback" {
  # Arrange
  videos a.mkv
  subtitle_source '1\n00:00:01,000 --> 00:00:02,000\n\223Ol\341\224\n'
  jm_test_shim file 'printf "unknown-8bit\\n"'

  # Act
  run jm_test_run "${FILMS}/a.mkv"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${FILMS}/a.en.srt: converted from WINDOWS-1252 to UTF-8."* ]]
  local bytes
  bytes="$(jm_test_bytes "${FILMS}/a.en.srt")"
  [[ "${bytes}" == *"e2809c4f6cc3a1e2809d0a" ]]
}

@test "a UTF-8 subtitle loses its byte order mark and nothing else" {
  # Arrange
  videos a.mkv
  subtitle_source '\357\273\2771\n00:00:01,000 --> 00:00:02,000\nOl\303\241\n'

  # Act
  run jm_test_run "${FILMS}/a.mkv"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" != *"converted"* ]]
  local bytes
  bytes="$(jm_test_bytes "${FILMS}/a.en.srt")"
  [[ "${bytes}" == "310a30303a30303a30312c303030202d2d3e2030303a30303a30322c3030300a4f6cc3a10a" ]]
}

@test "a UTF-16 subtitle with a byte order mark becomes UTF-8 without one" {
  # Arrange
  videos a.mkv
  subtitle_source '\377\3761\000\n\000O\000l\000\341\000\n\000'

  # Act
  run jm_test_run "${FILMS}/a.mkv"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${FILMS}/a.en.srt: converted from utf-16le to UTF-8."* ]]
  local bytes
  bytes="$(jm_test_bytes "${FILMS}/a.en.srt")"
  [[ "${bytes}" == "310a4f6cc3a10a" ]]
}

@test "a subtitle whose encoding cannot be told stays as it is with a warning" {
  # Arrange
  videos a.mkv
  jm_test_shim file 'exit 1'

  # Act
  run jm_test_run "${FILMS}/a.mkv"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"jimaku: warning: could not tell the encoding of ${FILMS}/a.en.srt, so it stays as it is."* ]]
}

@test "a subtitle iconv cannot convert stays as it is with a warning" {
  # Arrange
  videos a.mkv
  jm_test_shim file 'printf "iso-8859-1\\n"'
  jm_test_shim iconv 'exit 1'

  # Act
  run jm_test_run "${FILMS}/a.mkv"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"jimaku: warning: could not convert ${FILMS}/a.en.srt to UTF-8, so it stays as it is."* ]]
  [[ ! -e "${FILMS}/a.en.srt.jimaku" ]]
}

@test "a folder run also converts subtitles that were already there" {
  # Arrange
  videos a.mkv
  printf 'Ol\341\n' >"${FILMS}/old movie.en.srt"

  # Act
  run jm_test_run "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${FILMS}/old movie.en.srt: converted from iso-8859-1 to UTF-8."* ]]
}

@test "a video whose name holds brackets keeps its subtitle matched" {
  # Arrange
  videos "Show [1080p] S01E01.mkv" "Show [1080p] S01E010.mkv"
  printf 'Ol\341\n' >"${FILMS}/Show [1080p] S01E010.en.srt"

  # Act
  FAKE_NONE=S01E010 run jm_test_run "${FILMS}/Show [1080p] S01E01.mkv"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" != *"S01E010.en.srt"* ]]
}

@test "without a target and a terminal the current folder is used" {
  # Arrange
  videos a.mkv
  cd "${FILMS}" || return 1

  # Act
  run jm_test_run --dry-run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Videos: 1 in ."* ]]
}

@test "in a terminal the folder or video is asked for" {
  # Arrange
  videos a.mkv
  cd "${WORK}" || return 1

  # Act
  JM_INTERACTIVE=1 run jm_test_run --dry-run < <(printf '%s\n' films '')

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Folder or video [${WORK}]: "*"Videos: 1 in films"* ]]
}

@test "Enter at the prompt uses the current folder" {
  # Arrange
  videos a.mkv
  cd "${FILMS}" || return 1

  # Act
  JM_INTERACTIVE=1 run jm_test_run --dry-run < <(printf '\n\n')

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Videos: 1 in ${FILMS}"* ]]
}

@test "a target typed with a tilde starts at home" {
  # Arrange
  videos a.mkv

  # Act
  # shellcheck disable=SC2088
  HOME="${WORK}" run jm_test_run --dry-run '~/films'

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Videos: 1 in ${WORK}/films"* ]]
}

@test "a lone tilde is home itself" {
  # Arrange
  : >"${WORK}/a.mkv"

  # Act
  # shellcheck disable=SC2088
  HOME="${WORK}" run jm_test_run --dry-run '~'

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Videos: 1 in ${WORK}"* ]]
}

@test "end of input at the prompt stops the run" {
  # Arrange
  local empty=""

  # Act
  JM_INTERACTIVE=1 run jm_test_run < <(printf '%s' "${empty}")

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "Folder or video ["*"]: " ]]
}

@test "a bare -- without a target uses the current folder" {
  # Arrange
  videos a.mkv
  cd "${FILMS}" || return 1

  # Act
  run jm_test_run --dry-run --

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Videos: 1 in ."* ]]
}

@test "a byte order mark sed cannot strip leaves the subtitle as it was" {
  # Arrange
  videos a.mkv
  subtitle_source '\357\273\2771\n'
  jm_test_shim sed 'exit 1'

  # Act
  run jm_test_run "${FILMS}/a.mkv"

  # Assert
  [[ "${status}" -eq 0 ]]
  local bytes
  bytes="$(jm_test_bytes "${FILMS}/a.en.srt")"
  [[ "${bytes}" == "efbbbf310a" ]]
  [[ ! -e "${FILMS}/a.en.srt.jimaku" ]]
}

@test "a language with a region such as zh-Hant is accepted" {
  # Arrange
  videos a.mkv

  # Act
  run jm_test_run --dry-run --language zh-Hant "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Plan:   zh-Hant subtitles, saved as UTF-8 next to each video"* ]]
}

@test "JIMAKU_LANGUAGE sets the language when --language is not given" {
  # Arrange
  videos a.mkv

  # Act
  JIMAKU_LANGUAGE=pt-BR run jm_test_run "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Plan:   pt-BR subtitles, saved as UTF-8 next to each video"* ]]
  [[ -f "${FILMS}/a.pt-BR.srt" ]]
}

@test "--language wins over JIMAKU_LANGUAGE" {
  # Arrange
  videos a.mkv

  # Act
  JIMAKU_LANGUAGE=pt-BR run jm_test_run --language es "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  run download_calls
  [[ "${output}" == "download -l es -e utf-8 -f -C n,fo,hi -- ${FILMS}/a.mkv" ]]
}

@test "a JIMAKU_LANGUAGE that is not a language code stops the run before anything is fetched" {
  # Arrange
  videos a.mkv

  # Act
  JIMAKU_LANGUAGE=pt_BR run jm_test_run "${FILMS}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "jimaku: JIMAKU_LANGUAGE is 'pt_BR', which is not a language code such as pt-BR or en. run 'jimaku help' for usage." ]]
  [[ ! -e "${FAKE_LOG}" ]]
}

@test "an empty JIMAKU_LANGUAGE counts as not set" {
  # Arrange
  videos a.mkv

  # Act
  JIMAKU_LANGUAGE="" run jm_test_run --dry-run "${FILMS}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Plan:   en subtitles, saved as UTF-8 next to each video"* ]]
}

@test "in a terminal without a language the common ones are listed and a number picks one" {
  # Arrange
  videos a.mkv
  local menu
  menu="Common subtitle languages:"$'\n'"   1) en     English"$'\n'"   2) es     Spanish"$'\n'"   3) pt-BR  Brazilian Portuguese"

  # Act
  JM_INTERACTIVE=1 run jm_test_run --dry-run "${FILMS}" < <(printf '%s\n' 3)

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${menu}"$'\n'*"  12) zh     Chinese"$'\n'"Language, a number or a code [en]: "* ]]
  [[ "${output}" == *"Plan:   pt-BR subtitles, saved as UTF-8 next to each video"* ]]
}

@test "a language code typed at the prompt is used even when it is not listed" {
  # Arrange
  videos a.mkv

  # Act
  JM_INTERACTIVE=1 run jm_test_run --dry-run "${FILMS}" < <(printf '%s\n' nl)

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Plan:   nl subtitles, saved as UTF-8 next to each video"* ]]
}

@test "Enter at the language prompt picks English" {
  # Arrange
  videos a.mkv

  # Act
  JM_INTERACTIVE=1 run jm_test_run --dry-run "${FILMS}" < <(printf '\n')

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Plan:   en subtitles, saved as UTF-8 next to each video"* ]]
}

@test "a wrong answer at the language prompt is named and asked again" {
  # Arrange
  videos a.mkv

  # Act
  JM_INTERACTIVE=1 run jm_test_run --dry-run "${FILMS}" < <(printf '%s\n' 13 fr)

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"jimaku: '13' is not a number from the list or a language code such as pt-BR or en."$'\n'"Language, a number or a code [en]: "* ]]
  [[ "${output}" == *"Plan:   fr subtitles, saved as UTF-8 next to each video"* ]]
}

@test "three wrong answers at the language prompt stop the run" {
  # Arrange
  videos a.mkv

  # Act
  JM_INTERACTIVE=1 run jm_test_run "${FILMS}" < <(printf '%s\n' 0 pt_BR '?')

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"jimaku: '?' is not a number from the list or a language code such as pt-BR or en."$'\n'"jimaku: no language was chosen. run 'jimaku help' for usage." ]]
  [[ ! -e "${FAKE_LOG}" ]]
}

@test "end of input at the language prompt stops the run" {
  # Arrange
  videos a.mkv
  local empty=""

  # Act
  JM_INTERACTIVE=1 run jm_test_run "${FILMS}" < <(printf '%s' "${empty}")

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"Language, a number or a code [en]: " ]]
  [[ ! -e "${FAKE_LOG}" ]]
}

@test "in a terminal JIMAKU_LANGUAGE is used without asking" {
  # Arrange
  videos a.mkv
  local empty=""

  # Act
  JIMAKU_LANGUAGE=ja JM_INTERACTIVE=1 run jm_test_run --dry-run "${FILMS}" < <(printf '%s' "${empty}")

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" != *"Common subtitle languages"* ]]
  [[ "${output}" == *"Plan:   ja subtitles, saved as UTF-8 next to each video"* ]]
}

@test "a folder with no videos never asks for a language" {
  # Arrange
  videos notes.txt
  local empty=""

  # Act
  JM_INTERACTIVE=1 run jm_test_run "${FILMS}" < <(printf '%s' "${empty}")

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "No videos in ${FILMS}." ]]
}
