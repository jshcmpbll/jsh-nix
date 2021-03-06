{ config, pkgs, ... }:
let
  nix-garage = builtins.fetchGit {
    url = "https://github.com/nebulaworks/nix-garage";
    ref = "master";
  };
  garage-overlay = import (nix-garage.outPath + "/overlay.nix");
  overlay = import <nixpkgs> { overlays = [ garage-overlay ]; };


in
{
  imports =
    [
      /home/jsh/git/jsh-nix/users/jsh.nix
      /etc/nixos/hardware-configuration.nix
      <home-manager/nixos>
      <nixpkgs/nixos/modules/services/hardware/sane_extra_backends/brscan4.nix>
    ];
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import <nixpkgs-unstable> {
        config = config.nixpkgs.config;
      };
    };
  };

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
        extraEntries = ''
          menuentry "Windows 10" {
            search --set=root --file /EFI/Microsoft/Boot/bootmgfw.efi
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        '';
      };
    };
    supportedFilesystems = [ "zfs" ];
  };


  time.timeZone = "America/Los_Angeles";

  location = {
    latitude = 33.9;
    longitude = -118.1;
  };

  environment.variables = {
    EDITOR = "${pkgs.vim}/bin/vim";
  };

  fonts.fonts = with pkgs; [
    hermit
    source-code-pro
    terminus_font
    dejavu_fonts
  ];

  ### NETWORKING ###

  networking = {

    hostName = "jsh-server";
    hostId = "a6bbe9e1";
    useDHCP = true;
    interfaces.enp5s0.useDHCP = true;
    firewall = {
      enable = false;
      # allowedTCPPorts = [ ... ];
      # allowedUDPPorts = [ 500 4500 ];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp5s0";
    };

  };

  ### NETWORKING ###




  ### PACKAGES ###  

  environment.systemPackages = with pkgs; [
    ntfs3g
    wget
    vim
    rxvt_unicode
    chromium
    i3-gaps
    slack
    spotify
    unzip
    scrot
    tldr
    tlp
    zsh
    neofetch
    htop
    gtk3
    lightdm
    lightdm_gtk_greeter
    git
    git-lfs
    unstable.github-cli
    oh-my-zsh
    rofi
    dunst
    ffmpeg
    gimp
    gnumake
    vlc
    which
    nmap
    ncat
    python38Packages.grip
    zathura
    zfs
    unstable.zoom-us
    unstable.spotifyd
    tree
    feh
    file
    fdupes
    unstable.discord
    silver-searcher
    screen
    rsync
    restic
    polybarFull
    ncurses
    ncdu
    jq
    hddtemp
    google-cloud-sdk
    awscli2
    unstable.azure-cli
    _1password
    tmux
    pavucontrol
    xclip
    os-prober
    woeusb
    cudatoolkit
    glxinfo
    youtube-dl
    unrar
    lsof
    yubikey-manager
    digikam
    restic
    polybar
    sxiv
    mpv
    picom
    killall
    vulnix
    aspell
    aspellDicts.en
    blueman
    wine
    #lutris
    vulkan-loader
    vulkan-tools
    simple-scan
    sane-airscan
    cava
    redshift
    steam
    unstable.obs-studio
    #obs-ndi
    #ndi
    linuxPackages.v4l2loopback
    pywal
    yarn
    smartmontools
    pciutils
    xfce.thunar
    kubectl
    sshfs
    lm_sensors
    ofono-phonesim
    unstable.teams
    unstable.citrix_workspace_20_09_0
    kompose
    kubectl
    kubernetes
    kubernetes-helm
    synergy
    yq
    yaml2json
    yj
    iperf3
    usbutils
    firefox
    #unstable.terraform
    #terraform_0_11
    #terraform_0_12
    #unstable.terraform_0_13
    #terraform_0_15
    terraform-providers.google
    tigervnc
    eagle
    prometheus
    audacity
    _1password-gui
    foremost
    samba
    libheif
    nixpkgs-fmt
    okular
    overlay.codefresh
    unstable.exodus
    unstable.minecraft
    unstable.guvcview
    sshfs-fuse
    dmidecode
    protonvpn-cli
    freecad
    unstable.odafileconverter
    unstable.fluxcd
    unstable.argocd
    exiftool
    mediainfo
    tesseract
    pdfsandwich
    gnupg
    unstable.python37
    unstable.python37Packages.pip
    bind
    nix-prefetch-git
    libreoffice
    mkdocs
    unstable.joplin
    wireshark-qt
    wireshark-cli
    nodePackages.prettier
    php
  ];

  ### PACKAGES ###




  ### SERVICES ###
  services = {

    xserver = {
      enable = true;
      autorun = true;
      displayManager.autoLogin = {
        enable = true;
        user = "jsh";
      };
      displayManager.lightdm = {
        enable = true;
        autoLogin.timeout = 10;
        background = "/mnt/CSAN/Media/Pictures/backgrounds/Bison-BW-Looking-Left.JPG";
      };
      displayManager.defaultSession = "none+i3";
      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;
      };
      layout = "us";
      videoDrivers = [ "nvidia" ];
      libinput = {
        enable = true;
        disableWhileTyping = true;
        naturalScrolling = true;
        tapping = false;
      };
      xkbOptions = "ctrl:swapcaps";
    };

    samba = {
      enable = true;
      syncPasswordsByPam = true;
      shares.csan =
        {
          path = "/mnt/CSAN";
          "read only" = false;
          "guest ok" = false;
          writeable = true;
          comment = "Campbell SAN";
        };
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

    plex = {
      enable = true;
      user = "jsh";
    };

    zfs = {
      autoScrub.enable = true;
      autoSnapshot = {
        daily = 1;
        enable = true;
      };
    };

  };

  systemd.services = {
    x11vnc = {
      enable = true;
      path = [ pkgs.gawk pkgs.nettools ];
      wantedBy = [ "multi-user.target" ];
      requires = [ "graphical.target" ];
      description = "VNC server";
      serviceConfig = {
        type = "simple";
        ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :0 -auth /home/jsh/.Xauthority -forever";
      };
    };
  };

  ### SERVICES ###




  ### HARDWARE ###

  hardware = {

    enableAllFirmware = true;

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

    pulseaudio = {
      enable = true;
      support32Bit = true;
      package = pkgs.pulseaudioFull;
      extraModules = [ pkgs.pulseaudio-modules-bt ];
      extraConfig = "load-module module-switch-on-connect";
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    opengl = {
      driSupport32Bit = true;
      driSupport = true;
    };

  };

  ### HARDWARE ###




  # Read docs before changing -> (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}
