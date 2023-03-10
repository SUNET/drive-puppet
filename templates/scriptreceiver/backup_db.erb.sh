#!/bin/bash
container="${1}"
customer="${2}"
if [[ -z ${container} ]]; then
	container="mariadb_backup_mariadb_backup_1"
fi
if [[ -z ${customer} ]]; then
	backupdir="/opt/mariadb_backup/backups/"
else
	backupdir="/opt/multinode/${customer}/mariadb-${customer}/backups/"
fi

docker exec ${container} /do_backup.sh ${customer}
chmod 755 ${backupdir}
chown -R script:root ${backupdir}
