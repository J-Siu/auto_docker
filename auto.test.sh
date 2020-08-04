#!/usr/bin/env bash

COMMON="auto.common.sh"
source ${COMMON}
common_option ${@}

# --- Main ---

# This is for testing

# Print config
set | grep ^auto_

echo db update
time auto_db_update ${@}
echo db read
time auto_db_read

# test pkg version
echo
RUN_CMD "auto_db_dump"
RUN_CMD "auto_db_pkg_ver alpine edge postfix"

#auto_proj_update ${@}
