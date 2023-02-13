#!/bin/bash

state=${1}

if ! [[ ${state} =~ ^(on|off)$ ]]; then
	echo "Usage: ${0} <on|off>"
	exit 1
fi

CUSTOMER='<%= @customer %>'
ENVIRONMENT='<%= @environment %>'
types="node"
env="test."
customer="${CUSTOMER}."
if [[ "${ENVIRONMENT}" == "prod" ]]; then
	env=""
fi
if [[ "${CUSTOMER}" == "common" ]]; then
	customer=""
	types="multinode gss"
fi

domain="${customer}drive.${env}sunet.se"

for prefix in ${types}; do
	if [[ "${prefix}" == "multinode" ]]; then
		range=4
	else
		range=3
	fi
	for i in $(seq ${range}); do
		host="${prefix}${i}.${domain}"
		ssh -t -o StrictHostKeyChecking=off ${host} "sudo /home/script/bin/maintenancemode.sh ${state}"
	done
done
