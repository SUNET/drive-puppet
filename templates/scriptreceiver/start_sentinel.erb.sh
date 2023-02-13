#!/bin/bash
docker start redis_redis-sentinel_1
if [[ -z ${1} ]]; then
	rm /etc/no-automatic-cosmos
fi
