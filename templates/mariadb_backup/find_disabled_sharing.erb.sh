#!/bin/bash

container=${1}
customer=${2}
if [[ -z ${container} ]]; then
	container='mariadb_backup_mariadb_backup_1'
fi
if [[ -z ${customer} ]]; then
	location='<%= @location %>'
fi

dexec="docker exec ${container}"

password=$(${dexec} env | grep MYSQL_ROOT_PASSWORD | awk -F '=' '{print $2}')

mysql="${dexec} mysql -p${password}"

project="statistics"
bucket="drive-server-coms"
base_dir="${project}:${bucket}"
mountpoint="/opt/statistics"
customer_dir="${mountpoint}/${location}"
mkdir -p "${customer_dir}"
rclone mkdir "${base_dir}/${location}"

${mysql} -NB -e \
  "select JSON_OBJECT('option_id',oc_external_options.option_id,'mount_id',oc_external_options.mount_id,'sharing_enabled',oc_external_options.value,'mount_point',oc_external_mounts.mount_point,'storage_backend',oc_external_mounts.storage_backend,'auth_backend',oc_external_mounts.auth_backend,'priority',oc_external_mounts.priority,'type',oc_external_mounts.type,'bucket',oc_external_config.value) as data from oc_external_options join oc_external_mounts on oc_external_options.mount_id=oc_external_mounts.mount_id and oc_external_options.key = 'enable_sharing' and oc_external_options.value = 'false' join oc_external_config on oc_external_config.mount_id=oc_external_mounts.mount_id where oc_external_config.key='bucket'" \
  nextcloud | jq -s . >"${customer_dir}/sharing_disabled.json"
status=${?}
if [[ ${status} == 0 ]]; then
	rclone move "${customer_dir}/sharing_disabled.json" "${base_dir}/${location}/"
fi
exit ${status}
