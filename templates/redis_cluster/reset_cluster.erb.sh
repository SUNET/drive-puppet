#!/bin/bash
my_host=$(hostname -f)
hosts=""
redis_password="<%= @redis_password %>"
for index in 1 2 3; do
  cur_host="redis${index}.$(hostname -d)"
  if [[ "${my_host}" == "${cur_host}" ]]; then
    ip="$(facter networking.ip)"
  else
    ip="$(host "${cur_host}" | grep "has address" | awk '{print $NF}')"
  fi
  for port in 6379 6380 6381; do
    hosts="${hosts} ${ip}:${port}"
  done
done

for host in ${hosts}; do
        redis-cli --no-auth-warning -a "${redis_password}" -u "redis://${host}" flushall
        redis-cli --no-auth-warning -a "${redis_password}" -u "redis://${host}" cluster reset hard
done
redis-cli --no-auth-warning -a "${redis_password}" --cluster create ${hosts} --cluster-replicas 2
