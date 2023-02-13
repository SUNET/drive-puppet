#!/bin/bash
# Backup all buckets in rcp to rcpclone
src="<%= @location %>-pilot"
dest="<%= @location %>"

buckets=$(rclone lsjson ${src}: | jq -r '.[].Path')

for bucket in ${buckets}; do
	if [[ "${bucket}" =~ -clone$ ]]; then
		echo "Skipping clone bucket"
	else
		echo "Backing up bucket ${bucket}"
		rclone --config /root/.rclone.conf -c sync ${src}:${bucket} ${dest}:${bucket} --s3-upload-cutoff 0 --checkers 32 --low-level-retries 16 --transfers 8 -P
	fi
done
