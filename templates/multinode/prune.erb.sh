#!/bin/bash
if [[ $(df --output=ipcent /var/lib/docker/ | tail -1 | sed 's/[ %]//g') -gt 50 ]]; then
	touch /etc/no-automatic-cosmos
	systemctl stop docker sunet-*.service
	#docker system prune -af --volumes
  rm -rf /var/lib/docker
	rm /etc/no-automatic-cosmos
	safer_reboot
fi
