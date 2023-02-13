#!/bin/bash
service="${1}"

if [[ "x${service}" == "x" ]]; then
	echo "usage:   ${0} <service>"
	echo "example: ${0} proxysql"
	exit 1
fi

systemctl restart sunet-"${service}".service
