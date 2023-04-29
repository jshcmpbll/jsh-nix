{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/" =
    { device = "zroot/local/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B2B7-803A";
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

  fileSystems."/mnt/CSAN" =
    { device = "csan";
      fsType = "zfs";
    };
  fileSystems."/home/jsh/Pictures" =
    { device = "csan/media/pictures";
      fsType = "zfs";
    };
  fileSystems."/home/jsh/Videos" =
    { device = "csan/media/videos";
      fsType = "zfs";
    };
  fileSystems."/home/jsh/Movies" =
    { device = "csan/media/movies";
      fsType = "zfs";
    };
  fileSystems."/home/jsh/TV" =
    { device = "csan/media/tv";
      fsType = "zfs";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp6s0f1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;
}
