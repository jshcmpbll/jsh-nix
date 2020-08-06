# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s20u1.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  
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
    gtk+3
    lightdm
    lightdm_gtk_greeter
    git
    oh-my-zsh
    rofi
    ffmpeg
    aspell
    gimp
    gnumake
    vlc
    which
    nmap
    ncat
    python38Packages.grip
    zathura
    linuxPackages.zfs
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
    polybar 
    ncurses
    ncdu
    jq
    hddtemp
    google-cloud-sdk
    _1password
  ];

  environment.variables.EDITOR = "urxvt";

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    autorun = true;
    displayManager.lightdm.enable = true;
    displayManager.defaultSession = "none+i3";
    #desktopManager.default = "none";
    #windowManager.default = "i3";
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
    };
    layout = "us";
  };


  programs  = {
    zsh = {
      interactiveShellInit = ''

      # Customize your oh-my-zsh options here
      ZSH_THEME = "jsh"
      plugins=(git)
      source $ZSH/oh-my-zsh.sh
      '';

      promptInit = ""; # Clear this to avoid a conflict with oh-my-zsh
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };

  # Read docs before changing -> (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}