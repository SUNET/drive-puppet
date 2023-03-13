#!/bin/bash
# Backup all databases
# We sleep a deterministic amount of time, which will be between 0 an 128 m and allways the same within
# a specific host, but will differ between hosts
sleep $((16#$(ip a | grep "link/ether" | head -1 | awk -F ':' '{print $6}' | awk '{print $1}') / 2))m
number_of_full_to_keep=7
backup="multinode-db1.$(fqdn -d)"
remote_backup_dir="/etc/mariadb/backups"
backup_dir="/opt/backups"
bucket="db-backups-multinode"
mirror="common-<%= @environment %>-mirror"
echo "Backing up all databases for for multinode customer"
ssh "${backup}" "sudo /home/script/bin/backup_multinode_db.sh"
echo "Cleaning up old backups for ${backup}"
ssh ${backup} "sudo /home/script/bin/purge_backups.sh ${remote_backup_dir}"
echo "Copying backups here"
mkdir -p ${backup_dir}
scp "script@${backup}:${remote_backup_dir}/$(date +%Y/%m/%d)/*.gz" "${backup_dir}"
echo "Copying backups to remote bucket"
rclone mkdir "${mirror}:${bucket}"
duplicity --full-if-older-than 1M --tempdir /mnt --archive-dir /mnt --no-encryption "${backup_dir}" "rclone://${mirror}:/${bucket}"
duplicity remove-all-but-n-full "${number_of_full_to_keep}" --tempdir /mnt --archive-dir /mnt --force "rclone://${mirror}:/${bucket}"
echo "cleaning up"
rm -r "${backup_dir}"
