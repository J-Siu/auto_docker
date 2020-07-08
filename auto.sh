#!/bin/bash

COMMON="auto.common.sh"
source ${COMMON}
common_option ${@}

# --- Main ---

[ ${auto_debug} ] && log "$(set | grep ^auto_ | sort)"

auto_db_update ${@}
auto_proj_update ${@}
