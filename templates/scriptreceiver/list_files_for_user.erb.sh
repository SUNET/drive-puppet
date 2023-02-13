#!/bin/bash
container=${1}
user=${2}
format=${3}

function usage {
	echo "Usage: ${0} <nextcloud container name> <nextcloud username>"
	echo "Example : ${0} nextcloud_app_1 kano@sunet.se"
	exit 1
}

if ! [[ ${container} =~ ^nextcloud[a-z]*_app_1$ ]]; then
	usage
fi

if [[ "x${user}" == "x" ]]; then
	usage
fi

if [[ "x${format}" != "x" ]]; then
	format="--output ${format}"
fi

docker exec -u www-data -i ${container} php --define apc.enable_cli=1 /var/www/html/occ files_external:list ${format} ${user}
