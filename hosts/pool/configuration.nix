{ config, pkgs, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../users/jsh.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 1;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nixpkgs.config = {
    pulseaudio = true;
    allowUnfree = true;
  };

  environment.variables = {
    EDITOR = "${pkgs.vim}/bin/vim";
  };

  networking = {
    hostName = "pool";
    useDHCP = false;
    interfaces.enp2s0.useDHCP = true;
    interfaces.wlp3s0.useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 5900 ];
    };
  };

  # Enable Desktop Environment.
  services.xserver = {
    enable = true;
    layout = "us";
    displayManager.lightdm = {
      enable = true;
    };
    desktopManager.gnome.enable = true;
    videoDrivers = [ "intel" ];
  };

  # VNC
  systemd.services.x11vnc = {
    enable = true;
    path = [ pkgs.gawk pkgs.nettools ];
    wantedBy = [ "multi-user.target" ];
    requires = [ "graphical.target" ];
    after = [ "display-manager.service" ];
    description = "VNC server";
    serviceConfig = {
      type = "simple";
      ExecStart = "${pkgs.x11vnc}/bin/x11vnc -xkb -display :0 -auth /var/run/lightdm/root/:0 -forever";
    };
    reloadIfChanged = true;
    restartIfChanged = true;
  };

  # Enable sound.
  sound.enable = true;
  hardware = {
    pulseaudio = {
      enable = true;
      systemWide = true;
      support32Bit = true;
      package = pkgs.pulseaudioFull;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          ControllerMode = "bredr";
        };
      };
    };
  }; 

  # GPU
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;

  environment.systemPackages = with pkgs; [
    tmux
    wget
    vim
    htop
    lm_sensors
    chromium
    steam
    firefox
    google-chrome
    qutebrowser
    mpv
    vlc
    spotify
    audacity
    pavucontrol
    shairplay
    shairport-sync
    avahi
    spotifyd
    prometheus-node-exporter
    nixpkgs-fmt
  ];

  services.openssh = {
    enable = true;
    forwardX11 = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
    openFirewall = true;
  };

  system.stateVersion = "22.11"; # Did you read the comment?

}
