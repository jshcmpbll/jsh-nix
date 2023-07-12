# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "zroot/local/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-id/nvme-APPLE_SSD_AP0512M_C079415007DJRH1AK-part2";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    { device = "zroot/local/nix";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "zroot/safe/home";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    { device = "zroot/safe/persist";
      fsType = "zfs";
    };

  fileSystems."/sigma/media/tv" =
    { device = "sigma/media/tv";
      fsType = "zfs";
    };

  fileSystems."/sigma/media/movies" =
    { device = "sigma/media/movies";
      fsType = "zfs";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.ens1.useDHCP = lib.mkDefault true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
