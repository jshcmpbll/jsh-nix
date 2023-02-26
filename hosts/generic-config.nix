{ lib, config, pkgs, latest, ... }:
let
in
{
  imports = [
    ../dots/zsh.nix
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
          origin = ../dots/dunst/dunstrc;
          target = "/home/jsh/.config/dunst/dunstrc";
        }
        {
          origin = ../dots/Xresources;
          target = "/home/jsh/.Xresources";
        }
        {
          origin = ../dots/font-size;
          target = "/home/jsh/.urxvt/ext/font-size";
        }])
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        version = 2;
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

  fonts.fonts = with pkgs; [
    hermit
    source-code-pro
    terminus_font
    dejavu_fonts
  ];

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  ### SERVICES ###
  services = {

    xserver = {
      enable = true;
      autorun = true;
      desktopManager.xfce = {
        enable = true;
      };
      displayManager.lightdm = {
        enable = true;
        autoLogin.timeout = 10;
        background = "/home/jsh/.i3_background";
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
        };
      };
      xkbOptions = "ctrl:swapcaps";
    };

    openssh = {
      enable = true;
      forwardX11 = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
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

    #redshift = {
    #  enable = true;
    #  #brightness = {
    #  #  day = "1";
    #  #  night = "0.8";
    #  #};
    #  temperature = {
    #    day = 5500;
    #    night = 3500;
    #  };
    #};

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

  system.stateVersion = "22.11"; # Did you read the comment?
}

