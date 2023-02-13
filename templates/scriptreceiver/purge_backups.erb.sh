#!/bin/bash

thisyear=$(date +%Y)
lastyear=$(date +%Y -d "last year")
thismonth=$(date +%m)
lastmonth=$(date +%m -d "last month")

backupdir=${1}

if ! [[ -d ${backupdir} ]]; then
	echo "Usage: ${0} <backup directory>"
	echo "Example: ${0} /opt/mariadb_backup/backups/"
	exit 1
fi

cd "${backupdir}"
# We want to keep:
# * one backup per year for a year that is not this
# * one backup per month of this year that is not current month
# * one backup per day of current month
for year in $(ls -d 20*/ | sed 's_/$__'); do
	# If it is not this year
	if [[ "${year}" != "${thisyear}" ]]; then
		# We loop jan - nov
		for month in $(seq -w 1 11); do
			if [[ -d "${year}/${month}" ]]; then
				rm -r "${year}/${month}"
			fi
		done
		# If current month is january and we are dealing with last year we skip it
		if ! ([[ "${thismonth}" == "01" ]] && [[ "${year}" == "${lastyear}" ]]); then
			for day in $(seq -w 1 30); do
				if [[ -d "${year}/12/${day}" ]]; then
					rm -r "${year}/12/$day"
				fi
			done
		fi
	else
		# This means it is this year
		# so we loop each month of this year
		for month in $(ls -d ${year}/* | sed "s_${year}/__"); do
			nexttolastdayoflastmonth=$(date -d "${year}-${month}-01 + 1 month - 2 day" +"%d")
			# If it is not the current month, we delete all days except the last
			# unless it is january, because then we keep the days around untill february
			if [[ "${month}" != "${thismonth}" ]]; then
				for day in $(seq -w 1 ${nexttolastdayoflastmonth}); do
					if [[ -d "${year}/${month}/${day}" ]]; then
						rm -r "${year}/${month}/${day}/"
					fi
				done
			fi
		done
	fi
done
# Finally we remove any empty directories
find "${backupdir}" -type d -empty -delete
