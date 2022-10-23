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
          { origin = ./dots/rofi/config;
            target = "/home/jsh/.config/rofi/config";
          }
          { origin = ./dots/dunst/dunstrc;
            target = "/home/jsh/.config/dunst/dunstrc";
          }
          { origin = ./dots/i3/config;
            target = "/home/jsh/.config/i3/config";
          }
          { origin = ./scripts/screens;
            target = "/home/jsh/.config/screens";
          }
        ])
    ];
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    firmware = with pkgs; [ wireless-regdb alsa-firmware ];
    opengl.driSupport = true;
    opengl.driSupport32Bit = true;
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
        '';
      };
    };
    extraModulePackages = with config.boot.kernelPackages;
      [ v4l2loopback.out ];
    kernelModules = [ "v4l2loopback" "kvm-amd" ];
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
    experimental-features = nix-command flakes
  '';


  ### NETWORKING ###

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

  ### NETWORKING ###

  ### PACKAGES ###  

  environment.systemPackages = with pkgs; [
    #builtins.readFile /home/jsh/git/jsh-nix/packages ];
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
    myFirefox
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
    #latest.citrix_workspace
    latest.discord
    latest.exodus
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
    deluge
    at
    latest.btop
    lm_sensors
    ansible
    openconnect
    stoken
    nvtop
    latest.dolphin-emu
    hdparm
    latest.conftest
    json2hcl
    open-policy-agent
    ocrmypdf
    thunderbird
    hugo
    gthumb
    ifuse
    wireguard-tools
    element-desktop
    latest.obsidian
    imv
    signal-desktop
    _1password
    arandr
    #LPA
  ];

  ### PACKAGES ###


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
      };
      displayManager.defaultSession = "none+i3";
      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;
        #configFile = "/home/jsh/git/jsh-nix/dots/
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
      videoDrivers = [ "amdgpu" ];
      xkbOptions = "ctrl:swapcaps";
    };

    openssh = {
      enable = true;
      forwardX11 = true;
      permitRootLogin = "yes";
      passwordAuthentication = true;
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

    zfs = {
      autoScrub.enable = true;
      autoScrub.interval = "weekly";
      autoSnapshot = {
        daily = 1;
        enable = true;
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

    fprintd.enable = true;

    tlp.enable = true;

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

    instructions = {
      enable = true;
      description = "displays instructions for cature the flag event";
      script = "echo 'hi' | ${pkgs.netcat-openbsd}/bin/nc 127.0.0.1 9065; exit 0";
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
      };
      reloadIfChanged = true;
      restartIfChanged = true;
      after = [ "multi-user.target" ];
    };


  };

  ### SERVICES ###

  ### CONFIG ###


  ### CONFIG ###

  users.extraUsers.root.shell = pkgs.zsh;

  users.users.jsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" "audio" "docker" ];
    shell = pkgs.zsh;
  };

  security.sudo.configFile = ''
    jsh ALL=(ALL) NOPASSWD:ALL
  '';

  security.pam.services = {
    login.fprintAuth = true;
    xscreensaver.fprintAuth = true;
  };



  system.stateVersion = "22.05"; # Did you read the comment?
}

