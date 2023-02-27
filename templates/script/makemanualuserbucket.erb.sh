#!/bin/bash
# The name of the bucket is the transformed user id
# E.g. user tene3253@su.se will receive the bucket tene3253-su-drive-sunet-se
echo "$(date) - Start executing ${0}"

# These are configurable with positional args
eppn=${1}
node1=${2}
container=${3}
rcp=${4}
if [[ -z ${node1} ]]; then
  num=$(seq 1 3 | shuf -n 1)
	node1=$(hostname --fqdn | sed 's/script1/node'${num}'/')
fi
if [[ -z ${container} ]]; then
	container=nextcloud_app_1
fi
if [[ -z ${rcp} ]]; then
	rcp="<%= @location %>"
fi

# These only have defaults
user_bucket_name="<%= @user_bucket_name %>"
if [[ -z ${user_bucket_name} ]]; then
	user_bucket_name="userdata"
fi
site_name="<%= @site_name %>"
rclone="rclone --config /root/.rclone.conf"

username=${eppn%@*}
# Remove underscore from username
user=${username//_/-}

bucketname="${user}-${site_name//./-}"

echo "$(date) - ${eppn} adding bucket and mounts..."
${rclone} mkdir ${rcp}:${bucketname}
ssh ${node1} "sudo /home/script/bin/create_bucket.sh ${container} ${eppn} ${bucketname} ${user_bucket_name}"

