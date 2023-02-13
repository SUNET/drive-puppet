#!/bin/bash
for container in $(docker ps | grep docker.sunet.se/drive/nextcloud-custom | grep -v cron | awk '{print $NF}'); do
	/usr/bin/docker exec -u www-data ${container} php --define apc.enable_cli=1 /var/www/html/cron.php
done
