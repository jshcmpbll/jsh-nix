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
    hostName = "jsh-mm"; # Define your hostname.
    hostId = "a6bbe9e3";
    useDHCP = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    firewall.enable = false;
    wg-quick.interfaces = {
      wg0 = {
        address = [ "10.2.0.2/32" ];
        dns = [ "10.2.0.1" ];
        privateKeyFile = "/persist/pvpn-canada";
        peers = [
          {
            publicKey = "28hrybwV/NiiMXvl1ynBvDvEvs1m8ABUzyvkQ7+ST3I=";
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = "146.70.198.34:51820";
          }
        ];
      };
    };
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

  virtualisation ={
    podman.enable = true;
    oci-containers = {
      backend = "podman";
      containers = {
        frigate = {
          image = "blakeblackshear/frigate:stable-amd64";
          autoStart = true;
          volumes = [
            "/home/jsh/frigate/storage:/media/frigate"
            "/home/jsh/frigate/config.yaml:/config/config.yml:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
          ports = [
            "5000:5000"
            "1935:1935"
          ];
          environment = {
            FRIGATE_RTSP_PASSWORD = "password";
          };
          extraOptions = [
            "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
            "--device=/dev/bus/usb:/dev/bus/usb"
            "--device=/dev/dri/renderD128"
            "--shm-size=64m"
          ];
        };
      };
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
    mosquitto = {
      enable = true;
      listeners = [{
        port = 1883;
        omitPasswordAuth = true;
        settings = {
          allow_anonymous = true;
        };
      }];
    };
    deluge = {
      user = "jsh";
      group = "users";
      enable = true;
      declarative = true;
      openFirewall = true;
      authFile = "/persist/deluge-auth";
      config = {
        #download_location = "/home/jsh/Downloads";
        info_sent = 0.0;
        prioritize_first_last_pieces = true;
        send_info = false;
        stop_seed_at_ratio = true;
        stop_seed_ratio = 2;
        outgoing_interface = "wg0";
      };
      web = {
        enable = true;
        openFirewall = true;
      };
    };
    sonarr.enable = true;
    radarr.enable = true;
    plex = {
      enable = true;
      user = "jsh";
    };
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}

