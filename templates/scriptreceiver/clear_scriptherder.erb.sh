#!/bin/bash

for job in $(/usr/local/bin/scriptherder | grep -Ev " OK |Start|^$|===" | awk -F ' ' '{print $9}'); do
  /usr/local/bin/scriptherder --mode wrap --syslog --name "${job}" -- /bin/true
done
