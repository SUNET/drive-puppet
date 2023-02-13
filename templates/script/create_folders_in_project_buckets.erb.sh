#!/bin/bash

customer="<%= @customer %>"
environment="<%= @environment %>"
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
cd "${tempdir}" || echo "Could not cd to tempdir"
for project in $(${yq} -r '.project_mapping.'"${customer}"'.'"${environment}"'.assigned | "\(.[].project)"' /etc/hiera/data/common.yaml); do
	for bucket in $(rclone lsd "${project}:" | awk '{print $NF}'); do
		count=$(rclone size --json "${project}:${bucket}" | jq -r .count)
		if [[ ${count} -gt 0 ]]; then
			echo "Skipping ${project}:${bucket} because it has stuff in it already"
			continue
		fi
		for directory in "${directories[@]}"; do
			dirty=1
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
	ssh -t "node3.$(hostname -d)" -l script -i .ssh/id_script "sudo /usr/local/bin/occ ${container} files:scan admin"
fi
