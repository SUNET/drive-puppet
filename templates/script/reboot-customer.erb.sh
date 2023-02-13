#!/bin/bash

# We sleep a deterministic amount of time, which will be between 0 an 128 m and allways the same within
# a specific host, but will differ between hosts
sleep $((16#$(ip a | grep "link/ether" | head -1 | awk -F ':' '{print $6}' | awk '{print $1}') / 2))m

needs_reboot="$(curl -s -H 'X-Thruk-Auth-User: thrukadmin' -H "X-Thruk-Auth-Key: <%= @apikey_prod %>" 'https://monitor.drive.sunet.se/thruk/r/services?display_name=Reboot+Needed&columns=state' -d 'q=host_groups>=<%= @location %>' | jq '. | any(.state != 0)')"
status=0
if [[ "${needs_reboot}" != "false" ]]; then
	/root/tasks/restart-db-cluster
	status=$((status + ${?}))
	/root/tasks/restart-nextcloud-farm
	status=$((status + ${?}))
	ssh "<%= @backup_server %>" "sudo /usr/local/bin/safer_reboot"
fi
exit ${status}
