#! /usr/bin/env bash


main()
{
case $1 in

  *tldr)
    TLDR
    ;;
  *d)
    echo "exit"
    ;;
  *help|*h|*)
    Help
    ;;
  esac
}

Help()
{
printf "This is the setup script for getting NixOS installed on a system via parted. The intent of this script is to take a device name for a storage volume and prepare the proper paritions and formats.\n\n"
printf "\tSyntax: setup [-h|d|c|v]\n\n"
printf "\th   Prints help function\n"
printf "\td   Drive setup\n"
printf "\tc   configuration via \$editor\n"
printf "\tv   Verbose mode\n"
printf "\n\nThis help function will run on any improper input. Run ./setup.sh tldr for concrete examples."
}

TLDR()
{
  printf "Here are some concrete examples\n"

}


#parted /dev/$1 -- mklabel gpt
#parted /dev/$1 -- mkpart primary 512MiB -110GiB
## parted /dev/$1 -- mkpart primary linux-swap -110GiB 100%
#parted /dev/$1 -- mkpart ESP fat32 1MiB 512MiB
#parted /dev/$1 -- set 2 boot on
#
#mkfs.ext4 -L nixos /dev/$1p1
#mkswap -L swap /dev/$1p2
#mkfs.fat -F 32 -n boot /dev/$1p2
#
#mount /dev/$1p1 /mnt
#mkdir -p /mnt/boot
#mount /dev/$1p2 /mnt/boot
#
#swapon /dev/$1p2
#
#nixos-generate-config --root /mnt
#
#vim /mnt/etc/nixos/configuration.nix
#
#nixos-install

main "$@"
