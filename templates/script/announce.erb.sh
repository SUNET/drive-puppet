#!/bin/bash

VALID_ARGS=$(getopt -o cdghi:m:s: --long create,delete,get,help,id:,message:,subject: -- "$@")
# shellcheck disable=SC2181
if [[ ${?} -ne 0 ]]; then
    exit 1;
fi

usage () {
  echo "${0}: -c|--create -m|--message <'Your announcement goes here'> -s|--subject <Your subject goes here>"
  echo "${0}: -d|--delete -i|--id <announcement_id>"
  echo "${0}: -g|--get"
  exit 1
}

eval set -- "${VALID_ARGS}"
# shellcheck disable=SC2078
while [ : ]; do
  case "$1" in
    -c | --create)
        method='POST'
        shift
        ;;
    -d | --delete)
        method='DELETE'
        shift
        ;;
    -g | --get)
        method='GET'
        shift
        ;;
    -h | --help)
        usage
        ;;
    -i | --id)
        argument="${2}"
        shift 2
        ;;
    -m | --message)
        message="${2}"
        shift 2
        ;;
    -s | --subject)
        subject="${2}"
        shift 2
        ;;
    *)
      break
      ;;
  esac
done

if [[ ${method} == 'DELETE' ]] && [[ -z ${argument} ]]; then
  usage
fi
if [[ ${method} == 'POST' ]]; then
  if [[ -z ${message} ]] || [[ -z ${subject} ]]; then
    usage
  fi
  argument='{"subject":"'${subject}'","message":"'${message}'", "plainMessage":"'${message}'", "groups": [], "userId": "admin", "activities": false, "notifications": true, "emails": false, "comments": false }'
fi

curl_cmd(){
  local method="${1}"
  if [[ ${method} == 'POST' ]] && [[ -n ${2} ]]; then
    local payload=(-d "${2}" -H "Content-Type: application/json")
  elif [[ ${method} == 'DELETE' ]] && [[ -n ${2} ]]; then
    local id="/${2}"
  fi
  local admin_app_password="<%= @admin_app_password %>"
  domain="$(hostname -d)"
  curl -X "${method}" -u "admin:${admin_app_password}" "${payload[@]}" -H 'OCS-APIRequest: true' "https://${domain}/ocs/v2.php/apps/announcementcenter/api/v1/announcements${id}"
}
curl_cmd "${method}" "${argument}"

