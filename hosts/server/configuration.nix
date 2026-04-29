{ config, lib, pkgs, modulePaths, options, latest2, kiro-gateway-src, ... }:
{
  imports =
    let
      i3-server = builtins.readFile ../../dots/i3/server-config;
      i3-zoom = builtins.readFile ../../dots/i3/zoom-config;
      i3-config = pkgs.writeText "config" (i3-server + "\n" + i3-zoom);
    in
    [
      ../../dots/vnc.nix
      ../../dots/docker.nix
      ./hardware-configuration.nix
      ../generic-config.nix
      (import ../../lib/home-file.nix
        [{
          origin = i3-config;
          target = "/etc/i3/config";
        }
          {
            origin = ../../dots/polybar/server-config.ini;
            target = "/home/jsh/.config/polybar/config.ini";
          }
          {
            origin = ../../dots/firefox/profiles.ini;
            target = "/home/jsh/.mozilla/firefox/profiles.ini";
          }
          {
            origin = ../../dots/firefox/proxy-user.js;
            target = "/home/jsh/.mozilla/firefox/proxy-profile/user.js";
          }
          {
            origin = ../../dots/polybar/server-launch.sh;
            target = "/home/jsh/.config/polybar/launch.sh";
          }])
    ];

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
    hosts = {
      #"127.0.0.1" = [ "" ];
    };
    #useDHCP = true;
    useNetworkd = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    #interfaces.eth0.wakeOnLan.enable = true;
    #interfaces.eth1.wakeOnLan.enable = true;
    wg-quick.interfaces = {
      ca = {
        configFile = "/persist/ca.conf";
        autostart = false;
      };
      can = {
        configFile = "/persist/can.conf";
        autostart = false;
      };
      lydon = {
        configFile = "/persist/lydon.conf";
        autostart = false;
      };
    };
  };
  systemd.network.enable = true;
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
        ${config.hardware.nvidia.package.settings.outPath}/bin/nvidia-settings --assign CurrentMetaMode="DP-0: nvidia-auto-select +2560+0, HDMI-0: nvidia-auto-select +0+0 {viewportin=2560x1440}"
      '';
      videoDrivers = [ "nvidia" ];
      #deviceSection = ''
      #  Option "VirtualHeads" "1"
      #'';
    };

    ai-stack = {
      enable = true;
      ollama = {
        acceleration = "cuda";
        package = latest2.ollama-cuda.overrideAttrs (finalAttrs: _: {
          version = "0.15.5";
          src = pkgs.fetchFromGitHub {
            owner = "ollama";
            repo = "ollama";
            tag = "v${finalAttrs.version}";
            hash = "sha256-VJrAUHX+BVQXsH34BDI4YqVXEqD14ERnKhSpMByAdrQ=";
          };
          vendorHash = "sha256-r7bSHOYAB5f3fRz7lKLejx6thPx0dR4UXoXu0XD7kVM=";
        });
      };
      hermes = {
        extraProviders.kiro = {
          baseUrl = "http://127.0.0.1:${toString config.services.kiro-gateway.port}/v1";
          model = "claude-sonnet-4.6";
        };
        environmentFiles = [ "/persist/hermes-secrets.env" ];
      };
      openWebUI.openFirewall = true;
    };

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
  };

  virtualisation.oci-containers.backend = "docker";

  services.kiro-gateway = {
    enable = true;
    src = kiro-gateway-src;
  };

  services.cron = {
      enable = true;

      systemCronJobs = [
        # Add "export NIX_PATH='nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels" for access to allow access to nix
        #"cron-date     user     script | 2>&1 tee logfile_$EPOCHSECONDS.log"
      ];
    };
  systemd.services.wakeonlan = {
    description = "Reenable wake on lan every boot";
    after = [ "network.target" ];
    wantedBy = [ "default.target" ];
    path = [ pkgs.ethtool ];
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = "true";
    };
    script = ''
      ethtool -s enp6s0f1 wol g
      ethtool -s enp5s0 wol g
    '';
  };

  ### HARDWARE ###

  hardware = {
    nvidia = {
      open = false;
      modesetting.enable = true;
    };
    enableAllFirmware = true;
    pulseaudio = {
      enable = false;
      support32Bit = true;
      package = pkgs.pulseaudioFull;
      extraConfig = ''
        load-module module-switch-on-connect auth-anonymous=1
        load-module module-raop-discover
      '';
    };
  };

  ### HARDWARE ###]
}
