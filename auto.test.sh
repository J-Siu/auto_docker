#!/bin/bash

# This is for testing

COMMON="auto.common.sh"
source ${COMMON}

# Print config
set|grep ^auto_

echo db update
time auto_db_update
echo db read
time auto_db_read

# test pkg version
echo
CMD="auto_db_pkg_ver alpine edge postfix"
echo $CMD
$CMD

auto_project_update