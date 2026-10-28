#!/bin/sh
{ set +x; } 2>/dev/null
printf '%s\n' "$*" >>"${FAKE_LOG:-/dev/null}"
case "$1" in
--version)
  printf 'subliminal, version %s\n' "${FAKE_VERSION:-2.8.0}"
  exit 0
  ;;
download) ;;
*) exit 2 ;;
esac
if [ "${2:-}" = "--help" ]; then
  [ "${FAKE_CATEGORIES:-yes}" = yes ] && printf '%s\n' '  -C, --subtitle-categories TEXT'
  printf '%s\n' '  -hi, --hearing-impaired'
  exit 0
fi
language="${3:-und}"
for video; do :; done
case "${video}" in
*"${FAKE_FAIL:-//}"*)
  printf '%s\n' 'Error: every provider failed' 'Try again later' >&2
  exit 1
  ;;
*"${FAKE_NONE:-//}"*)
  printf '%s\n' 'Downloaded 0 subtitle'
  exit 0
  ;;
*) ;;
esac
if [ -n "${FAKE_SOURCE:-}" ]; then
  cp -f "${FAKE_SOURCE}" "${video%.*}.${language}.srt"
else
  printf '%s\n' 1 '00:00:01,000 --> 00:00:02,000' 'Ola' >"${video%.*}.${language}.srt"
fi
printf '%s\n' '1 video collected / 0 video ignored / 0 error' 'Downloaded 1 subtitle'
