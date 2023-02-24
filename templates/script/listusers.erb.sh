#!/bin/bash

customer="${1}" 
multinode="${2}" 
environment="<%= @environment %>"
location="${customer}-${environment}"
userjson=$(ssh "script@${multinode}" "sudo /home/script/bin/list_users.sh nextcloud${customer}_app_1") 
project="statistics"
bucket="drive-server-coms"
base_dir="${project}:${bucket}"
stat_dir="/opt/statistics"
customer_dir="${stat_dir}/${location}"
mkdir -p "${customer_dir}"
rclone mkdir "${base_dir}/${location}"
echo "${userjson}"  | jq . >"${customer_dir}/users.json"
status=${?}
if [[ ${status} -eq 0 ]]; then
	# something is wrong if we cant copy the file in 30 seconds, so we should note that
	if ! timeout 30s rclone copy -c --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies "${customer_dir}/users.json" "${base_dir}/${location}/"; then
		status=1
	fi
fi
exit ${status}
