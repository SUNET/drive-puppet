#!/bin/bash
# We sleep a deterministic amount of time, which will be between 0 an 128 m and allways the same within# a specific host, but will differ between hosts, making sure we don't restart at the same time
sleep $((16#$(ip a | grep "link/ether" | head -1 | awk -F ':' '{print $6}' | awk '{print $1}') / 2))m

# Restart satosa
/usr/bin/systemctl restart docker-satosa.service
