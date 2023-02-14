#!/bin/bash

if ! [[ -f /swapfile ]]; then
  gb=$(free --gibi| grep Mem: | awk '{print $2}')
  fallocate -l "${gb}G" /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  if ! grep -E '^(#)?/swapfile' /etc/fstab; then
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
  fi
fi
