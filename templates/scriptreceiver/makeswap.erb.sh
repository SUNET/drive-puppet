#!/bin/bash
# Clean up old swap version
if [[ -f /swapfile ]]; then
  swapoff -a
  sed -i 's_^/swapfile none swap sw 0 0_#/swapfile none swap sw 0 0_' /etc/fstab
  rm /swapfile
fi
# Create crypt swap that should play nice with puppet
if ! [[ -f /cryptswap1 ]]; then
  gb=$(free --gibi| grep Mem: | awk '{print $2}')
  fallocate -l "${gb}G" /cryptswap1
  chmod 600 /cryptswap1

  loop=$(losetup -f)
  losetup "${loop}" /cryptswap1
  cryptsetup open --type plain --key-file /dev/urandom "${loop}" cryptswap1
  mkswap /dev/mapper/cryptswap1
  swapon /dev/mapper/cryptswap1

  if ! grep -E '^/dev/mapper/cryptswap1' /etc/fstab; then
    echo '/dev/mapper/cryptswap1 none swap sw 0 0' >> /etc/fstab
  fi
fi
