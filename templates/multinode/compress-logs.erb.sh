#!/bin/bash

no_files=30 # Keep this many files as an archive, script is run once a week
# We sleep a deterministic amount of time, which will be between 0 an 128 m and allways the same within
# a specific host, but will differ between hosts
sleep $((16#$(ip a | grep "link/ether" | head -1 | awk -F ':' '{print $6}' | awk '{print $1}') / 2))m

for logfile in $(ls /opt/multinode/*/{nextcloud.log,server/server.log}); do
	if [[ -f ${logfile}.gz.${no_files} ]]; then
		rm ${logfile}.gz.${no_files}
	fi
	for i in $(seq 1 $((no_files - 1)) | sort -nr); do
		if [[ -f ${logfile}.gz.${i} ]]; then
			mv ${logfile}.gz.${i} ${logfile}.gz.$((i + 1))
		fi
	done
	if [[ -f ${logfile}.gz ]]; then
		mv ${logfile}.gz ${logfile}.gz.1
	fi
	cat ${logfile} | gzip >${logfile}.gz && echo '' >${logfile}
done
