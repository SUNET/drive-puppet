#!/bin/bash

key=${1}
secret=${2}
endpoint=${3}
bucket=${4}
user=${5}
/usr/local/bin/occ files_external:create "${bucket}" \
	amazons3 -c bucket="${bucket}" -c key="${key}" -c secret="${secret}" -c hostname="${endpoint}" -c use_ssl=true -c use_path_style=true -c region=us-east-1 \
	amazons3::accesskey --user "${user}"
for shareid in $(/usr/local/bin/occ files_external:export "${user}" | jq -r '.[].mount_id'); do
	/usr/local/bin/occ files_external:option "${shareid}" enable_sharing true
done
