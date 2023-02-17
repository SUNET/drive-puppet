#!/bin/bash
# Lists all users from container
# Create and attach buckets for users ending in @<customer>
# The name of the bucket is the transformed user id
# E.g. user tene3253@su.se will receive the bucket tene3253-su-drive-sunet-se
echo "$(date) - Start executing makebuckets.sh"

# These are configurable with positional args
node=${1}
container=${2}
rcp=${3}
if [[ -z ${node} ]]; then
  num=$(seq 1 3 | shuf -n 1)
  # shellcheck disable=SC2086
	node=$(hostname --fqdn | sed 's/script1/node'${num}'/')
fi
if [[ -z ${container} ]]; then
	container=nextcloud_app_1
fi
if [[ -z ${rcp} ]]; then
	rcp="<%= @location %>"
fi

lock="/tmp/mkbucket-${rcp}-${node}.lock"
if [[ -f ${lock} ]]; then
  echo "Lockfile exists, another instance of ${0} is running"
  exit 0
else
  touch "${lock}"
fi
# These only have defaults
user_bucket_name="<%= @user_bucket_name %>"
if [[ -z ${user_bucket_name} ]]; then
	user_bucket_name="userdata"
fi
site_name="<%= @site_name %>"
rclone="rclone --config /root/.rclone.conf"

# These are dynamic
buckets="$(${rclone} lsd "${rcp}:" | awk '{print $NF}')"
users=$(${rclone} cat --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies "statistics:drive-server-coms/${rcp}/users.json" | jq '. | with_entries( select(.key | match("@") ) )')
for eppn in $(echo "${users}" | jq -r keys[]); do
  user=${eppn%@*}

  echo "$(date) - Check bucket status for ${eppn}"
  bucketname="${user}-${site_name//./-}"
  if ! echo "${buckets}" | grep "${bucketname}" &> /dev/null; then
    echo "$(date) - ${eppn} has no mounts configured, adding bucket and mounts..."
    ${rclone} mkdir "${rcp}:${bucketname}"
    # shellcheck disable=SC2029
    ssh-keygen -f "/root/.ssh/known_hosts" -R ${node}
    ssh -o StrictHostKeyChecking=no "${node}" "sudo /home/script/bin/create_bucket.sh ${container} ${eppn} ${bucketname} ${user_bucket_name}"
  fi
done
echo "$(date) - Done executing makebuckets.sh"
rm "${lock}"

