#!/usr/bin/env bash

config_php='/var/www/html/config/config.php'
dbhost="<%= @dbhost %>"
mysql_user_password="<%= @mysql_user_password %>"
admin_password="<%= @admin_password %>"
location="<%= @location %>"
bucket="<%= @s3_bucket %>"
customer="<%= @customer %>"

/usr/bin/mysql -e "drop database nextcloud" -u nextcloud -p"${mysql_user_password}" -h "${dbhost}" >/dev/null 2>&1
/usr/bin/mysql -e "create database nextcloud" -u nextcloud -p"${mysql_user_password}" -h "${dbhost}" >/dev/null 2>&1
if [[ "x${location}" != "x" || "x${bucket}" != "x" ]]; then
	bucket_content=$(/usr/bin/rclone ls "${location}":"${bucket}" --config /rclone.conf 2>/dev/null)
	if [[ "x${bucket_content}" != "x" ]]; then
		/usr/bin/rclone purge "${location}:${bucket}" --config /rclone.conf >/dev/null 2>&1
		/usr/bin/rclone mkdir "${location}:${bucket}" --config /rclone.conf >/dev/null 2>&1
	fi
fi
: >${config_php}
su - www-data -s /bin/bash <<EOF
  cd /var/www/html && php --define apc.enable_cli=1 ./occ  maintenance:install \
  --database "mysql" --database-name "nextcloud"  --database-user "nextcloud" \
  --database-pass "${mysql_user_password}" --database-host "${dbhost}" \
  --admin-user "admin" --admin-pass "${admin_password}" --data-dir /var/www/html/data \
  --no-interaction > /dev/null 2>&1 && php --define apc.enable_cli=1  ./occ files:recommendations:recommend admin > /dev/null 2>&1 && \
  php --define apc.enable_cli=1 ./occ app:enable globalsiteselector > /dev/null 2>&1 && \
  php --define apc.enable_cli=1 ./occ app:list > /dev/null 2>&1 && \
  php --define apc.enable_cli=1 ./occ app:enable files_external > /dev/null 2>&1 && \
  php --define apc.enable_cli=1 ./occ app:enable twofactor_totp > /dev/null 2>&1 && \
  php --define apc.enable_cli=1 ./occ app:enable twofactor_u2f > /dev/null 2>&1 && \
  php --define apc.enable_cli=1 ./occ app:enable admin_audit > /dev/null 2>&1
EOF
/usr/bin/wget --no-check-certificate -q https://localhost/index.php -O /dev/null
instanceid=$(grep -E "^  'instanceid'" ${config_php} | awk -F "'" '{print $4}')
secret=$(grep -E "^  'secret'" ${config_php} | awk -F "'" '{print $4}')
passwordsalt=$(grep -E "^  'passwordsalt'" ${config_php} | awk -F "'" '{print $4}')
echo "${customer}_instanceid: DEC::PKCS7[${instanceid}]!"
echo "${customer}_secret: DEC::PKCS7[${secret}]!"
echo "${customer}_passwordsalt: DEC::PKCS7[${passwordsalt}]!"

exit 0
