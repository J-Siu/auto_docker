#!/bin/bash

# --- db.sh common start ---

COMMON="auto.common.sh"
source ${COMMON}

_my_path=${BASH_SOURCE[0]}
_my_name=$(basename ${_my_path})
_my_dir=${_my_path/%\/${_my_name}/}

source ${_my_dir}/${auto_db_conf}

_db_path=${auto_db_root}/${my_distro_name}/${auto_db_file}

# --- db.sh common end ---

# Get Alpine package db
#	- Check Status
#	if time up or db not exist
#		get alpine tag, ver, create db
#	else
# 	read db
# ${1} alpine version
alpine_apkindex2db() {
	if $(_db_refresh) || [ ! -f ${_db_path} ]; then

		# Remove old db
		[ -f ${_db_path} ] && rm ${_db_path}

		local _url=''
		local _dir_repo=''
		for _i in ${branch}; do
			echo ${_i} repo : ${repo[${_i}]}
			for _j in ${repo[${_i}]}; do
				_url="http://dl-cdn.alpinelinux.org/alpine/${_i}/${_j}/${arch}/APKINDEX.tar.gz"
				_dir_repo=${auto_db_root}/${my_distro_name}/${_i}/${_j}
				echo ${_dir_repo}
				mkdir -p ${_dir_repo}
				curl -s ${_url} | tar zx -C ${_dir_repo}
				# convert to auto db
				_alpine_apkindex2db ${_i} ${_dir_repo}/APKINDEX
			done
		done
	fi
}

# APKINDEX into array
# ${1} branch
# ${2} apkindex path
_alpine_apkindex2db() {
	local _branch=${1}
	local _apkindex=${2}

	local _field=''
	local _idx=''
	local _pkg=''
	local _val=''
	local _ver=''
	for _k in ${repo[${_branch}]}; do
		while IFS= read -r line; do
			if [ -n "$line" ]; then
				_field=${line:0:1}
				_val=${line:2}
				case "${_field}" in
				"V")
					# version
					_ver=${_val}
					;;
				"P")
					# pkg name
					_pkg=${_val}
					;;
				esac
			else
				# db index use image tag : latest-stable -> latest, edge -> edge
				_idx="${branch_tag_map[${_branch}]}::${_pkg}"
				echo "${_idx}" >>${_db_path}
				echo "${_ver}" >>${_db_path}
				_pkg=''
				_ver=''
			fi
		done <"${_apkindex}"
	done
}

# Check if is it time to refresh db
# return: true(0)/false(1)
_db_refresh() {
	return 1 # 0 == true/yes, 1 == false/no
}

# Get Alpine docker image tag from hub -- NOT USED
_alpine_tag_get() {
	# get all alpine image tags from registry
	filter='.results[]| .name'
	registry="https://registry.hub.docker.com/v2/repositories/library/alpine/tags/"
	#json=$(curl -s ${registry} | jq -r ${filter})
	json=$(cat test.json)
	#echo $json

	# get latest amd64 digest
	filter='.results[]|select(.name=="latest")|.images[]|select(.architecture=="amd64")|.digest'
	digest=$(echo ${json} | jq -r ${filter})
	#echo $digest

	# get versions with digest
	filter=".results[]|select(.images[]|.digest==\"${digest}\")|.name"
	tags=$(echo ${json} | jq -r ${filter})
	#echo "$tags"

	# get latest version tag
	tag=$(echo "${tags}" | grep -v latest | sort | tail -1)

	echo "${tag}"
}

# Convert Alpine image numeric tag to ver -- NOT USED
_alpine_tag2ver() {
	tag=${1}
	major=$(echo ${tag} | cut -d. -f1)
	minor=$(echo ${tag} | cut -d. -f2)
	patch=$(echo ${tag} | cut -d. -f3)
	echo "v${major}.${minor}"
}

# --- Main
alpine_apkindex2db
exit 0
