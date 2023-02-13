#!/bin/bash
docker exec -ti proxysql_proxysql_1 mysql -NB -e "select count(*) FROM main.runtime_mysql_servers where hostgroup_id = 10" | tr -d '\r'
