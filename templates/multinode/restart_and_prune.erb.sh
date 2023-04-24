#!/bin/bash

include_paying="${1}"
customers="$(/usr/local/bin/get_non_paying_customers)"
echo "Starting cleanup: $(date)"
if [[ -n ${include_paying} ]]; then
  echo "Including paying customers: $(date)"
	customers="${customers}
  $(/usr/local/bin/get_paying_customers)"
fi
touch /etc/no-automatic-cosmos
for customer in ${customers}; do
  echo "Stopping ${customer}: $(date)"
	systemctl stop sunet-{redis,nextcloud}-"${customer}"
  echo "Pruning docker: $(date)"
	docker system prune -af --volumes
  echo "Starting ${customer}: $(date)"
	systemctl start sunet-{redis,nextcloud}-"${customer}"
done
rm /etc/no-automatic-cosmos
echo "Cleanup done: $(date)"
