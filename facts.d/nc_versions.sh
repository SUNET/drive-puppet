#!/bin/bash

repo="/var/cache/cosmos/repo"
common="${repo}/global/overlay/etc/hiera/data/common.yaml"

function print_fact {
  customer=${1}
  environment=${2}
  version=${3}
  if [[ ${version} != 'null' ]]; then
    echo "nextcloud_version_${environment}_${customer}=${version}"
  else
    echo "nextcloud_version_${environment}_${customer}=$(yq -r ".${key}" "${common}")"
  fi
}

for environment in test prod; do
    key="nextcloud_version_${environment}"
    for customer in $(yq -r '.multinode_mapping | keys| .[]' "${common}"); do
      group="${repo}/multinode-common/overlay/etc/hiera/data/group.yaml"
      version=$(yq -r ".${key}" "${group}")
      print_fact "${customer}" "${environment}" "${version}"
    done
    for customer in $(yq -r '.fullnodes[]' "${common}") gss; do
      group="${repo}/${customer}-common/overlay/etc/hiera/data/group.yaml"
      version=$(yq -r ".${key}" "${group}")
      print_fact "${customer}" "${environment}" "${version}"
    done
done
