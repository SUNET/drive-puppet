#!/bin/bash
# List usage for all buckets
date=$(date "+%Y%m%d")
hdate=$(date "+%Y-%m-%d")
htime=$(date "+%H:%M")
remotes=$(rclone listremotes | grep -E '^sto[3-4]')
location="<%= @location %>"
if [[ -n "${1}" ]]; then
	customer="${1}"
  location="${customer}-<%= @environment %>"
	allowmixedcustomers=yes
else
	customer="<%= @customer %>"
	allowmixedcustomers=no
fi
userjson=$(rclone cat --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies "statistics:drive-server-coms/${location}/users.json")
users=$(echo ${userjson} | jq -r '.| keys | .[]  | test("^((?!(^admin|^[_])).)*$")' | grep true | wc -l)
outfile1="${customer}-${date}-detailed.csv"
outfile2="${customer}-${date}.csv"
header="DATE:${hdate} TIME:${htime}"$'\n'
result1="${header}Project:Bucket;Files;MB;GB"$'\n'
result2="${header}Customer;Total GB;Users"$'\n'
foundwrongcustomer=0
totalMB=0
totalFiles=0

for remote in ${remotes}; do
	project=${remote}
	buckets=$(rclone --config /root/.rclone.conf lsjson "${project}" | jq -r '.[].Name' | grep -E -v '^statistics')

	for bucket in ${buckets}; do
		echo "${bucket}" | grep -E "${customer}|db-backups$" &>/dev/null
		status=${?}
		if [[ ${status} -ne 0 ]] && [[ "${allowmixedcustomers}" == "no" ]]; then
			((foundwrongcustomer += 1))
			echo "Found ${project}${bucket} not maching ${customer}"
			continue
		elif [[ ${status} -ne 0 ]] && [[ "${allowmixedcustomers}" == "yes" ]]; then
			echo "Found ${project}${bucket} not maching ${customer}"
			continue
		fi
		bucketinfo=$(rclone --config /root/.rclone.conf size "${project}${bucket}" --json)
		numfiles=$(jq '.count' <<<"${bucketinfo}")
		((totalFiles += numfiles))
		bytes=$(jq '.bytes' <<<"${bucketinfo}")
		KB=$((bytes / 1024))
		MB=$((KB / 1024))
		((totalMB += MB))
		GB=$((MB / 1024))
		result1="${result1}${project}${bucket};${numfiles};${MB};${GB}"$'\n'
		#printf '%s:%s \t Files: %s \t S3: %s MB \t %s GB\n' "${project}" "${bucket}" "${numfiles}" "${MB}" "${GB}"| expand -t 45
	done
done

totalGB=$((totalMB / 1024))
result2="${result2}${customer};${totalGB};${users}"

rclone mkdir "${location}:drive-${location}-share"
echo -n "${result1}" >"${outfile1}"
echo -n "${result2}" >"${outfile2}"

rclone copyto -c --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies "${outfile1}" "statistics:drive-storage-report/${customer}-usage/daily/${outfile1}"
rclone copyto -c --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies "${outfile2}" "statistics:drive-storage-report/${customer}-usage/daily/${outfile2}"

rclone copyto -c --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies "${outfile1}" "statistics:drive-storage-report/${customer}-usage/${customer}-latest-detailed.csv"
rclone copyto -c --no-check-certificate --webdav-headers "Host,sunet.drive.sunet.se" --use-cookies "${outfile2}" "statistics:drive-storage-report/${customer}-usage/${customer}-latest.csv"

rm "${outfile1}"
rm "${outfile2}"
exit ${foundwrongcustomer}
