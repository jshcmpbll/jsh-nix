{ lib, config, pkgs, latest, ... }:
let
  myFirefox = pkgs.wrapFirefox pkgs.firefox-esr-unwrapped {
    cfg = { smarctcardSupport = true; };
    nixExtensions = [
      (pkgs.fetchFirefoxAddon {
        name = "1password";
        url = "https://addons.mozilla.org/firefox/downloads/file/3972472/1password_x_password_manager-2.3.7.xpi";
        sha256 = "sha256:9aaee3215d05faa802d83c5a355405d1ba8659f502aacd32aa44c036d2d6d354";
      })
      (pkgs.fetchFirefoxAddon {
        name = "ublock";
        url = "https://addons.mozilla.org/firefox/downloads/file/3933192/ublock_origin-1.42.4-an+fx.xpi"; # Get this from about:addons
        sha256 = "sha256:1kirlfp5x10rdkgzpj6drbpllryqs241fm8ivm0cns8jjrf36g5w";
      })
    ];
  };
in
{
  imports = [
    ../dots/zsh.nix
    ../dots/vim.nix
    ../dots/pkgs.nix
    ../dots/zfs.nix
    ../users/jsh.nix
    (import ../lib/home-file.nix
      [ { origin = ../dots/rofi/config.rasi;
          target = "/home/jsh/.config/rofi/config.rasi";
        }
        { origin = ../dots/dunst/dunstrc;
          target = "/home/jsh/.config/dunst/dunstrc";
        }
      ])
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
    libvirtd = {
      enable = true;
    };
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

  system.stateVersion = "22.05"; # Did you read the comment?
}

