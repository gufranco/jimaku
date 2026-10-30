#!/bin/sh
set -eu

version=${1:?version required}
root=$(cd "$(dirname "$0")/../.." && pwd)
core="${root}/lib/core.sh"

if ! grep -q '^JIMAKU_VERSION=' "${core}"; then
  printf 'no JIMAKU_VERSION assignment found in %s\n' "${core}" >&2
  exit 1
fi

tmp=$(mktemp "${TMPDIR:-/tmp}/jimaku-version-XXXXXX")
sed "s/^JIMAKU_VERSION=\".*\"$/JIMAKU_VERSION=\"${version}\"/" "${core}" >"${tmp}"
cat "${tmp}" >"${core}"
rm -f "${tmp}"

reported=$("${root}/bin/jimaku" --version)
printf 'version set to %s\n' "${reported}"
