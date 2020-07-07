# Configuration file
CONF=auto.conf
source ${CONF}

# Read status file
status_get() {
	[ -f ${file_status} ] && source ${file_status}
}

# Write status file
#status_put() {}

common_test() {
	echo This is a test.
}

# {$@} Log message
log() {
	#	[ -n "${file_log}" ] && {echo "$@" >>${file_log}}
	echo log:"$@"
}

# ${1} CMD
RUN_CMD() {
	CMD=$1
	$CMD
	RTN=$?
	if [ ${RTN} -ne 0 ]; then
		log \"$CMD\" error:${RTN}
		exit ${RTN}
	else
		log \"$CMD\"
	fi
	return ${RTN}
}

auto_db_update() {
	# create/update db
	for _i in ${auto_distro}; do
		local CMD="${auto_distro_root}/${_i}/${auto_db_script}"
		RUN_CMD ${CMD}
	done
}

auto_project_update() {
	local CMD="${auto_project_script}"
	RUN_CMD ${CMD}
}

auto_db_read() {
	for _i in ${auto_distro}; do

		local _db_path=${auto_db_root}/${_i}/${auto_db_file}
		echo db_read:${_db_path}
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
						#echo "${_i}::${_idx}"=${_ver}
						db_pkg+=(["${_i}::${_idx}"]=${_ver})
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
