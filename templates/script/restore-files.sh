#!/bin/bash

function usage {
	echo "Usage: ${0} --user <user who gains access> --bucket <bucket> --project <project> [--time <restore from>] [--file-to-restore <files to restore>]"
	exit 1
}

while [[ "$#" -gt 0 ]]; do
	case $1 in
	-t | --time)
		time="${2}"
		shift
		;;
	-u | --user)
		user="${2}"
		shift
		;;
	-b | --bucket)
		bucket="${2}"
		shift
		;;
	-f | --file-to-restore)
		files="${2}"
		shift
		;;
	-p | --project)
		project="${2}"
		shift
		;;
	*)
		usage
		;;
	esac
	shift
done

if [[ -z ${bucket} ]] || [[ -z ${project} ]]; then
	usage
fi

duplicity_opts="--no-encryption"
if [[ -n ${files} ]]; then
	duplicity_opts="${duplicity_opts} --file-to-restore ${files}"
fi
if [[ -n ${time} ]]; then
	duplicity_opts="${duplicity_opts} --time ${time}"
fi
node1=$(hostname --fqdn | sed 's/script/node/')
restoredir="/opt/restoremounts/${bucket}"
restorepath="${project}:${bucket}-restore"
backuppath="${project}:${bucket}-mirror"
mkdir -p "${restoredir}"
rclone mkdir "${restorepath}"
rclone mount "${restorepath}" "${restoredir}" --daemon --allow-other
# shellcheck disable=SC2086
duplicity restore ${duplicity_opts} "rclone://${backuppath}" "${restoredir}"
key=""
secret=""
endpoint=""

# shellcheck disable=SC2029
ssh "script@${node1}" "/home/script/bin/create_bucket_without_question.sh ${key} ${secret} ${endpoint} ${bucket}-mirror ${user}"
