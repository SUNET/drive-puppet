#!/bin/bash
customer=${1}
stream_name="${customer}mariadb-stream-$(date +%Y-%m-%dT%H.%M.%S).gz"
dump_name="${customer}mariadb-dump-$(date +%Y-%m-%dT%H.%M.%S).sql.gz"
backup_dir="/backups/$(date +%Y/%m/%d)"
mkdir -p "${backup_dir}"

if [[ -z ${customer} ]]; then
	buopts="--slave-info --safe-slave-backup"
	dumpopts="--dump-slave"
	mysql -p${MYSQL_ROOT_PASSWORD} -e "stop slave"
fi
mariadb-backup --backup ${buopts} -u root -p${MYSQL_ROOT_PASSWORD} --stream=xbstream | gzip >"${backup_dir}/${stream_name}"
mysqldump --all-databases --single-transaction ${dumpopts} -u root -p${MYSQL_ROOT_PASSWORD} | gzip >"${backup_dir}/${dump_name}"
if [[ -z ${customer} ]]; then
	mysql -p${MYSQL_ROOT_PASSWORD} -e "start slave"
fi
