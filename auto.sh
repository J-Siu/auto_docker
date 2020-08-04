#!/usr/bin/env bash

# Minimum bash version 4
[[ ${BASH_VERSION} ]] && [[ ${BASH_VERSION} < 4 ]] && echo "${BASH_VERSION} < 4" && exit 1

COMMON="auto.common.sh"
source ${COMMON}
common_option ${@}

# --- Main ---

[ ${auto_option_debug} ] && log "$(set | grep ^auto_ | sort)"

[ ${auto_option_db_update} ] && auto_db_update ${@}

[[ ! ${auto_option_project} ]] && [[ ! ${auto_option_prefix} ]] && [ ${auto_option_db_update} ] && exit 0
[[ ! ${auto_option_project} ]] && [[ ! ${auto_option_prefix} ]] && usage && exit 0

rm -rf ${auto_stg_root}

auto_proj_update ${@}
