#!/bin/bash
# Backup all databases
# We sleep a deterministic amount of time, which will be between 0 an 128 m and allways the same within
# a specific host, but will differ between hosts
sleep $((16#$(ip a | grep "link/ether" | head -1 | awk -F ':' '{print $6}' | awk '{print $1}') / 2))m
number_of_full_to_keep="<%= @full_backup_retention %>"

backup="${1}"
if [[ -z ${backup} ]]; then
  backup="backup1.$(hostname -d)"
fi
if ! [[ ${backup} =~ backup1.*sunet.se$ ]]; then
	echo "Usage: ${0} <fqdn of backup server>"
	echo "Example: ${0} backup1.sunet.drive.sunet.se"
fi
backup_dir="/opt/backups/backup-files"
bucket="db-backups"
mirror="<%= @customer %>-<%= @environment %>-mirror"
if [[ ${mirror} =~ common-(test|prod)-mirror ]]; then
	suffix=$(echo ${backup} | sed 's/backup1.*//')
	bucket="${bucket}-${suffix}"
	backup_dir="${backup_dir}-${suffix}"
fi
mkdir -p ${backup_dir}
echo "Backing up database for ${backup}"
ssh ${backup} "sudo /home/script/bin/backup_db.sh"
echo "Cleaning up old backups for ${backup}"
ssh ${backup} "sudo /home/script/bin/purge_backups.sh /opt/mariadb_backup/backups/"
echo "Copying backups here"
scp script@${backup}:/opt/mariadb_backup/backups/$(date +%Y/%m/%d)/*.gz ${backup_dir}
echo "Copying backups to remote bucket"
rclone mkdir ${mirror}:${bucket}
duplicity --full-if-older-than 1M --tempdir /mnt --archive-dir /mnt --no-encryption ${backup_dir} rclone://${mirror}:/${bucket}
duplicity remove-all-but-n-full ${number_of_full_to_keep} --tempdir /mnt --archive-dir /mnt --force rclone://${mirror}:/${bucket}
rm -rf "${backup_dir}"
