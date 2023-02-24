#!/bin/bash

container=${1}
customer=${2}
if [[ -z ${container} ]]; then
	container='mariadbbackup_mariadb_backup_1'
fi
if [[ -z ${customer} ]]; then
	location='<%= @location %>'
fi

dexec="docker exec ${container}"

password=$(${dexec} env | grep MYSQL_ROOT_PASSWORD | awk -F '=' '{print $2}')

mysql="${dexec} mysql -p${password}"

users="$(${mysql} -NB -e 'select uid,displayname from nextcloud.oc_global_scale_users')"
users="${users}
$(${mysql} -NB -e 'select uid,displayname from nextcloud.oc_users')"

project="statistics"
bucket="drive-server-coms"
base_dir="${project}:${bucket}"
mountpoint="/opt/statistics"
customer_dir="${mountpoint}/${location}"
mkdir -p "${customer_dir}"
rclone mkdir "${base_dir}/${location}"

echo "${users}" | awk 'BEGIN{print "{"} {print t "\""$1"\": \""$2"\""} {t=","} END{print "}"}' | jq . >"${customer_dir}/users.json"
status=0
if ! jq . "${customer_dir}/users.json" &>/dev/null; then
  status=1
fi
if [[ ${status} -eq 0 ]]; then
	# something is wrong if we cant copy the file in 30 seconds, so we should note that
	if ! timeout 30s rclone copy -c --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies "${customer_dir}/users.json" "${base_dir}/${location}/"; then
		status=1
	fi
fi
exit ${status}
