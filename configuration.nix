{ config, pkgs, ... }:
let
  nix-garage = builtins.fetchGit {
    url = "https://github.com/nebulaworks/nix-garage";
    ref = "master";
  };
  garage-overlay = import (nix-garage.outPath + "/overlay.nix");
  overlay = import <nixpkgs> { overlays = [ garage-overlay ]; };
  iconTheme = pkgs.luna-icons.out;
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
      latest = import <nixpkgs-unstable> {
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

  # QT4/5 global theme
  environment.etc."xdg/Trolltech.conf" = {
    text = ''
      [Qt]
      style=Breeze
    '';
    mode = "444";
  };

  # GTK3 global theme (widget and icon theme)
  environment.etc."xdg/gtk-3.0/settings.ini" = {
    text = ''
      [Settings]
      gtk-icon-theme-name=breeze
      gtk-theme-name=Breeze-gtk
    '';
    mode = "444";
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

  ### NETWORKING ###

  networking = {

    hostName = "jsh-server";
    hostId = "a6bbe9e1";
    useDHCP = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    firewall = {
      enable = false;
      # allowedTCPPorts = [ ... ];
      # allowedUDPPorts = [ 500 4500 ];
    };
  };

  ### NETWORKING ###




  ### PACKAGES ###  

  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.en
    audacity
    awscli2
    bc
    bind
    blueman
    breeze-gtk
    breeze-qt5
    cava
    chromium
    cudatoolkit
    darktable
    digikam
    dmg2img
    dmidecode
    docker-compose
    latest.dolphin
    dunst
    eagle
    exiftool
    fdupes
    feh
    ffmpeg
    file
    firefox
    foremost
    freecad
    gimp
    git
    git-lfs
    glxinfo
    gnome3.adwaita-icon-theme
    gnumake
    gnupg
    gnuplot
    go
    google-chrome
    google-cloud-sdk
    grub2
    gtk3
    hddtemp
    hicolor_icon_theme
    htop
    i3-gaps
    iconTheme
    imagemagick
    iperf3
    jq
    killall
    kompose
    kubectl
    kubectl
    kubernetes
    kubernetes-helm
    libheif
    libimobiledevice
    libreoffice
    libvirt
    lightdm
    lightdm_gtk_greeter
    linuxPackages.v4l2loopback
    lm_sensors
    lsof
    #lutris
    lyx
    mediainfo
    mkdocs
    mpv
    mupdf
    ncat
    ncdu
    ncurses
    #ndi
    neofetch
    nixpkgs-fmt
    nix-prefetch-git
    nload
    nmap
    nodePackages.prettier
    ntfs3g
    #obs-ndi
    obs-studio
    ofono-phonesim
    oh-my-zsh
    okular
    olive-editor
    os-prober
    overlay.codefresh
    pandoc
    pavucontrol
    pciutils
    pdfsandwich
    php
    picom
    polybarFull
    prometheus
    protonvpn-cli
    python38Packages.azure-functions-devops-build
    python38Packages.grip
    pywal
    qemu
    qemu_kvm
    qemu-utils
    redshift
    restic
    restic
    rofi
    rpl
    rsync
    rxvt_unicode
    samba
    sane-airscan
    screen
    screenkey
    scrot
    silver-searcher
    simple-scan
    latest.slack
    smartmontools
    spotify
    sshfs
    sshfs-fuse
    steam
    sxiv
    synergy
    telnet
    #terraform_0_11
    #terraform_0_12
    #terraform_0_15
    terraform_0_13
    terraform-providers.google
    tesseract
    texlive.combined.scheme-full
    tigervnc
    tldr
    tlp
    tmux
    tree
    unrar
    vlc
    latest.argocd
    latest.azure-cli
    latest.azure-functions-core-tools
    latest.citrix_workspace_20_09_0
    latest.discord
    latest.exodus
    latest.fluxcd
    latest.github-cli
    latest.guvcview
    latest.joplin
    minecraft
    latest.odafileconverter
    latest.python37
    latest.python37Packages.pip
    latest.spotifyd
    latest.teams
    #latest.terraform
    #latest.terraform_0_13
    latest.yuzu-mainline
    zoom-us
    ranger
    unzip
    usbmuxd
    usbutils
    vim
    vulkan-loader
    vulkan-tools
    vulnix
    wget
    which
    wine
    wireshark-cli
    wireshark-qt
    woeusb
    xclip
    xfce.thunar
    xorg.xdpyinfo
    yaml2json
    yarn
    yj
    youtube-dl
    yq
    yubico-piv-tool
    yubikey-manager
    zathura
    zfs
    zsh
    latest.ccloud-cli
    binutils
    helmsman
    terraform-docs
    libimobiledevice
    magic-wormhole
    wormhole-william
    #LPA
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
        background = "/home/jsh/.i3_background";
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

    #samba = {
    #  enable = true;
    #  syncPasswordsByPam = true;
    #  shares.csan =
    #    {
    #      path = "/mnt/CSAN";
    #      "read only" = false;
    #      "guest ok" = false;
    #      writeable = true;
    #      comment = "Campbell SAN";
    #    };
    #};

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

    usbmuxd = {
      enable = true;
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
        ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever";
      };
      reloadIfChanged = true;
      restartIfChanged = true;
      after = [ "display-manager.service" ];
    };

    ofono = {
      enable = true;
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
      config = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
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
