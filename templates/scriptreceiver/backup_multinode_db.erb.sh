#!/bin/bash
docker exec mariadb_db_1 /scripts/run_manual_backup_dump.sh
backupdir=/etc/mariadb/backups
chmod 755 ${backupdir}
chown -R script:root ${backupdir}
