#!/bin/bash
PATH="${PATH}:/usr/local/bin"
restarted="false"
for index in 1 2 3; do
	db_ip=$(host "intern-db${index}.$(hostname -d)" | awk '/has address/ {print $NF}')
  result=$(proxysql "select * from main.mysql_servers where hostname = '${db_ip}' and hostgroup_id = 10")
  if [[ -z ${result} ]]; then
    query="INSERT INTO main.mysql_servers (hostgroup_id, hostname, max_connections, comment) VALUES( 10, '${db_ip}', 100, 'Inserted by script at $(date)')"
    proxysql "${query}"
    restarted="true"
  fi
done
if [[ "${restarted}" == "true" ]]; then
	systemctl restart sunet-proxysql.service
fi
