#!/bin/bash
# Clean up old swap version
swapoff -a
cryptsetup remove cryptswap1
sed -i 's_^/dev/mapper/cryptswap1 none swap sw 0 0__' /etc/fstab
sed -i 's_/swapfile none swap sw 0 0__' /etc/fstab
sed -i 's_cryptswap1 /swapfile /dev/urandom swap,offset=1024,cipher=aes-xts-plain64__' /etc/crypttab
rm /swapfile
rm /cryptswap1
