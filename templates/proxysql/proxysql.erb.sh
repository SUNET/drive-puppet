#!/bin/bash
#docker exec proxysql_proxysql_1 mysql -B -N -e "UPDATE main.mysql_servers SET status = 'ONLINE' WHERE hostname = ''"
docker exec proxysql_proxysql_1 mysql -B -N -e "${@}"

