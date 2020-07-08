#!/bin/bash

COMMON="auto.common.sh"
source ${COMMON}
common_option ${@}

# Dockerfile array hold following:
# FROM {from}
# LABEL version="{version}"
# LABEL maintainers="{maintainers}"
# LABEL name="{name}"
# LABEL usage="{usage}"
# {distro} derived from {from}
# {tag} derived from {from}
# {proj} project/dir name
declare -A dockerfile

# List of distro::branch
distro_tags=''

distro_branch_update() {
	for _i in ${auto_distro_root}/*; do
		source ${_i}/${auto_db_conf}
		for _j in ${tags}; do
			distro_tags+=" ${my_distro_name}:${_j}"
		done
	done
}

# ${1} project path
dockerfile_get() {
	local _dir_proj=${1}
	local _proj=$(basename ${_dir_proj})
	local _dockerfile_path=${_dir_proj}/Dockerfile
	for _i in version maintainers name usage; do
		local _val=$(grep "^LABEL ${_i}" ${_dockerfile_path} | cut -d= -f2- | tail -1)
		_val=${_val##\"} # strip first "
		_val=${_val%%\"} # strip last "
		dockerfile[${_i}]=${_val}
		[ ${auto_debug} ] && log "${_i}:${dockerfile[${_i}]}"
	done
	dockerfile["from"]=$(grep "^FROM\ " ${_dockerfile_path} | cut -d' ' -f2- | tail -1)
	[ ${auto_debug} ] && log "from:${dockerfile['from']}"
	dockerfile['distro']=${dockerfile['from']%:*}
	[ ${auto_debug} ] && log "distro:${dockerfile['distro']}"
	dockerfile['tag']=${dockerfile['from']#*:}
	[ ${auto_debug} ] && log "tag:${dockerfile['tag']}"
	dockerfile['proj']=${_proj}
	[ ${auto_debug} ] && log "proj:${dockerfile['proj']}"
}

dockerfile_skip() {

	# testing
	[ ${auto_noskip} ] && return 1 # 1=false, don't skip

	local _distro=${dockerfile["distro"]}
	local _from="${dockerfile["from"],,}" # change to lowercase
	local _pkg=${dockerfile["name"]}
	local _tag=${dockerfile["tag"]}
	local _ver=${dockerfile["version"]}

	#echo ${_from}, ${_tag}, ${_pkg}

	if [[ ${_from} == *" as "* ]]; then
		[ ${auto_debug} ] && log "Has AS"
		return 0 # 0=true, skip, not simple
	fi
	if [[ ${distro_tags} != *"${_distro}:${_tag}"* ]]; then
		[ ${auto_debug} ] && log "distro:tag no match"
		return 0 # 0=true, skip, not edge/latest
	fi
	local _db_pkg_ver=$(auto_db_pkg_ver ${_distro} ${_tag} ${_pkg})
	if [[ -z ${_db_pkg_ver} ]]; then
		[ ${auto_debug} ] && log "PKG not found"
		return 0 # 0=true, skip, pkg not found
	fi
	if [[ "${_ver}" == "${_db_pkg_ver}" ]]; then
		[ ${auto_debug} ] && log "PKG no update"
		return 0 # 0=true, skip, same version
	fi
	if [[ "${_ver}" > "${_db_pkg_ver}" ]]; then
		[ ${auto_debug} ] && log "PKG newer than db"
		return 0 # 0=true, skip, doesn't make sense, oh well ...
	fi

	return 1 # 1=false, don't skip
}

# ${1} staging dir
# ${2} pkg
dockerfile_build() {
	local _dir=${1}
	local _pkg=${2}
	local _img="${_pkg}:${auto_stg_tag}"
	local _curr_dir=$(pwd)
	cd ${_dir}
	RUN_CMD "docker build --quiet -t ${_img} ."
	local _rtn=$?
	# clean up
	RUN_CMD "docker image rm ${_img}"
	cd ${_curr_dir}
	return ${_rtn}
}

# ${1} staging dir
dockerfile_update() {
	local _dir=${1}
	local _file=${_dir}/Dockerfile
	local _action=''
	local _old_ver=${dockerfile["version"]}
	local _new_ver=$(auto_db_pkg_ver ${dockerfile["distro"]} ${dockerfile["tag"]} ${dockerfile["name"]})

	# version
	if [ -n "${_new_ver}" ]; then
		[ ${auto_debug} ] && log "${_old_ver} '->' ${_new_ver}"
		sed -i "s/${_old_ver}/${_new_ver}/g" ${_file}
	fi

	# maintainers
	_action="s#^LABEL maintainers=.*#LABEL maintainers=\"${auto_git_maintainers}\"#g"
	[ ${auto_debug} ] && log "_action: ${_action}"
	sed -i "${_action}" ${_file}

	# usage
	_usage="${auto_git_maintainers_url}/${dockerfile[proj]}/blob/master/README.md"
	_action="s#^LABEL usage=.*#LABEL usage=\"${_usage}\"#g"
	[ ${auto_debug} ] && log "_action: ${_action}"
	sed -i "${_action}" ${_file}
}

# ${1} staging dir
license_update() {
	local _file=${1}/LICENSE
	cp LICENSE ${_file}
	# Update copyright year
	local _year=$(date +%Y)
	sed -i "s/^Copyright (c).*/Copyright (c) ${_year}/g" ${_file}
}

# ${1} staging dir
readme_update() {
	local _file=${1}/README.md
	local _new_ver=$(auto_db_pkg_ver ${dockerfile["distro"]} ${dockerfile["tag"]} ${dockerfile["name"]})

	# Update Change Log before <!--CHANGE-LOG-END-->
	local _log="- ${_new_ver}"
	sed -i "s/${auto_log_end}/${_log}\n${auto_log_end}/g" ${_file}
	local _log="  - Auto update to ${_new_ver}"
	sed -i "s/${auto_log_end}/${_log}\n${auto_log_end}/g" ${_file}

	# Update copyright year
	local _year=$(date +%Y)
	sed -i "s/^Copyright (c).*/Copyright (c) ${_year}/g" ${_file}

	# #--- One time
	# local _old=''
	# local _new=''

	# _old="https://github.com/J-Siu/docker_compose"
	# _new="https://github.com/J-Siu/${dockerfile[proj]}"
	# sed -i "s#${_old}#${_new}#g" ${_file}

	# _old="cd docker/${dockerfile["pkg"]}"
	# _new="cd ${dockerfile[proj]}"
	# sed -i "s#^${_old}.*#${_new}#g" ${_file}
}

# ${1} project dir
proj_update() {
	local _dir_proj=${1}

	# clear global var dockerfile
	for _j in from version maintainers name usage; do
		dockerfile[${_j}]=''
	done

	if [ -f ${_dir_proj}/Dockerfile ]; then
		dockerfile_get ${_dir_proj}

		# dockerfile_skip use global var dockerfile
		if dockerfile_skip; then
			if [ ${auto_debug} ]; then
				log "${_dir_proj} skipped"
			fi
		else
			[ ${auto_debug} ] && log "${_dir_proj} processing"
			# Staging dir
			local _dir_stg=${auto_stg_root}/${dockerfile[proj]}
			# Delete if staging dir exist
			[ -d ${_dir_stg} ] && rm -rf ${_dir_stg}
			# Copy project to staging
			cp -r ${_dir_proj} ${auto_stg_root}/
			# Update Dockerfile
			dockerfile_update ${_dir_stg}
			# Build
			dockerfile_build ${_dir_stg} ${dockerfile["name"]}
			local _rtn=$?
			# If build successful
			if [ ${_rtn} -eq 0 ]; then
				readme_update ${_dir_stg}
				license_update ${_dir_stg}
				# Check DRYRUN
				if [ ${auto_dryrun} ]; then
					# Copy from staging to project
					for _j in Dockerfile README.md LICENSE; do
						CMD="cp ${_dir_stg}/${_j} ${_dir_proj}/"
						echo $CMD
						$CMD
					done
					# Git commit & tag
					if [[ ${auto_commit} ]]; then
						local _curr_dir=$(pwd)
						cd ${_dir_proj}
						CMD="git add ."
						echo $CMD
						$CMD
						CMD="git commit -a -m ${dockerfile["version"]}"
						echo $CMD
						$CMD
						CMD="git tag -a ${dockerfile["version"]} -m ${dockerfile["version"]}"
						echo $CMD
						$CMD
						cd ${_curr_dir}
					fi
				fi
			fi
			[ ${auto_debug} ] && log "${_dir_proj} processed"
		fi
	else
		if [ ${auto_debug} ]; then
			log "${_dir_proj} no Dockerfile"
		fi
	fi
}

# --- Main ---

auto_db_read
[ ! -d ${auto_stg_root} ] && RUN_CMD "mkdir -p ${auto_stg_root}"

distro_branch_update
[ ${auto_debug} ] && log "${distro_tags}"

for _docker in ${auto_proj_prefix}*; do
	[ ${auto_debug} ] && log "---"
	[ ${auto_debug} ] && log "${_docker}"
	proj_update ${_docker}
done
