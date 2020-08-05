# Configuration file
CONF=auto.conf
source ${CONF}

declare -a auto_option_project
declare -a auto_option_prefix

# Read status file
status_get() {
	[ -f ${file_status} ] && source ${file_status}
}

common_test() {
	log "This is a test."
}

# {$@} Log message
log() {
	#	[ -n "${file_log}" ] && {echo "$@" >>${file_log}}
	echo -e "log:$@"
}

usage() {
	echo "Usage:"
	echo "  ${0} [flags]"
	echo "Flags:"
	echo -e "  -commit                  Apply git commit. Only work with -save"
	echo -e "  -tag                     Apply git tag. Only work with -commit"
	echo -e "  -debug                   Show debug log"
	echo -e "  -h, -help                Show help"
	echo -e "  -nobuild                 Do not perform docker build"
	echo -e "  -noskip                  Do not skip project"
	echo -e "  -pref, -prefix string    Path prefix for project"
	echo -e "  -proj, -project string   Path of project"
	echo -e "  -save                    Write back to project folder"
	echo -e "  -updatedb                Update package database"
}

# ${@}
common_option() {
	local _state=1
	for i in ${@}; do
		case ${_state} in
		1)
			case ${i} in
			"-commit")
				auto_option_commit=true # if defined/non-empty, git commit
				[ ${auto_option_debug} ] && log "enabled Commit"
				;;
			"-tag")
				auto_option_tag=true # if defined/non-empty, git tag
				[ ${auto_option_debug} ] && log "enabled Tag"
				;;
			"-debug")
				auto_option_debug=true # if defined/non-empty, debug mode
				[ ${auto_option_debug} ] && log "enabled Debug"
				;;
			"-save")
				auto_option_save=true # if defined/non-empty, write back to project
				[ ${auto_option_debug} ] && log "enabled Save"
				;;
			"-nobuild")
				auto_option_nobuild=true # if defined/non-empty, will not perform docker build
				[ ${auto_option_debug} ] && log "enabled No Build"
				;;
			"-noskip")
				auto_option_noskip=true # if defined/non-empty, process all project even no update
				[ ${auto_option_debug} ] && log "enabled No Skip"
				;;
			"-updatedb")
				auto_option_db_update=true # if defined/non-empty, process all project even no update
				[ ${auto_option_debug} ] && log "Update DB"
				;;
			"-proj" | "-project")
				_state=2
				;;
			"-pref" | "-prefix")
				_state=3
				;;
			"-h" | "-help")
				usage
				exit 0
				;;
			*)
				log "Unknown option"
				usage
				exit 0
				;;
			esac
			;;
		2)
			auto_option_project+=(${i})
			_state=1
			;;
		3)
			auto_option_prefix+=(${i})
			_state=1
			;;
		esac
	done
}

# ${1} CMD
RUN_CMD() {
	local CMD="${@}"

	[ ${auto_option_debug} ] && log "$CMD"

	$CMD
	local RTN=$?

	[ ${RTN} -ne 0 ] && log "$CMD error:${RTN}"

	return ${RTN}
}

auto_db_update() {
	# create/update db
	for _i in ${auto_distro_root}/*; do
		RUN_CMD "${_i}/${auto_db_script} ${@}"
	done
}

auto_db_read() {
	for _i in ${auto_db_root}/*; do

		local _db_path=${_i}/${auto_db_data}
		local _distro=$(basename ${_i})

		[ ${auto_option_debug} ] && log "auto_db_read:${_db_path}"

		if [ -f ${_db_path} ]; then
			local _idx=''
			local _ver=''
			local _state=1 # 1 = index line, 2 = version line
			while IFS= read -r _line; do
				if [ -n ${_line} ]; then
					case ${_state} in
					1)
						# index
						_idx=${_line}
						;;
					2)
						# version
						_ver=${_line}
						db_pkg+=(["${_distro}::${_idx}"]=${_ver})
						;;
					esac
					((_state = 3 - _state))
				fi
			done <"${_db_path}"
		fi
	done
}

# ${1} distro
# ${1} tag
# ${2} pkg
auto_db_pkg_ver() {
	_dis=${1}
	_tag=${2}
	_pkg=${3}
	echo ${db_pkg["${_dis}::${_tag}::${_pkg}"]}
}

auto_db_dump() {
	for _i in ${!db_pkg[@]}; do
		echo "${_i}=${db_pkg[${_i}]}"
	done
}
