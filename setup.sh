#! /bin/bash
set -xv

echo "parted /dev/$1 -- mklabel gpt"
echo "parted /dev/$1 -- mkpart primary 512MiB -110GiB"
echo "# parted /dev/$1 -- mkpart primary linux-swap -110GiB 100%"
echo "parted /dev/$1 -- mkpart ESP fat32 1MiB 512MiB"
echo "parted /dev/$1 -- set 2 boot on"

echo "mkfs.ext4 -L nixos /dev/$1p1"
echo "mkswap -L swap /dev/$1p2"
echo "mkfs.fat -F 32 -n boot /dev/$1p2"

echo "mount /dev/$1p1 /mnt"
echo "mkdir -p /mnt/boot"
echo "mount /dev/$1p2 /mnt/boot"

echo "swapon /dev/$1p2"

echo "nixos-generate-config --root /mnt"

echo "vim /mnt/etc/nixos/configuration.nix"

echo "nixos-install"

