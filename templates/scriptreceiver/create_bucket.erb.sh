#!/bin/bash
container=${1}
user=${2}
bucket=${3}

user_bucket_name="userdata"

function usage {
	echo "Usage: ${0} <nextcloud container name> <nextcloud username> <bucket name>"
	echo "Example : ${0} nextcloud_app_1 kano@sunet.se kano"
	exit 1
}

if ! [[ ${container} == 'nextcloud_app_1' ]] && ! [[ ${container} =~ ^nextcloud-[a-z]*_app_1$ ]]; then
	usage
fi
if ! [[ ${bucket} =~ ^[a-zA-Z0-9]+ ]]; then
	usage
fi

if [[ "x${4}" != "x" ]]; then
	user_bucket_name=${4}
fi

echo "$(date): Start executing create_bucket.sh ${1} ${2} ${3}"

rclone_config="/opt/nextcloud/rclone.conf"
if [[ "${container}" != "nextcloud_app_1" ]]; then
  customer=$(echo "${container}" | sed -e 's/^nextcloud-//' -e 's/_app_1$//')
  rclone_config="/opt/multinode/${customer}/rclone.conf"
fi

key=$(grep access_key_id "${rclone_config}" | awk '{print $3}')
secret=$(grep secret_access_key "${rclone_config}"| awk '{print $3}')
endpoint=$(grep endpoint "${rclone_config}" | awk '{print $3}')
preexisting="$(docker exec -u www-data -i "${container}" php --define apc.enable_cli=1 /var/www/html/occ files_external:list --output json "${user}" | jq -r '.[] | .configuration.bucket' | grep "${bucket}")"

if [[ -z ${preexisting} ]]; then
	docker exec -u www-data -i "${container}" php --define apc.enable_cli=1 /var/www/html/occ files_external:create "${user_bucket_name}" \
		amazons3 -c bucket="${bucket}" -c key="${key}" -c secret="${secret}" -c hostname="${endpoint}" -c use_ssl=true -c use_path_style=true -c region=us-east-1 \
		amazons3::accesskey --user ${user}
	for shareid in $(docker exec -u www-data -i ${container} php --define apc.enable_cli=1 /var/www/html/occ files_external:export ${user} | jq -r '.[].mount_id'); do
		docker exec -u www-data -i ${container} php --define apc.enable_cli=1 /var/www/html/occ files_external:option ${shareid} enable_sharing true
	done
else
	echo "$(date): Preexisting: ${preexisting}"
fi
echo "$(date): Done executing create_bucket.sh"
