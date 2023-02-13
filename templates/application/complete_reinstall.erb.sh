#!/usr/bin/env bash

config_php='/var/www/html/config/config.php'
dbhost="<%= @dbhost %>"
mysql_user_password="<%= @mysql_user_password %>"
admin_password="<%= @admin_password %>"
location="<%= @location %>"
bucket="<%= @s3_bucket %>"

echo "Input 'IKnowWhatIAmDoing' if you are sure you want to delete everything and reinstall Nextcloud: "
read -r user_input

if [[ "${user_input}" == "IKnowWhatIAmDoing" ]]; then
	echo "WARNING: This will delete everything in the database and reinstall Nextcloud."
	echo "You have 10 seconds to abort by hitting CTRL/C"
	sleep 10s
	echo "Ok, proceeding."
	echo "Dropping database in 3 seconds"
	sleep 3s
	/usr/bin/mysql -e "drop database nextcloud" -u nextcloud -p"${mysql_user_password}" -h "${dbhost}"
	/usr/bin/mysql -e "create database nextcloud" -u nextcloud -p"${mysql_user_password}" -h "${dbhost}"
	if [[ "x${location}" != "x" || "x${bucket}" != "x" ]]; then
		bucket_content=$(/usr/bin/rclone ls "${location}":"${bucket}" --config /rclone.conf)
		if [[ "x${bucket_content}" != "x" ]]; then
			echo "Deleting all files in ${location}:${bucket} in 3 seconds"
			sleep 3s
			/usr/bin/rclone purge "${location}:${bucket}" --config /rclone.conf
			/usr/bin/rclone mkdir "${location}:${bucket}" --config /rclone.conf
		fi
	fi
	: >${config_php}
	echo "Running maintenance:install"
	su - www-data -s /bin/bash <<EOF
  cd /var/www/html && php --define apc.enable_cli=1 ./occ  maintenance:install \
  --database "mysql" --database-name "nextcloud"  --database-user "nextcloud" \
  --database-pass "${mysql_user_password}" --database-host "${dbhost}" \
  --admin-user "admin" --admin-pass "${admin_password}" --data-dir /var/www/html/data \
  --no-interaction && php --define apc.enable_cli=1 ./occ files:recommendations:recommend admin && \
  php --define apc.enable_cli=1  ./occ app:list && \
  php --define apc.enable_cli=1  ./occ app:enable globalsiteselector && \
  php --define apc.enable_cli=1  ./occ app:list && \
  php --define apc.enable_cli=1  ./occ app:enable files_external && \
  php --define apc.enable_cli=1  ./occ app:enable twofactor_totp && \
  php --define apc.enable_cli=1  ./occ app:enable twofactor_u2f && \
  php --define apc.enable_cli=1  ./occ app:enable admin_audit
EOF
	/usr/bin/wget --no-check-certificate -q https://localhost/index.php -O /dev/null
	instanceid=$(grep -E "^  'instanceid'" ${config_php} | awk -F "'" '{print $4}')
	secret=$(grep -E "^  'secret'" ${config_php} | awk -F "'" '{print $4}')
	passwordsalt=$(grep -E "^  'passwordsalt'" ${config_php} | awk -F "'" '{print $4}')
	echo "Please use edit-secrets to add these variables to all Nextcloud servers:"
	echo "instanceid: DEC::PKCS7[${instanceid}]!"
	echo "secret: DEC::PKCS7[${secret}]!"
	echo "passwordsalt: DEC::PKCS7[${passwordsalt}]!"

	echo "All done, please enjoy your new nextcloud setup"
else
	echo "You did not input 'IKnowWhatIAmDoing', I am bailing out."
fi

exit 0
