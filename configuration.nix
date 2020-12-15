{ config, pkgs, ... }:
let
  kubeMasterIP = "192.168.0.100";
  kubeMasterHostname = "api.kube";
  kubeMasterAPIServerPort = 443;
in
{
  imports =
    [ 
      /.jsh-nix/users/jsh.nix
      /etc/nixos/hardware-configuration.nix
      <home-manager/nixos>
      /.jsh-nix/x11vnc/service.nix
      <nixpkgs/nixos/modules/services/hardware/sane_extra_backends/brscan4.nix>
    ];
  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        version = 2;
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

  #virtualisation.virtualbox.host.enable = true;

  networking = {
    hostName = "jsh-server";
    hostId = "a6bbe9e1";
    useDHCP = false;
    interfaces.enp4s0.useDHCP = true;
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  ## Uncomment for wireless macbook
  # networking.networkmanager.enable = false;
  # networking.wireless.enable = true;

#####

  services.xserver.xkbOptions = "ctrl:swapcaps";

  services.udev.packages = [ pkgs.libu2f-host ];

  time.timeZone = "America/Los_Angeles";
  
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
    xfce.xfce4-power-manager
    tlp
    zsh
    neofetch
    htop
    gtk3
    lightdm
    lightdm_gtk_greeter
    git
    git-lfs
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
    zoom-us
    tree
    feh
    file
    fdupes
    discord
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
    azure-cli
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
    #wine
    #lutris
    vulkan-loader
    vulkan-tools
    simple-scan
    sane-airscan
    cava
    redshift
    steam
    obs-studio
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
    teams
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
    #minecraft
    firefox
  ];

  environment.variables = {
    EDITOR = "${pkgs.vim}/bin/vim";
  };

  # List services that you want to enable:
  # Enable the OpenSSH daemon.
  services = {
    openssh.enable = true;
    pcscd.enable = true;
    avahi.enable = true;
    printing.enable = true;
    blueman.enable = true;
  };

  # Scanning setup
  hardware = {
    sane = {
      enable = true;
      brscan4 = {
        enable = true;
        netDevices = {
          home = { model = "MFC-L2710DW"; ip = "192.168.0.53"; };
        };
      };
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ 500 4500 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.firewall.enable = false;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
    extraModules = [ pkgs.pulseaudio-modules-bt ];
    extraConfig = "
  load-module module-switch-on-connect
";
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Enable the X11 windowing system and i3 gaps
  services.xserver = {
    enable = true;
    autorun = true;
    displayManager.lightdm.enable = true;
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
  };

  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.driSupport = true;


fonts.fonts = with pkgs; [
  hermit
  source-code-pro
  terminus_font
];

# Kubernetes

  networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

  services.kubernetes = {
    roles = ["master" "node"];
    masterAddress = kubeMasterHostname;
    easyCerts = true;
    apiserver = {
      securePort = kubeMasterAPIServerPort;
      advertiseAddress = kubeMasterIP;
    };

    # use coredns
    addons.dns.enable = true;

  };

  # Read docs before changing -> (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}
