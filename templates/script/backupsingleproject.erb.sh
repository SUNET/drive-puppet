#!/bin/bash
# Backup primary bucket or all buckets in a single project
proj=${1}
primary_only=${2}
if [[ -z ${proj} ]]; then
	echo "Usage: ${0} <project number> [primary only]"
	echo "Example: ${0} 34 yes"
	exit 1
fi
function do_backup {
	local project="${1}"
	local mirror="${2}"
	local bucket="${3}"
	local mirrorbucket="${bucket}-mirror"
	local mountpoint="/opt/backupmounts/${bucket}"
	mkdir -p "${mountpoint}"
	rclone mount "${project}:${bucket}" "${mountpoint}/" --daemon --allow-other --dir-cache-time 24h --timeout 0 
	rclone mkdir "${mirror}:${mirrorbucket}"
	duplicity full --asynchronous-upload --tempdir /mnt --archive-dir /mnt --timeout 3600 \
		--verbosity debug --no-encryption "${mountpoint}" "rclone://${mirror}:/${mirrorbucket}"
	umount "${mountpoint}"
	rmdir "${mountpoint}"
}

project="sto4-${proj}"
mirror="sto3-${proj}"
for bucket in $(rclone lsd "${project}:/" | awk '{print $5}'); do
  if [[ -n ${primary_only} ]] && ! [[ $bucket =~ 'primary-' ]]; then
    continue
  else
    do_backup "${project}" "${mirror}" "${bucket}" 
  fi
done
