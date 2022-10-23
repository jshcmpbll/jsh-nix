{ lib, config, pkgs, latest, ... }:
{
  imports = [
      ./hardware-configuration.nix
      ../generic-config.nix
      ../../wifi.nix
      (import ../../lib/home-file.nix
        [ { origin = ../../dots/i3/lenovo-config;
            target = "/etc/i3/config";
          }
          { origin = ../../scripts/screens;
            target = "/home/jsh/.config/screens";
          }
          { origin = ../../dots/polybar/lenovo-config.ini;
            target = "/home/jsh/.config/polybar/config.ini";
          }
          { origin = ../../dots/polybar/lenovo-launch.sh;
            target = "/home/jsh/.config/polybar/launch.sh";
          }
        ])
  ];

  networking = {

    hostName = "jsh-lenovo";
    hostId = "a6bbe9e2";
    #useDHCP = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    firewall = {
      enable = false;
    };
    usePredictableInterfaceNames = true;
  };

  services = {

    xserver = {
      videoDrivers = [ "amdgpu" ];
    };

    acpid = {
      enable = true;
      handlers.brightnessup = {
        event = "video/brightnessup*";
        action = "bld=/sys/class/backlight/*/brightness; echo $(($(cat $bld)+51)) | tee $bld";
      };
      handlers.brightnessdown = {
        event = "video/brightnessdown*";
        action = "bld=/sys/class/backlight/*/brightness; echo $(($(cat $bld)-51)) | tee $bld";
      };
      handlers.volumeup = {
        event = "button/volumeup*";
        action = "pactl set-sink-volume @DEFAULT_SINK@ +10%";
      };
      handlers.volumedown = {
        event = "button/volumedown*";
        action = "pactl set-sink-volume @DEFAULT_SINK@ -10%";
      };
      handlers.volumemute = {
        event = "button/mute*";
        action = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
      };
      handlers.micmute = {
        event = "button/f20*";
        action = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
      };

    };

  };
  
  services.fprintd.enable = true;

  security.pam.services = {
    login.fprintAuth = true;
    xscreensaver.fprintAuth = true;
  };

  system.stateVersion = "22.05"; # Did you read the comment?
}
