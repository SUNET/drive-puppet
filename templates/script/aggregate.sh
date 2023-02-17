#!/bin/bash

# Datafile with customers
commonyaml="/etc/hiera/data/common.yaml"
billingbucket="statistics:drive-storage-report"
aggregatedir="${billingbucket}/billing/daily"
latestdir="${billingbucket}/billing"
aggregatefile="billing-$(date +%Y%m%d).csv"
tempdir=$(mktemp -d)

# Install yq if needed
yq="/usr/local/bin/yq"
if ! [[ -x ${yq} ]]; then
	pip3 install yq
fi

olddir=${PWD}
cd "${tempdir}" || (echo "could not move to tempdir" && exit 1)

# Make sure we have dir
rclone mkdir -p "${aggregatedir}"
# Output headers
csv="DATE:$(date +%F) TIME:$(date +%H:%M)
Customer;Total GB;Users;Product"

# Aggregate data
for customer in $(${yq} -r '.fullnodes | .[]' ${commonyaml}); do
	product=1 # Prisplan 1
	csv="${csv}
$(rclone cat --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies "${billingbucket}/${customer}-usage/${customer}-latest.csv" |
		grep -E -v '^DATE|^Customer' |
		sed 's/$/;1/')"
done
for customer in $(${yq} -r '.singlenodes | .[]' ${commonyaml}); do
	product=2 # Prisplan 2
	csv="${csv}
$(rclone --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies cat "${billingbucket}/${customer}-usage/${customer}-latest.csv" |
		grep -E -v '^DATE|^Customer' |
		sed 's/$/;'${product}'/')"
done
echo "${csv}" >"${aggregatefile}"

rclone copy --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies "${aggregatefile}" "${aggregatedir}/"
mv "${aggregatefile}" "latest.csv"
rclone move --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies "latest.csv" "${latestdir}/"
cd "${olddir}" || (echo "Could not switch back to old dir" && exit 1)
rmdir "${tempdir}"
