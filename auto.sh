#!/bin/bash

COMMON="auto.common.sh"
source ${COMMON}
common_option ${@}

# --- Main ---

[ ${auto_option_debug} ] && log "$(set | grep ^auto_ | sort)"

[ ${auto_option_db_update} ] && auto_db_update ${@}
auto_proj_update ${@}
