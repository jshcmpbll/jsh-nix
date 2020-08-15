# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        version = 2;
        devices = [ "nodev" ];
        useOSProber = true;
	efiSupport = true;
#	extraEntries = ''
#          menuentry "Windows 10" {
#            search --fs-uuid --no-floppy --set=root --fs-uuid 618c166c-f279-499f-a7f1-72e04d376689
#            chainloader (hd5,1)/EFI/Microsoft/Boot/bootmgfw.efi
#          }
#        '';
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

  time.timeZone = "America/LosAngeles";
  
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
    polybar 
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
    x11vnc
    glxinfo
    youtube-dl
  ];

  environment.variables.EDITOR = "urxvt";
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services = {
    openssh.enable = true;
    # x11vnc.enable= true;
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
    #desktopManager.default = "none";
    #windowManager.default = "i3";
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
    };
    layout = "us";
    videoDrivers = [ "nvidia" ];
  };

  hardware.opengl.driSupport32Bit = true;

  programs  = {
    zsh = {
      interactiveShellInit = ''

      # Customize your oh-my-zsh options here
      ZSH_THEME = "jsh"
      plugins=(git)
      source $ZSH/oh-my-zsh.sh
      '';

      promptInit = ""; # Clear this to avoid a conflict with oh-my-zsh

      ohMyZsh = {
        enable = true;
        plugins = ["git" "python" "man"];
        theme = "/home/jsh/.dotfiles/jcampbell.zsh-theme";
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jsh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo"]; # Enable ‘sudo’ for the user.
  };

  security.sudo.configFile = ''
    jsh ALL=(ALL) NOPASSWD:ALL
  '';

  # Read docs before changing -> (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}