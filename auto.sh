#!/bin/bash

COMMON="auto.common.sh"
source ${COMMON}

# --- main
[ ${auto_debug} ] && log "$(set|sort)"

auto_db_update

common_option ${@}

auto_proj_update ${@}