#!/bin/bash

container=${1}

if ! [[ ${container} =~ ^nextcloud[a-z]*_app_1$ ]]; then
	echo "Usage: ${0} <nextcloud container name>"
	echo "Example : ${0} nextcloud_app_1"
	exit 1
fi

docker exec -u www-data -i ${container} php --define apc.enable_cli=1 /var/www/html/occ user:list --limit 10000 --output=json_pretty
