#!/bin/sh

LC_ALL=C
export LC_ALL

: "${JM_LIB:=}"
: "${JM_PROG:=jimaku}"
: "${JM_LANGUAGE:=}"
: "${JM_DEFAULT_LANGUAGE:=en}"
: "${JM_HEARING:=no}"
: "${JM_FORCE:=yes}"
: "${JM_DRY_RUN:=no}"
: "${JM_CATEGORIES:=no}"
: "${JM_ARGS_DONE:=no}"
: "${JM_ARGS_PENDING:=no}"
: "${JM_TARGETS:=0}"
: "${JM_PLACE:=}"
: "${JM_PLACE_KIND:=}"
: "${JM_FOUND:=0}"
: "${JM_SAVED:=0}"
: "${JM_MISSED:=0}"
: "${JM_FAILED:=0}"
: "${JM_OS:=}"
: "${JM_INSTALL_HINT:=brew install subliminal, or apt install subliminal}"
