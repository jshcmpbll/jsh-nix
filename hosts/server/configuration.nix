{ config, lib, pkgs, modulePaths, ... }:
{
  imports = [
    ../../dots/vnc.nix
    ./hardware-configuration.nix
    ../generic-config.nix
    (import ../../lib/home-file.nix
        [{
          origin = ../../dots/i3/server-config;
          target = "/etc/i3/config";
        }
        {
          origin = ../../dots/polybar/server-config.ini;
          target = "/home/jsh/.config/polybar/config.ini";
        }
        {
          origin = ../../dots/polybar/server-launch.sh;
          target = "/home/jsh/.config/polybar/launch.sh";
        }])
  ];

  virtualisation.docker.enable = true;

  boot = {
    loader = {
      grub = {
        extraEntries = ''
          menuentry "Windows 10" {
            search --set=root --file /EFI/Microsoft/Boot/bootmgfw.efi
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        '';
      };
    };
  };

  networking = {

    hostName = "jsh-server";
    hostId = "a6bbe9e1";
    useDHCP = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    interfaces.eth0.wakeOnLan.enable = true;
    interfaces.eth1.wakeOnLan.enable = true;
    #interfaces.*.wakeOnLan.enable = true;
    firewall = {
      enable = false;
    };
    wg-quick.interfaces = {
      ca = {
        address = [ "10.2.0.2/32" ];
        dns = [ "10.2.0.1" ];
        privateKeyFile = "/persist/pvpn-california";
        peers = [
          {
            publicKey = "4v/dB/ha+PGL0jihNVlVj81NGAFh6VndO9s4giDZEUw=";
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = "185.230.126.18:51820";
          }
        ];
        autostart = false; # Stop by running `systemctl start wg-quick-${name}`
      };
    };
  };
  #systemd.network.links."10-eth0" = {
  #  matchConfig.PermanentMACAddress = "34:97:f6:32:70:9d";
  #  linkConfig.Name = "eth0";
  #};
  #systemd.network.links."10-eth1" = {
  #  matchConfig.PermanentMACAddress = "34:97:f6:31:ad:4d";
  #  linkConfig.Name = "eth1";
  #};
  #systemd.network.links."10-eth3" = {
  #  matchConfig.PermanentMACAddress = "ea:5f:02:a6:52:7d";
  #  linkConfig.Name = "eth2";
  #};

  services = {
    xserver = {
      displayManager.setupCommands = ''
        /nix/store/rqikhbksyzdgaddq50nqrnlgg6c3gky9-nvidia-settings-515.48.07/bin/nvidia-settings --assign CurrentMetaMode="DPY-1: nvidia-auto-select @2560x1440 +2160+0 {ViewPortIn=2560x1440, ViewPortOut=2560x1440+0+0}, DPY-0: 3840x2160 @2160x3840 +0+0 {ViewPortIn=2160x3840, ViewPortOut=3840x2160+0+0, Rotation=90}"
      '';
      videoDrivers = [ "nvidia" ];
      displayManager.autoLogin = {
        enable = true;
        user = "jsh";
      };
    };
    tailscale.enable =true;

    acpid = {
      enable = true;
      handlers.brightnessup = {
        event = "video/brightnessup*";
        action = "bld=/sys/class/backlight/*/brightness; echo $(($(cat $bld)+5)) | tee $bld";
      };
      handlers.brightnessdown = {
        event = "video/brightnessdown*";
        action = "bld=/sys/class/backlight/*/brightness; echo $(($(cat $bld)-5)) | tee $bld";
      };
      handlers.volumeup = {
        event = "button/volumeup*";
        action = "/run/wrappers/bin/su jsh -c '/run/current-system/sw/bin/pactl --server=/run/user/1000/pulse/native set-sink-volume @DEFAULT_SINK@ +10%'";
      };
      handlers.volumedown = {
        event = "button/volumedown*";
        action = "/run/wrappers/bin/su jsh -c '/run/current-system/sw/bin/pactl --server=/run/user/1000/pulse/native set-sink-volume @DEFAULT_SINK@ -10%'";
      };
      handlers.volumemute = {
        event = "button/mute*";
        action = "/run/wrappers/bin/su jsh -c '/run/current-system/sw/bin/pactl --server=/run/user/1000/pulse/native set-sink-mute @DEFAULT_SINK@ toggle'";
      };
      #handlers.micmute = {
      #  event = "button/f20*";
      #  action = "/run/wrappers/bin/su jsh -c '/run/current-system/sw/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle'";
      #};

    };


    syncoid = {
      enable = true;
      user = "root";
      group = "root";
      commonArgs = [ "--no-privilege-elevation" "--debug" ];
      localSourceAllow = [
        "change-key"
        "compression"
        "create"
        "mount"
        "mountpoint"
        "receive" 
        "rollback"
        "bookmark"
        "hold"
        "send"
        "snapshot"
        "destroy"
      ];
      # Permissions the local `syncoid` user gets to manipulate local ZFS datasets that
      # are the targets for backups. 
      # NOTE: you must ensure the remote syncoid user has similar permissions. 
      localTargetAllow = [
        "change-key"
        "compression"
        "create"
        "mount"
        "mountpoint"
        "receive"
        "rollback"
        "bookmark"
        "hold"
        "send"
        "snapshot"
        "destroy"
      ];
      commands = {
        # CSAN
        "zroot-csan-home" = {
          source = "zroot/safe/home";
          recursive = true;
          target = "csan/jsh-server/home";
        };
        "zroot-csan-persist" = {
          source = "zroot/safe/persist";
          recursive = true;
          target = "csan/jsh-server/persist";
        };
        # SIGMA
        #"zroot-sigma-server" = {
        #  source = "zroot/safe";
        #  recursive = true;
        #  target = "sigma/server";
        #};
        #"csan-sigma-media" = {
        #  source = "csan/media";
        #  recursive = true;
        #  target = "sigma/media";
        #};
        # REIN
        "zroot-rein-home" = {
          source = "zroot/safe/home";
          recursive = true;
          target = "rein/jsh-server/home";
        };
        "zroot-rein-persist" = {
          source = "zroot/safe/persist";
          recursive = true;
          target = "rein/jsh-server/persist";
        };
        "csan-rein-media" = {
          source = "csan/media";
          recursive = true;
          target = "rein/media";
        };
      };
    };
    plex = {
      enable = true;
      user = "jsh";
    };

  };

  ### HARDWARE ###

  hardware = {

    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };

    enableAllFirmware = true;

    pulseaudio = {
      enable = true;
      support32Bit = true;
      package = pkgs.pulseaudioFull;
      extraConfig = "load-module module-switch-on-connect";
    };

    opengl = {
      enable = true;
      driSupport32Bit = true;
      driSupport = true;
    };
  };

  ### HARDWARE ###
}
