#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/bin"
mkdir -p "${demo}/films" "${demo}/Music"
for name in "Charade (1963)" "Nosferatu (1922)" "His Girl Friday (1940)" "family-picnic-2019"; do
  head -c 1048576 /dev/urandom >"${demo}/films/${name}.mkv"
done
printf 'x\n' >"${demo}/Music/song.mp3"
