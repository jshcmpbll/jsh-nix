{ lib, config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../users/jsh.nix
      ../../dots/zfs.nix
      ../../dots/shells.nix
      ../../dots/vim.nix
    ];

  # Mount mm's media shares over NFS. mm exports these restricted to this machine's IP.
  # all_squash on the export side maps writes to jsh (uid 1000) so Plex can read them.
  fileSystems."/mnt/mm-tv" = {
    device = "192.168.0.106:/home/jsh/TV";
    fsType = "nfs";
    options = [ "nfsvers=4" "rw" "sync" "_netdev" ];
  };

  fileSystems."/mnt/mm-movies" = {
    device = "192.168.0.106:/home/jsh/Movies";
    fsType = "nfs";
    options = [ "nfsvers=4" "rw" "sync" "_netdev" ];
  };

  # Aargh: VPN-routed torrent + media management stack
  services.aargh = {
    enable = true;
    proton = {
      enable = true;
      configDir = "/persist/protonvpn-configs";
    };
    deluge.enable = true;
    sonarr = {
      enable = true;
      tvDir = "/mnt/mm-tv";
    };
    overseerr.enable = false;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "jsh-mms";
    hostId = "a6aae9e3";
    useDHCP = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    firewall.enable = false;
  };

  time.timeZone = "America/Los_Angeles";

  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = [ "jsh" ];
  };

  nixpkgs.config.allowUnfree = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "25.05";
}
