#!/bin/bash

state=${1}

if ! [[ ${state} =~ ^(on|off)$ ]]; then
	echo "Usage: ${0} <on|off>"
	exit 1
fi

for container in $(docker ps | grep docker.sunet.se/drive/nextcloud-custom | grep -v cron | awk '{print $NF}'); do
	docker exec -ti ${container} su - www-data -s /bin/bash -c "php --define apc.enable_cli=1 /var/www/html/occ  maintenance:mode --${state}"
done
