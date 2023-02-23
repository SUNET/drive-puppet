#!/bin/bash
# Clean up old swap version
if [[ -f /cryptswap1 ]]; then
  swapoff -a
  sed -i 's_^/dev/mapper/cryptswap1 none swap sw 0 0__' /etc/fstab
  rm /swapfile
fi
if ! [[ -f /swapfile ]]; then
  gb=$(free --gibi| grep Mem: | awk '{print $2}')
  fallocate -l "${gb}G" /swapfile
  chmod 600 /swapfile

  mkswap /swapfile
  swapon /swapfile

  if ! grep -E '^/swapfile' /etc/fstab; then
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
  fi
else
  swapon -a
fi
