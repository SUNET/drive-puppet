#!/bin/bash

mode=${1}
if [[ "${mode}" == "multi" ]]; then
	filter='.multinode_mapping| keys | join("\n")'
elif [[ "${mode}" == "single" ]]; then
  filter='.singlenodes| join("\n")'
else
	filter='.fullnodes | join("\n")'
fi
yq -r "${filter}" < /etc/hiera/data/common.yaml

