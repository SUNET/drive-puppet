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
for container in $(get_containers); do 
  customer=$(echo "${container}" | sed -e 's/nextcloud//' -e 's/_app_1//')
  sed -i "s/ 'version' => '.*',/ 'version' => '24.0.9.3',/" "/opt/multinode/${customer}/config.php"
  sed -i "s/  'config_is_read_only' => true,/  'config_is_read_only' => false,/" "/opt/multinode/${customer}/config.php"
  sed -i 's#docker.sunet.se/drive/nextcloud-custom:.*-1#docker.sunet.se/drive/nextcloud-custom:24.0.9.3-1#' "/opt/multinode/${customer}/nextcloud-${customer}/docker-compose.yml"
  systemctl restart "sunet-nextcloud-${customer}"
  sleep 10s
  block_for_container "${container}"
  occ "${container}" upgrade && occ "${container}" db:add-missing-columns && occ "${container}" db:add-missing-indices && occ "${container}" db:add-missing-primary-keys
  sed -i 's#docker.sunet.se/drive/nextcloud-custom:.*-1#docker.sunet.se/drive/nextcloud-custom:25.0.3.3-1#' "/opt/multinode/${customer}/nextcloud-${customer}/docker-compose.yml"
  systemctl restart "sunet-nextcloud-${customer}"
  sleep 10s
  block_for_container "${container}"
  occ "${container}" upgrade && occ "${container}" db:add-missing-columns && occ "${container}" db:add-missing-indices && occ "${container}" db:add-missing-primary-keys && occ "${container}" maintenance:repair
done
rm /etc/no-automatic-cosmos
