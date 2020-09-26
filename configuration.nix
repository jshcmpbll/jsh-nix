{ config, pkgs, ... }:
let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "8def3835111f0b16850736aa210ca542fcd02af6";
    ref = "release-19.03";
  };
in
{
  imports =
    [ 
      /.jsh-nix/users/jsh.nix
      /.jsh-nix/hardware-configuration.nix
      "${home-manager}/nixos"
      /.jsh-nix/x11vnc/service.nix
    ];

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
      };
    };
    supportedFilesystems = [ "zfs" ];
  };

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

  services.xserver.xkbOptions = "ctrl:swapcaps";

  services.udev.packages = [ pkgs.libu2f-host ];

  time.timeZone = "America/Los_Angeles";
  
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    wget
    vim
    rxvt_unicode
    qutebrowser
    chromium
    i3-gaps
    slack
    spotify
    unzip
    scrot
    tldr
    xfce.xfce4-power-manager
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
    dolphin
    sxiv
    mpv
    picom
    killall
    vulnix
    docker
    aspell
    blueman
    wine
  ];

  environment.variables = {
    EDITOR = "${pkgs.vim}/bin/vim";
  };

  # List services that you want to enable:
  # Enable the OpenSSH daemon.
  services = {
    openssh.enable = true;
    pcscd.enable = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;


  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

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
  };

  services.x11vnc = {
    enable = true;
    autoStart = true;
    auth = "/var/run/lightdm/root/:0";
    shared = true;
    password = "test";
  };
    

  hardware.opengl.driSupport32Bit = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.

fonts.fonts = with pkgs; [
  hermit
  source-code-pro
  terminus_font
];


  # Read docs before changing -> (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}
