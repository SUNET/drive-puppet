#!/bin/bash

customer="<%= @customer %>"
environment="<%= @environment %>"
eppn_suffix="<%= @eppn_suffix %>"
include_userbuckets="<%= @include_userbuckets %>"
container="nextcloud_app_1"
yq="/usr/local/bin/yq"
if ! [[ -x ${yq} ]]; then
	pip install yq
fi

declare -a directories
if [[ -n ${1} ]]; then
	directories=("${@}")
else
	directories+=("Arbetsmaterial")
	directories+=("Bevarande")
	directories+=("Gallringsbart")
fi

olddir="${PWD}"
tempdir=$(mktemp -d)
dirty=0
primary=''
declare -a users=( 'admin' )
cd "${tempdir}" || echo "Could not cd to tempdir"
declare -a projects=( "${yq}" -r '.project_mapping.'"${customer}"'.'"${environment}"'.assigned | "\(.[].project)"' /etc/hiera/data/common.yaml )
if [[ "${include_userbuckets}" == "true" ]]; then
	primary=$("${yq}" -r '.project_mapping.'"${customer}"'.'"${environment}"'.primary_project' /etc/hiera/data/common.yaml)
	projects+=( "${primary}" )
fi
for project in "${projects[@]}"; do
	for bucket in $(rclone lsd "${project}:" | awk '{print $NF}' | grep -E -v '^primary'); do
		count=$(rclone size --json "${project}:${bucket}" | jq -r .count)
		if [[ ${count} -gt 0 ]]; then
			echo "Skipping ${project}:${bucket} because it has stuff in it already"
			continue
		fi
		for directory in "${directories[@]}"; do
			dirty=1
      if [[ -n ${primary} ]] && [[ ${project} == "${primary}" ]] ; then
        user=$(echo "${bucket}" | awk -F '-' '{print $0}')
        users+=( "${user}@${eppn_suffix}" )
      fi
			echo "Creating ${project}:${bucket}/${directory} because it looks nice and empty"
			temp="README.md"
			echo "**${directory}**" >"${temp}"
			echo "Var god lämna kvar denna fil/Please leave this file" >>"${temp}"
			rclone --no-traverse move "${temp}" "${project}:${bucket}/${directory}"
		done
	done
done
cd "${olddir}" || echo "could not cd to home dir"
rmdir "${tempdir}"
if [[ ${dirty} -gt 0 ]]; then
  for user in "${users[@]}"; do
    ssh -t "node3.$(hostname -d)" -l script -i .ssh/id_script "sudo /usr/local/bin/occ ${container} files:scan ${user}"
  done
fi
