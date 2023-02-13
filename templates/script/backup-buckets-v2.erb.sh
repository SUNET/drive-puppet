#!/bin/bash
# Backup all buckets
# We sleep a deterministic amount of time, which will be between 0 an 128 m and allways the same within
# a specific host, but will differ between hosts
sleep $((16#$(ip a | grep "link/ether" | head -1 | awk -F ':' '{print $6}' | awk '{print $1}') / 2))m
number_of_full_to_keep="<%= @full_backup_retention %>"
fork_limit=30    #in GB, if bigger than this number, we fork the backup to it's own process
split_limit=1000 #in GB, if bigger than this number, we fork backup of each directory to it's own process

declare -a projects=("<%= @primary_project %> <%= @mirror_project %>")
#<% @assigned_projects.each do |project| %>
projects+=("<%= project['project'] %> <%= project['mirror_project'] %>")
#<% end %>

function do_huge_backup {
	local project="${1}"
	local mirror="${2}"
	local bucket="${3}"
	declare -a directories
	declare -a empty
	for dir in $(rclone lsd ${project}:${bucket} | awk '{print $NF}'); do
		directories+=("${dir}")
		mountpoint="/opt/backupmounts/${bucket}-${dir}"
		do_backup ${project} ${mirror} ${bucket} ${mountpoint} ${dir} ${empty} &
	done
	mountpoint="/opt/backupmounts/${bucket}"
	do_backup ${project} ${mirror} ${bucket} ${mountpoint} none ${directories[@]} &

}

function do_backup {
	local project="${1}"
	shift
	local mirror="${1}"
	shift
	local bucket="${1}"
	shift
	local mountpoint="${1}"
	shift
	local dire="${1}"
	shift
	declare -a exclude
  exclude=( "${@}" )
	suffix=""
	opts=""
	if [[ "${dire}" != "none" ]]; then
		suffix="/${dire}"
	fi
	if ((${#exclude[@]})); then
		for dir in "${exclude[@]}"; do
			opts="${opts} --exclude /${dir}"
		done
	fi
	local mirrorbucket="${bucket}-mirror"
	mkdir -p ${mountpoint}
	rclone mount ${project}:${bucket}${suffix} ${mountpoint}/ --daemon --allow-other
	rclone mkdir ${mirror}:${mirrorbucket}${suffix}
	duplicity --full-if-older-than 1M --asynchronous-upload --tempdir /mnt --archive-dir /mnt ${opts} \
		--no-encryption ${mountpoint} rclone://${mirror}:/${mirrorbucket}${suffix}
	umount ${mountpoint}
	rmdir ${mountpoint}
	# Clean up
	duplicity remove-all-but-n-full ${number_of_full_to_keep} --tempdir /mnt --archive-dir /mnt \
		--force rclone://${mirror}:/${mirrorbucket}${suffix}
}

for entry in "${projects[@]}"; do
	project=$(echo ${entry} | awk '{print $1}')
	mirror=$(echo ${entry} | awk '{print $2}')
	declare -a empty
	for bucket in $(rclone lsd ${project}:/ | awk '{print $5}'); do
		size=$(rclone size --json ${project}:${bucket} | jq -r '.bytes')
		mirrorbucket="${bucket}-mirror"
		mountpoint="/opt/backupmounts/${bucket}"
		# If bucket is above ${split_limit} we fork and do backup per directory
		if [[ ${size} -gt $((${split_limit} * 1000000000)) ]]; then
			do_huge_backup ${project} ${mirror} ${bucket} &
		# If bucket is above ${fork_limit} we fork and do backup for bucket
		elif [[ ${size} -gt $((${fork_limit} * 1000000000)) ]]; then
			do_backup ${project} ${mirror} ${bucket} ${mountpoint} none ${empty} &
		else
			# If bucket is below ${fork_limit} we do not fork and do backup for bucket
			do_backup ${project} ${mirror} ${bucket} ${mountpoint} none ${empty}
		fi
	done
done
