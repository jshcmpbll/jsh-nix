{ lib, config, inputs, pkgs, latest, ... }:
let
in
  imports = [
    ../dots/apple-cursor.nix
    ../dots/config.nix
    ../dots/shells.nix
    ../dots/vim.nix
    ../dots/pkgs.nix
    ../dots/zfs.nix
    ../users/jsh.nix
    (import ../lib/home-file.nix
      [{
        origin = ../dots/rofi/config.rasi;
        target = "/home/jsh/.config/rofi/config.rasi";
      }
        {
          origin = ../dots/rofi/theme.rasi;
          target = "/home/jsh/.config/rofi/theme.rasi";
        }
        {
          origin = ../dots/dunst/dunstrc;
          target = "/home/jsh/.config/dunst/dunstrc";
        }
        {
          origin = ../dots/Xresources;
          target = "/home/jsh/.Xresources";
        }
        {
          origin = /persist/ssh-config;
          target = "/home/jsh/.ssh/config";
        }
        {
          origin = ../dots/tmux.conf;
          target = "/home/jsh/.tmux.conf";
        }
        {
          origin = ../dots/font-size;
          target = "/home/jsh/.urxvt/ext/font-size";
        }
        {
          origin = ../scripts/sf-mono;
          target = "/home/jsh/.config/.sf-mono/.setup";
        }
        {
          origin = ../dots/zathurarc;
          target = "/home/jsh/.config/zathura/zathurarc";
        }])
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        default = 0;
        devices = [ "nodev" ];
        useOSProber = true;
        efiSupport = true;
        configurationLimit = 100;
      };
    };
    initrd.verbose = false;
    consoleLogLevel = 0;
    kernelParams = [ "quiet" "udev.log_level=3" ];
  };

  time.timeZone = "America/Los_Angeles";

  location = {
    latitude = 33.9;
    longitude = -118.1;
  };

  fonts.packages = with pkgs; [
    hermit
    source-code-pro
    terminus_font
    dejavu_fonts
    helvetica-neue-lt-std
    garamond-libre
    lato
  ];

  nix = {
    settings = {
      trusted-users = [
        "jsh"
      ];
    };
    optimise = {
      automatic = true;
      dates = ["00:00"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  programs.ssh.startAgent = true;

  services = {

    xserver = {
      enable = true;
      autorun = true;
      displayManager.gdm = {
        enable = true;
        autoLogin.delay = 10;
        autoSuspend = false;
        wayland = false;
      };
      displayManager.defaultSession = "none+i3";
      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;
        configFile = "/etc/i3/config";
      };
      layout = "us";
      libinput = {
        enable = true;
        touchpad = {
          disableWhileTyping = true;
          naturalScrolling = true;
          tapping = false;
          accelSpeed = "10";
          accelProfile = "flat";
        };
      };
      xkbOptions = "ctrl:swapcaps";
    };

    openssh = {
      enable = true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    pcscd.enable = true;

    avahi.enable = true;
    avahi.nssmdns = true;

    printing = {
      enable = true;
      drivers = [ pkgs.brlaser ];
    };

    blueman.enable = true;

    udev.packages = [ pkgs.libu2f-host ];

    redshift = {
      enable = true;
      brightness = {
        day = "1";
        night = "0.8";
      };
      temperature = {
        day = 5500;
        night = 3500;
      };
    };

    usbmuxd = {
      enable = true;
    };

    atd = {
      enable = true;
      allowEveryone = true;
    };

    ofono = {
      enable = true;
    };

    tlp.enable = true;

  };

  systemd.services = {
    #x11vnc = {
    #  enable = true;
    #  path = [ pkgs.gawk pkgs.nettools ];
    #  description = "VNC server";
    #  serviceConfig = {
    #    type = "simple";
    #    ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever";
    #  };
    #  reloadIfChanged = true;
    #  restartIfChanged = true;
    #  after = [ "multi-user.target" ];
    #};
  };

  ### SERVICES ###

  ### HARDWARE ###
  hardware = {

    sane = {
      enable = true;
      brscan4 = {
        enable = true;
        netDevices = {
          home = {
            model = "MFC-L2710DW";
            ip = "192.168.0.53";
          };
        };
      };
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          # Set this so that I could connect to airpods
          ControllerMode = "bredr";
        };
      };
    };

  };

  system.stateVersion = "23.11"; # Did you read the comment?
}
