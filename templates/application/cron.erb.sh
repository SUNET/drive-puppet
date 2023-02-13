#!/bin/bash
echo "$(date) - Start executing cron.sh"

# These are configurable with positional args
container=${1}
if [[ -z ${container} ]]; then
	container=nextcloud_app_1
fi

lock="/tmp/cron-${container}.lock"
if [[ -f ${lock} ]]; then
  echo "Lockfile exists, another instance of ${0} is running"
  exit 0
else
  touch ${lock}
fi

/usr/bin/docker exec -u www-data ${container} php --define apc.enable_cli=1 /var/www/html/cron.php

echo "$(date) - Done executing cron.sh"
rm ${lock}

