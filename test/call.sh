#!/bin/sh
[ -n "${ZSH_VERSION:-}" ] && emulate sh

JM_LIB="$(cd "$(dirname "$0")/../lib" && pwd)" || exit 1

# shellcheck source=SCRIPTDIR/../lib/core.sh
. "${JM_LIB}/core.sh"
# shellcheck source=SCRIPTDIR/../lib/cli.sh
. "${JM_LIB}/cli.sh"
# shellcheck source=SCRIPTDIR/../lib/doctor.sh
. "${JM_LIB}/doctor.sh"

"$@"
