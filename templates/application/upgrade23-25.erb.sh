#!/bin/bash
touch /etc/no-automatic-cosmos
for version in 24.0.9.3-1 25.0.3.3-4; do
  docker pull docker.sunet.se/drive/nextcloud-custom:${version}
done

function block_for_container {
  while ! [[ "$( docker container inspect -f '{{.State.Running}}' "${1}" )" == "true" ]]; do
    echo "Waiting for ${1}"
    sleep 1s
  done
}
container="nextcloud_app_1"
sed -i "s/ 'version' => '.*',/ 'version' => '24.0.9.3',/" "/opt/nextcloud/config.php"
sed -i "s/  'config_is_read_only' => true,/  'config_is_read_only' => false,/" "/opt/nextcloud/config.php"
sed -i 's#docker.sunet.se/drive/nextcloud-custom:.*#docker.sunet.se/drive/nextcloud-custom:24.0.9.3-1#' "/opt/nextcloud/docker-compose.yml"
systemctl restart "sunet-nextcloud"
sleep 10s
block_for_container  ${container}
occ upgrade && occ db:add-missing-columns && occ db:add-missing-indices && occ db:add-missing-primary-keys
sed -i 's#docker.sunet.se/drive/nextcloud-custom:.*#docker.sunet.se/drive/nextcloud-custom:25.0.3.3-4#' "/opt/nextcloud/docker-compose.yml"
systemctl restart "sunet-nextcloud"
sleep 10s
block_for_container  ${container}
occ upgrade && occ db:add-missing-columns && occ db:add-missing-indices && occ db:add-missing-primary-keys && occ maintenance:repair
rm /etc/no-automatic-cosmos
