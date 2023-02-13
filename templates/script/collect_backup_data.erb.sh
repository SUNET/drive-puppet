#!/bin/bash

project="${1}"
bucket="${2}"
data_dir='/opt/backups/data'
for project in $(rclone listremotes | grep -v 'mirror'); do
	for bucket in $(rclone lsd "${project}" | awk '{print $NF}' | grep -E '\-mirror|db-backups'); do
    mkdir -p "${data_dir}/${project}" 
		duplicity collection-status --log-file /dev/stdout --no-encryption "rclone://${project}${bucket}" | grep -E '^ inc|^ full' > "${data_dir}/${project}/${bucket}.dat"
	done
done
