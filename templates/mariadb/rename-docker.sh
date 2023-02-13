#!/bin/bash
touch /etc/no-automatic-cosmos
for i in $(systemctl list-unit-files | grep sunet-docker | grep enabled | awk '{print $1}'); do systemctl disable --now ${i}; done
for i in $(systemctl list-unit-files | grep mariadb | grep disabled | awk '{print $1}'); do rm /etc/systemd/system/${i}; done
rm -r /opt/docker*mariadb
run-cosmos -v
docker ps
rm /etc/no-automatic-cosmos
