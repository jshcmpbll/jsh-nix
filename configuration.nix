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
    ./hardware-configuration.nix
    ./dots/zsh.nix
    ./dots/vim.nix
    (import ./lib/home-file.nix
      [ { origin = ./dots/polybar/config.ini;
          target = "/home/jsh/.config/polybar/config.ini";
        }
        { origin = ./dots/rofi/config.rasi;
          target = "/home/jsh/.config/rofi/config.rasi";
        }
        { origin = ./dots/dunst/dunstrc;
          target = "/home/jsh/.config/dunst/dunstrc";
        }
        { origin = ./dots/i3/config;
          target = "/home/jsh/.config/i3/config";
        }
      ])
  ];
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
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
    extraModulePackages = with config.boot.kernelPackages;
      [ v4l2loopback.out ];
    kernelModules = [ "v4l2loopback" ];
    extraModprobeConfig = ''
      options v4l2loopback video_nr=10 exclusive_caps=1 card_label="Camera"
    '';
    supportedFilesystems = [ "zfs" ];
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
    experimental-features = nix-command
  '';


  ### NETWORKING ###

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
    gimp-with-plugins
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
    htop
    i3-gaps
    imagemagick
    iperf3
    jq
    killall
    kompose
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
    latest.lutris
    lyx
    mediainfo
    mkdocs
    mpv
    mupdf
    nmap
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
    os-prober
    pandoc
    pavucontrol
    pciutils
    pdfsandwich
    php
    picom
    polybarFull
    prometheus
    #protonvpn-cli
    protonvpn-cli_2
    #protonvpn-gui
    python38Packages.azure-functions-devops-build
    python38Packages.grip
    pywal
    qemu_full
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
    latest.simple-scan
    latest.slack
    smartmontools
    spotify
    sshfs
    sshfs-fuse
    steam
    sxiv
    synergy
    inetutils # telnet
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
    latest.citrix_workspace
    latest.discord
    latest.fluxcd
    latest.github-cli
    latest.guvcview
    joplin
    latest.joplin-desktop
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
    #vulkan-loader
    #vulkan-tools
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
    latest.youtube-dl
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
    latest.nufraw
    nixpkgs-review
    at
    latest.btop
    lm_sensors
    ansible
    openconnect
    stoken
    nvtop
    latest.davinci-resolve
    latest.dolphin-emu
    hdparm
    latest.conftest
    json2hcl
    open-policy-agent
    ocrmypdf
    thunderbird
    hugo
    gimpPlugins.resynthesizer
    wireguard-tools
    libsForQt5.skanlite
    obsidian
    gthumb
    #LPA
  ];


  ### PACKAGES ###

  ### PROGRAMS ###

  programs.mosh.enable = true;


  ### PROGRAMS ###


  ### SERVICES ###
  services = {

    xserver = {
      enable = true;
      autorun = true;
      displayManager.setupCommands = ''
        /nix/store/rqikhbksyzdgaddq50nqrnlgg6c3gky9-nvidia-settings-515.48.07/bin/nvidia-settings --assign CurrentMetaMode="DPY-1: nvidia-auto-select @2560x1440 +2160+0 {ViewPortIn=2560x1440, ViewPortOut=2560x1440+0+0}, DPY-0: 3840x2160 @2160x3840 +0+0 {ViewPortIn=2160x3840, ViewPortOut=3840x2160+0+0, Rotation=90}"
      '';
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
        touchpad = {
          disableWhileTyping = true;
          naturalScrolling = true;
          tapping = false;
        };
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

    #fail2ban = {
    #  enable = true;
    #  maxretry = 5;
    #  ignoreIP = [
    #    "192.168.0.0/16"
    #  ];
    #};

    atd = {
      enable = true;
      allowEveryone = true;
    };

    #cgminer = {
    #  enable = true;
    #  pools = [
    #    {
    #      password = "anything123";
    #      url = "stratum+tcp://stratum.slushpool.com:3333";
    #      username = "jshcmpbll.nix";
    #    }
    #  ];
    #};

    ofono = {
      enable = true;
    };


  };



  systemd.services = {
    x11vnc = {
      enable = true;
      path = [ pkgs.gawk pkgs.nettools ];
      description = "VNC server";
      serviceConfig = {
        type = "simple";
        ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever";
      };
      reloadIfChanged = true;
      restartIfChanged = true;
      after = [ "multi-user.target" ];
    };


  };

  ### SERVICES ###

  ### CONFIG ###

  users.users.jsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" "audio" "docker" ];
    shell = pkgs.zsh;
  };

  security.sudo.configFile = ''
    jsh ALL=(ALL) NOPASSWD:ALL
  '';

  ### CONFIG ###




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
      extraConfig = "load-module module-switch-on-connect";
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };

    opengl = {
      driSupport32Bit = true;
      driSupport = true;
    };

    video = {
      hidpi = {
        enable = true;
      };
    };

  };

  ### HARDWARE ###




  # Read docs before changing -> (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).S
  # Before changing update channel sources
  # sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-${system.stateVersion}.tar.gz home-manager
  # sudo nix-channel --add https://nixos.org/channels/nixos-${system.stateVersion} nixos
  system.stateVersion = "22.05"; # Did you read the comment?

}
