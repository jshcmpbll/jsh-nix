{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../users/jsh.nix
      ../../dots/zfs.nix
      ../../dots/shells.nix
      ../../dots/vim.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "jsh-mms"; # Define your hostname.
    hostId = "a6aae9e3";
    useDHCP = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    firewall.enable = false;
  };

  time.timeZone = "America/Los_Angeles";

  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    edgetpu-compiler
    git
  ];

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nixpkgs.config.allowUnfree = true;

  services = {
    openssh = {
      enable = true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}

