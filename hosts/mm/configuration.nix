{ config, pkgs, latest, ... }:

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
    kernel.sysctl = {
      "net.ipv4.ip_forward" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };
  };

  networking = {
    hostName = "jsh-mm"; # Define your hostname.
    hostId = "a6bbe9e3";
    useDHCP = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    firewall.enable = false;
    firewall.checkReversePath = "loose";
    wg-quick.interfaces = {
      ca = {
        configFile = "/persist/ca.conf";
        autostart = false;
      };
    };
  };

  time.timeZone = "America/Los_Angeles";

  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    wakeonlan
    vim
    jq
    tailscale
    git
  ];

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = [ "jsh" ];
  };

  nixpkgs.config.allowUnfree = true;

  virtualisation ={
    podman.enable = true;
    oci-containers = {
      backend = "podman";
      containers = {
        #frigate = {
        #  image = "blakeblackshear/frigate:stable-amd64";
        #  autoStart = true;
        #  volumes = [
        #    "/home/jsh/frigate/storage:/media/frigate"
        #    "/home/jsh/frigate/config.yaml:/config/config.yml:ro"
        #    "/etc/localtime:/etc/localtime:ro"
        #  ];
        #  ports = [
        #    "5000:5000"
        #    "1935:1935"
        #  ];
        #  environment = {
        #    FRIGATE_RTSP_PASSWORD = "password";
        #  };
        #  extraOptions = [
        #    "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
        #    "--device=/dev/bus/usb:/dev/bus/usb"
        #    "--device=/dev/dri/renderD128"
        #    "--shm-size=64m"
        #  ];
        #};
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
    cloudflared = {
      enable = true;
      tunnels = {
        "home" = {
          credentialsFile = "/etc/cloudflared/876bf7bc-d9de-4d2f-b287-7d90b68be053.json";
          default = "http_status:404";
        };
      };
    };
    vikunja = {
      enable = true;
      frontendScheme = "http";
      frontendHostname = "vikunja";
    };
    home-assistant = {
      enable = true;
      extraComponents = [
        "sense"
        "homekit"
        "generic"
        "amcrest"
        "iaqualink"
        "webostv"
        "rest"
        "rest_command"
        "lutron_caseta"
        "wake_on_lan"
      ];
      config = {
        default_config = {};
      };
    };
    plex = {
      enable = true;
      user = "jsh";
    };
    tailscale.enable = true;
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
