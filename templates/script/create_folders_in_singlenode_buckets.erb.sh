#!/bin/bash

customer="${1}"
shift
include_userbuckets="${1}"
shift
environment="<%= @environment %>"
container="nextcloud-${customer}_app_1"

yq="/usr/local/bin/yq"
if ! [[ -x ${yq} ]]; then
	pip install yq
fi

node=$(${yq} -r ".multinode_mapping | .${customer}.server" /etc/hiera/data/common.yaml)

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
cd "${tempdir}" || echo "Could not cd to tempdir"
declare -a projects=( $(${yq} -r '.project_mapping.'"${customer}"'.'"${environment}"'.assigned | "\(.[].project)"' /etc/hiera/data/common.yaml) )
if [[ "${include_userbuckets}" == "true" ]]; then
	projects+=( $(${yq} -r '.project_mapping.'"${customer}"'.'"${environment}"'.primary_project' /etc/hiera/data/common.yaml) )
fi
declare -a users=("admin")
for project in "${projects[@]}"; do
	for bucket in $(rclone lsd "${project}:" | awk '{print $NF}' | grep -E -v '^primary'); do
		count=$(rclone size --json "${project}:${bucket}" | jq -r .count)
		if [[ ${count} -gt 0 ]]; then
			echo "Skipping ${project}:${bucket} because it has stuff in it already"
			continue
		fi
		dirty=1
		# Check if this is a userbucket
		if [[ ${bucket} =~ sunet.se ]] && [[ "${include_userbuckets}" == "true" ]]; then
			user=$(echo "${bucket}" | awk '{print $NF}' | cut -d '-' -f 1)
			users+=("${user}@${customer}.se")
		fi
		for directory in "${directories[@]}"; do
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
		ssh -t "${node}.$(hostname -d)" -l script -i .ssh/id_script "sudo /usr/local/bin/occ ${container} files:scan ${user}"
	done
fi
