#!/bin/bash

new_master=${1}

if ! [[ ${new_master} =~ sunet\.se$ ]]; then
  new_master="${new_master}.$(hostname -d)"
fi

new_master_ip=$(host -t A "${new_master}" | awk '{print $NF}')

if [[ ${?} -ne 0 ]] || [[ "x${new_master_ip}" == "x" ]]; then
	echo "usage:   ${0} <fqdn of new redis master>"
	echo "example: ${0} node3.sunet.drive.test.sunet.se"
	exit 1
fi
ssh_command="ssh -q -t -o StrictHostKeyChecking=off -l script -i /root/.ssh/id_script"
declare -a all_nodes
#<% @config['app'].each do |node| %>
all_nodes+=('<%= node %>')
#<% end %>
declare -a slave_nodes
for node in "${all_nodes[@]}"; do
	if [[ "${node}" != "${new_master_ip}" ]]; then
		slave_nodes+=("${node}")
	fi
done

for node in "${slave_nodes[@]}" ${new_master}; do
  ${ssh_command} "${node}" "sudo /home/script/bin/stop_sentinel.sh stop_cosmos"
done

${ssh_command} "${new_master}" "sudo /usr/local/bin/redis-cli slaveof no one"

for node in "${slave_nodes[@]}"; do
	${ssh_command} "${node}" "sudo /usr/local/bin/redis-cli slaveof ${new_master_ip} 6379"
done

for node in "${slave_nodes[@]}" ${new_master}; do
  ${ssh_command} "${node}" "sudo /home/script/bin/start_sentinel.sh clear_cosmos"
done
