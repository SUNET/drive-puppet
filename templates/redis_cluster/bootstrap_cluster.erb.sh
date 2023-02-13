#!/bin/bash
my_host=$(hostname -f)
hosts=""
for index in 1 2 3; do
  cur_host="redis${index}.$(hostname -d)"
  if [[ "${my_host}" == "${cur_host}" ]]; then
    ip="$(hostname -I | awk '{print $1}')"
  else
    ip="$(host "${cur_host}" | grep "has address" | awk '{print $NF}')"
  fi
  for port in 6379 6380 6381; do
    hosts="${hosts} ${ip}:${port}"    
  done
done

redis-cli --no-auth-warning -a <%= @redis_password %> --cluster create ${hosts} --cluster-replicas 2
