#!/bin/bash
if [[ -z ${1} ]]; then
	touch /etc/no-automatic-cosmos
fi
docker stop redis_redis-sentinel_1
