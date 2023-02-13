#!/usr/bin/env bash

# A bash implementation of http://code.openark.org/blog/mysql/leader-election-using-mysql

# Defaults
quorum_alive_command='/bin/true'
quorum_config='/etc/quorum.conf'
quorum_db='quorum'
quorum_db_command='/usr/bin/mysql'
quorum_host='localhost'
quorum_id=$(hostname -f)
quorum_interval='20'
quorum_notify_command='/usr/bin/echo alive status:${QUORUM_ALIVE_STATUS}, leader: ${QUORUM_LEADER}, my leader status: ${QUORUM_LEADER_STATUS}'
quorum_password='quorum'
quorum_table='service_election'
quorum_user='quorum'

# Override default config path from env
if [[ "x${QUORUM_CONFIG}" != "x" ]]; then
	quorum_config="${QUORUM_CONFIG}"
fi

# Override default config with settings from config file
if [[ -f "${quorum_config}" ]]; then
	. "${quorum_config}"
fi

# Override with env
if [[ "x${QUORUM_ALIVE_COMMAND}" != "x" ]]; then
	quorum_alive_command=${QUORUM_ALIVE_COMMAND}
fi
if [[ "x${QUORUM_DB}" != "x" ]]; then
	quorum_db=${QUORUM_DB}
fi
if [[ "x${QUORUM_DB_COMMAND}" != "x" ]]; then
	quorum_db_command=${QUORUM_DB_COMMAND}
fi
if [[ "x${QUORUM_HOST}" != "x" ]]; then
	quorum_host=${QUORUM_HOST}
fi
if [[ "x${QUORUM_ID}" != "x" ]]; then
	quorum_id=${QUORUM_ID}
fi
if [[ "x${QUORUM_INTERVAL}" != "x" ]]; then
	quorum_interval=${QUORUM_INTERVAL}
fi
if [[ "x${QUORUM_NOTIFY_COMMAND}" != "x" ]]; then
	quorum_notify_command=${QUORUM_NOTIFY_COMMAND}
fi
if [[ "x${QUORUM_PASSWORD}" != "x" ]]; then
	quorum_password=${QUORUM_PASSWORD}
fi
if [[ "x${QUORUM_TABLE}" != "x" ]]; then
	quorum_table=${QUORUM_TABLE}
fi
if [[ "x${QUORUM_USER}" != "x" ]]; then
	quorum_user=${QUORUM_USER}
fi

# MySQL command
quorum_db_command="${quorum_db_command} --database=${quorum_db} --user ${quorum_user} --password ${quorum_password}"

# Queries
create_table_query='CREATE TABLE ${quorum_table} ( 
  anchor tinyint(3) unsigned NOT NULL, 
  service_id varchar(128) NOT NULL, 
  last_seen_active timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, 
  PRIMARY KEY (anchor) 
) ENGINE=InnoDB'

table_exists_query="SELECT * 
FROM information_schema.tables
WHERE table_schema = '${quorum_db}' 
    AND table_name = '${quorum_table}'
LIMIT 1"

election_query="insert ignore into ${quorum_table} ( anchor, service_id, last_seen_active ) values ( 1, '${quorum_id}', now() ) on duplicate key update service_id = if(last_seen_active < now() - interval ${quorum_interval} second, values(service_id), service_id), last_seen_active = if(service_id = values(service_id), values(last_seen_active), last_seen_active)"

is_leader_query="select count(*) as is_leader from ${quorum_table} where anchor=1 and service_id='${quorum_id}'"

who_is_leader_query="select max(service_id) as leader from ${quorum_table} where anchor=1"

# Set up table if it does not exist
${quorum_db_command} -e "${table_exists_query}" >/dev/null 2>&1
if [[ ${?} -ne 0 ]]; then
	${quorum_db_command} -e "${create_table_query}" >/dev/null 2>&1
fi

# Run the algorithm
${quorum_alive_command} >/dev/null 2>&1
alive_status=${?}
if [[ ${alive_status} -eq 0 ]]; then
	${quorum_db_command} -e "${election_query}" >/dev/null 2>&1
fi
leader_status=$(${quorum_db_command} -e "${is_leader_query}")
leader=$(${quorum_db_command} -e "${who_is_leader_query}")

QUORUM_ALIVE_STATUS=${alive_status} QUORUM_LEADER=${leader} QUORUM_LEADER_STATUS=${leader_status} eval ${quorum_notify_command}
exit ${alive_status}
