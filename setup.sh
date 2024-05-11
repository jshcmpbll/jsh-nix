#! /usr/bin/env bash

set -x

setup_disk() {
 local disk="${1}"
 blkdiscard -f "${disk}" || true

 parted --script --align=optimal  "${disk}" -- \
 mklabel gpt \
 mkpart ESP fat32 1MiB 1GiB \
 mkpart swap 1GiB 10GiB \
 mkpart zroot 10GiB 100% \
 set 1 boot on

 partprobe "${disk}"
 udevadm settle

 mkfs.fat -F 32 -n boot /dev/sda1
 mkswap -L swap /dev/sda2


 ATA_PATH=$(get_by_id_path ${disk})
 zpool create -f zroot $ATA_PATH-part3
 zfs set compression=on zroot

 zfs create -p -o mountpoint=legacy zroot/root
 zfs create -p -o mountpoint=legacy zroot/home
 zfs create -p -o mountpoint=legacy zroot/peresist
 zfs create -p -o mountpoint=legacy zroot/nix

 zfs set xattr=sa zroot
 zfs set acltype=posixacl zroot

 zfs set atime=off zroot/nix
 zfs set xattr=sa zroot/nix
 zfs set acltype=posixacl zroot/nix
 
 mount -t zfs zroot/root /mnt
 mkdir -p /mnt/{boot,home,persist,nix}
 mount -t vfat /dev/sda1 /mnt/boot
 mount -t zfs zroot/nix /mnt/nix
 mount -t zfs zroot/home /mnt/home
 mount -t zfs zroot/persist /mnt/persist
 
 swapon $ATA_PATH-part2
}

get_by_id_path() {
    local device_path="$1"
    local by_id_path=""

    # Check if the device path exists
    if [ -e "$device_path" ]; then
        # Get the device's ATA ID using udevadm
        ata_id=$(udevadm info --query=property --name="$device_path" | grep ID_SERIAL= | cut -d'=' -f2)

        # Construct the path in /dev/disk/by-id
        by_id_path="/dev/disk/by-id/ata-$ata_id"
    else
        echo "Error: Device path $device_path does not exist"
        return 1
    fi

    echo "$by_id_path"
}

setup_disk "${1}"
