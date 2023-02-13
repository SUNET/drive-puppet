#!/bin/bash

domain="$(hostname -d)"
ssh_command="ssh -q -tt -o StrictHostKeyChecking=off -l script -i /root/.ssh/id_script"

for index in 1 2 3; do
  no_mysql_servers=$(${ssh_command} node${index}.${domain} 'sudo /home/script/bin/get_no_mysql_servers.sh' | tr -d '\n')
  if [[ -n ${no_mysql_servers} ]] && [[ ${no_mysql_servers} -lt 2 ]]; then
    echo "Number of sql servers is ${no_mysql_servers}, so restarting proxysql"
    ${ssh_command} "node${index}.${domain}" "sudo /home/script/bin/restart_sunet_service.sh proxysql"
  else
    echo "Number of sql servers is ${no_mysql_servers}, so doing nothing"
  fi
done

exit 0
