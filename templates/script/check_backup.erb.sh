#!/bin/bash

project="${1}"
bucket="${2}"
declare -a sixmonths=('mau')
output_status="OK"
exit_status=0
problems=""
num_problems=0
data_dir='/opt/backups/data'
for project in $(ls ${data_dir}); do
	for bucket in $(ls ${data_dir}/${project}/ | sed 's/\.dat$//'); do
    issixmonths="false"
    for customer in "${sixmonths[@]}"; do
      if [[ "${bucket}" =~ ${customer} ]]; then
        issixmonths="true"
      fi
    done
    number_of_full_to_keep='<%= @full_backup_retention %>'
    if [[ "${issixmonths}" == "true" ]]; then
      number_of_full_to_keep=6
    fi
    max_num_inc=$((32 * number_of_full_to_keep))
    max_num_full=$((2 * number_of_full_to_keep))
    
		tabular_data=$(cat "${data_dir}/${project}/${bucket}.dat")
		# We warn if there are too many old backups
		num_full=$(echo "${tabular_data}" | grep -c full)
		num_inc=$(echo "${tabular_data}" | grep -c inc)
		if [[ ${num_inc} -gt ${max_num_inc} ]] || [[ ${num_full} -gt ${max_num_full} ]]; then
			problems="${problems} Too many backups: ${project}:${bucket}"
			num_problems=$((num_problems + 1))
			if [[ ${exit_status} -ne 2 ]]; then
				output_status="WARNING"
				exit_status=1
			fi
		fi

		latest_full=$(echo "${tabular_data}" | grep full | sort | tail -1)
		latest_inc=$(echo "${tabular_data}" | grep inc | sort | tail -1)

		latest_full_date=$(date -d "$(echo "${latest_full}" | awk '{print $2}' | sed 's/T/ /' | sed -e 's/\([0-9][0-9]\)\([0-9][0-9]\)Z/:\1:\2/' -e 's/\(20[0-9][0-9]\)\([0-9][0-9]\)/\1-\2-/')" +%s)
		latest_inc_date=$(date -d "$(echo "${latest_inc}" | awk '{print $2}' | sed 's/T/ /' | sed -e 's/\([0-9][0-9]\)\([0-9][0-9]\)Z/:\1:\2/' -e 's/\(20[0-9][0-9]\)\([0-9][0-9]\)/\1-\2-/')" +%s)

		now=$(date +%s)
		thirtytwodaysinseconds=$((32 * 24 * 60 * 60))
		twodaysinseconds=$((2 * 24 * 60 * 60))

		seconds_since_full=$((now - latest_full_date))
		seconds_since_inc=$((now - latest_inc_date))

		# We say that it is critical if backups are too old
		if [[ ${seconds_since_full} -gt ${thirtytwodaysinseconds} ]] || [[ ${seconds_since_inc} -gt ${twodaysinseconds} ]]; then
			if [[ ${seconds_since_full} -gt ${twodaysinseconds} ]]; then
				num_problems=$((num_problems + 1))
				problems="${problems} Too old backups: ${project}:${bucket}"
				output_status="CRITICAL"
				exit_status=2
			fi
		fi

	done
done
if [[ -z ${problems} ]]; then
	problems="No problems detected"
fi

output="${output_status}: ${problems} | num_problems=${num_problems};1;1;;"
echo "${output}"
exit ${exit_status}
