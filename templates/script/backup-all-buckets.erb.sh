#!/bin/bash
# Backup all buckets
# We sleep a deterministic amount of time, which will be between 0 an 128 m and allways the same within
# a specific host, but will differ between hosts
sleep $((16#$(ip a | grep "link/ether" | head -1 | awk -F ':' '{print $6}' | awk '{print $1}') / 2))m
number_of_full_to_keep='<%= @full_backup_retention %>'
fork_limit=30 #in GB, if bigger than this number, we fork the backup to it's own process
customer="<%= @customer %>"
#<% if @location.start_with?('common') %>
declare -a sixmonths=('mau')
if [[ " ${sixmonths[*]} " =~ " ${customer} " ]]; then
	number_of_full_to_keep=6
fi
declare -a projects
#<% @singlenodes.each do |singlenode| %>
projects+=("<%= @full_project_mapping[singlenode][@environment]['primary_project'] %> <%= @full_project_mapping[singlenode][@environment]['mirror_project'] %>")
#<% @full_project_mapping[singlenode][@environment]['assigned'].each do |project| %>
projects+=("<%= project['project'] %> <%= project['mirror_project'] %>")
#<% end %>
#<% end %>
#<% else %>
declare -a projects=("<%= @primary_project %> <%= @mirror_project %>")
#<% @assigned_projects.each do |project| %>
projects+=("<%= project['project'] %> <%= project['mirror_project'] %>")
#<% end %>
#<% end %>

if [[ ${customer} == 'common' ]]; then
  projects+=("<%= @location %> <%= @location %>-mirror")
fi


function do_backup {
	local project="${1}"
	local mirror="${2}"
	local bucket="${3}"
	local mirrorbucket="${bucket}-mirror"
	local mountpoint="/opt/backupmounts/${bucket}"
	ps aux | grep duplicity | grep "[^a-zA-Z]${bucket}" > /dev/null
	local oktorun=$?   # 1 == this bucket has no other bakup process in progress
	mkdir -p ${mountpoint}
	[ ${oktorun} -ne 0 ] && rclone mount ${project}:${bucket} ${mountpoint}/ --daemon --allow-other --dir-cache-time 24h
	rclone mkdir ${mirror}:${mirrorbucket}
	[ ${oktorun} -ne 0 ] && duplicity --full-if-older-than 1M --asynchronous-upload --tempdir /mnt --archive-dir /mnt \
		--no-encryption ${mountpoint} rclone://${mirror}:/${mirrorbucket}
	umount ${mountpoint}
	rmdir ${mountpoint}
	# Clean up
	[ ${oktorun} -ne 0 ] && duplicity remove-all-but-n-full ${number_of_full_to_keep} --tempdir /mnt --archive-dir /mnt \
		--force rclone://${mirror}:/${mirrorbucket}
}

for entry in "${projects[@]}"; do
	project=$(echo ${entry} | awk '{print $1}')
	mirror=$(echo ${entry} | awk '{print $2}')
	for bucket in $(rclone lsd ${project}:/ | awk '{print $5}'); do
		maybesize=$(timeout 30s rclone size --json ${project}:${bucket})
    if [[ ${?} -eq 124 ]]; then
      size=$((${fork_limit} * 1000000001))
    else
      size=$(echo ${maybesize} | jq -r '.bytes' )
    fi
		# If bucket is above 50 GB we fork
		if [[ ${size} -gt $((${fork_limit} * 1000000000)) ]]; then
			do_backup ${project} ${mirror} ${bucket} &
		else
			do_backup ${project} ${mirror} ${bucket}
		fi
	done
done
