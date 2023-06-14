{ lib, config, pkgs, latest, ... }:
{
  imports = [
    ../../dots/vnc.nix
    ./hardware-configuration.nix
    ../generic-config.nix
    (import ../../lib/home-file.nix
        [{
          origin = ../../dots/i3/lenovo-config;
          target = "/etc/i3/config";
        }
        {
          origin = ../../scripts/screens;
          target = "/home/jsh/.config/screens";
        }
        {
          origin = ../../dots/polybar/lenovo-config.ini;
          target = "/home/jsh/.config/polybar/config.ini";
        }
        {
          origin = ../../dots/polybar/lenovo-launch.sh;
          target = "/home/jsh/.config/polybar/launch.sh";
        }])
  ];

  boot.kernelModules = [ "kvm-amd" ];

  networking = {

    hostName = "jsh-lenovo";
    hostId = "a6bbe9e2";
    #useDHCP = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    firewall = {
      enable = false;
    };
    usePredictableInterfaceNames = true;
    wireless = {
      enable = true;
      interfaces = [
        "wlp2s0"
      ];
      userControlled.enable = true;
      allowAuxiliaryImperativeNetworks = true;
      environmentFile = "/persist/wireless.env";
      networks = {
        "The LAN Before Time" = {
          psk = "@PSK_HOME@";
          priority = 1;
        };
        "iPhone-13-128" = {
          psk = "@PSK_PHONE@";
          priority = 2;
        };
        "aainflight.com" = {
          authProtocols = [
            "NONE"
            "WPA-PSK"
            "WPA-EAP"
            "SAE"
            "FT-PSK"
            "FT-EAP"
            "FT-SAE"
          ];
          priority = 1;
        };
      };
    };
    wg-quick.interfaces = {
      ca = {
        address = [ "10.2.0.2/32" ];
        dns = [ "10.2.0.1" ];
        privateKeyFile = "/persist/pvpn-california";
        peers = [
          {
            publicKey = "D2ljOyE4iCiNDTEXME6qcraH97JRAWXsOTGXCb/vklY=";
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = "91.219.212.194:51820";
          }
        ];
        autostart = false; # Start by running `systemctl start wg-quick-${name}`
      };
      can = {
        address = [ "10.2.0.2/32" ];
        dns = [ "10.2.0.1" ];
        privateKeyFile = "/persist/pvpn-canada";
        peers = [
          {
            publicKey = "28hrybwV/NiiMXvl1ynBvDvEvs1m8ABUzyvkQ7+ST3I=";
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = "146.70.198.34:51820";
          }
        ];
        autostart = false; # Start by running `systemctl start wg-quick-${name}`
      };
    };
  };

  hardware = {
    pulseaudio = {
      enable = true;
      support32Bit = true;
      package = pkgs.pulseaudioFull;
      extraConfig = "load-module module-switch-on-connect";
    };
    bluetooth.package = pkgs.bluezFull;
  };

  services = {

    xserver = {
      videoDrivers = [ "amdgpu" ];
    };
    tailscale.enable = true;

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
      handlers.micmute = {
        event = "button/f20*";
        action = "/run/wrappers/bin/su jsh -c '/run/current-system/sw/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle'";
      };

    };

    create_ap = {
      enable = false;
      settings = {
        SSID = "The LAN Before Time";
        PASSPHRASE = "";
        WIFI_IFACE = "wlp4s0f4u1";
        INTERNET_IFACE = "ca";
      };
    };

  };

  services.fprintd.enable = true;

  security.pam.services = {
    login.fprintAuth = true;
    xscreensaver.fprintAuth = true;
  };

  system.stateVersion = "22.11"; # Did you read the comment?
}

