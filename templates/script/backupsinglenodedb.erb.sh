#!/bin/bash
# Backup all databases
# We sleep a deterministic amount of time, which will be between 0 an 128 m and allways the same within
# a specific host, but will differ between hosts
sleep $((16#$(ip a | grep "link/ether" | head -1 | awk -F ':' '{print $6}' | awk '{print $1}') / 2))m
backup="${1}"
customer=${2}

declare -a sixmonths=('mau')

function usage {
	echo "Usage: ${0} <fqdn of multinode server> <customer name>"
	echo "Example: ${0} multinode2.sunet.drive.sunet.se mau"
	exit 1
}

if ! [[ ${backup} =~ multinode.*sunet.se$ ]]; then
	usage
fi
if [[ -z ${customer} ]]; then
	usage
fi
if [[ " ${sixmonths[*]} " =~ " ${customer} " ]]; then
	number_of_full_to_keep=6
else
	number_of_full_to_keep=1
fi
container="mariadb-${customer}_db_1"
backup_dir="/opt/backups"
bucket="db-backups"
mirror="${customer}-<%= @environment %>-mirror"
bucket="${bucket}-${customer}"
backup_dir="${backup_dir}-${customer}"
echo "Backing up database for ${customer} on ${backup}"
ssh ${backup} "sudo /home/script/bin/backup_db.sh ${container} ${customer}"
echo "Cleaning up old backups for ${backup}"
ssh ${backup} "sudo /home/script/bin/purge_backups.sh /opt/multinode/${customer}/mariadb-${customer}/backups/"
echo "Copying backups here"
mkdir -p ${backup_dir}
scp script@${backup}:/opt/multinode/${customer}/mariadb-${customer}/backups/$(date +%Y/%m/%d)/*.gz ${backup_dir}
echo "Copying backups to remote bucket"
rclone mkdir ${mirror}:${bucket}
duplicity --full-if-older-than 1M --tempdir /mnt --archive-dir /mnt --no-encryption ${backup_dir} rclone://${mirror}:/${bucket}
duplicity remove-all-but-n-full ${number_of_full_to_keep} --tempdir /mnt --archive-dir /mnt --force rclone://${mirror}:/${bucket}
echo "cleaning up"
rm -r ${backup_dir}
