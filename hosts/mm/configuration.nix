{ lib, config, pkgs, latest, latest2, latest3, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../users/jsh.nix
      ../../dots/zfs.nix
      ../../dots/shells.nix
      ../../dots/vim.nix
    ];

  sops = {
    defaultSopsFile = ../../secrets/mm.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      immich_backup_key_id             = { owner = "immich"; };
      immich_backup_application_key    = { owner = "immich"; };
      immich_protondrive_username      = { owner = "immich"; };
      immich_protondrive_password      = { owner = "immich"; };
      immich_protondrive_mailbox_password = { owner = "immich"; };
      immich_protondrive_otp_secret_key   = { owner = "immich"; };
      rathole_default_token = {};
      grafana_cloud_password = {};
    };
    templates."rathole-client-creds.toml".content = ''
      [client]
      default_token = "${config.sops.placeholder.rathole_default_token}"
    '';

    templates."alloy-config.alloy" = {
      owner = "alloy";
      group = "alloy";
      path = "/etc/alloy/config.alloy";
      content = ''
        // HTTP service checks
        prometheus.scrape "blackbox_http" {
          targets = [
            {__address__ = "localhost:9115", __param_target = "http://localhost:8123",  __param_module = "http_2xx", instance = "home-assistant"},
            {__address__ = "localhost:9115", __param_target = "http://localhost:32400", __param_module = "http_2xx", instance = "plex"},
            {__address__ = "localhost:9115", __param_target = "http://localhost:2283",  __param_module = "http_2xx", instance = "immich"},
            {__address__ = "localhost:9115", __param_target = "http://localhost:3001",  __param_module = "http_2xx", instance = "uptime-kuma"},
          ]
          metrics_path    = "/probe"
          scrape_interval = "30s"
          forward_to      = [prometheus.remote_write.grafana_cloud.receiver]
        }

        // ICMP ping checks — detects internet outages and local network issues
        prometheus.scrape "blackbox_icmp" {
          targets = [
            {__address__ = "localhost:9115", __param_target = "192.168.0.1", __param_module = "icmp", instance = "gateway"},
            {__address__ = "localhost:9115", __param_target = "1.1.1.1",     __param_module = "icmp", instance = "cloudflare"},
            {__address__ = "localhost:9115", __param_target = "8.8.8.8",     __param_module = "icmp", instance = "google"},
          ]
          metrics_path    = "/probe"
          scrape_interval = "15s"
          forward_to      = [prometheus.remote_write.grafana_cloud.receiver]
        }

        prometheus.remote_write "grafana_cloud" {
          endpoint {
            url = "https://prometheus-prod-67-prod-us-west-0.grafana.net/api/prom/push"
            basic_auth {
              username = "3085006"
              password = "${config.sops.placeholder.grafana_cloud_password}"
            }
          }
        }
      '';
    };
  };

  # Custom modules
  immich-backup = {
    enable = true;
    bucketName = "immich-jshcmpbll";
    keyIDFile = config.sops.secrets.immich_backup_key_id.path;
    applicationKeyFile = config.sops.secrets.immich_backup_application_key.path;
  };

  immich-protondrive-backup = {
    enable = true;
    usernameFile = config.sops.secrets.immich_protondrive_username.path;
    passwordFile = config.sops.secrets.immich_protondrive_password.path;
    mailboxPasswordFile = config.sops.secrets.immich_protondrive_mailbox_password.path;
    otpSecretKeyFile = config.sops.secrets.immich_protondrive_otp_secret_key.path;
  };

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

  systemd.services.plex.serviceConfig.ProtectHome = lib.mkForce false;

  services.nfs.server = {
    enable = true;
    # Export TV and Movies to mms only. all_squash maps all writes to jsh (uid/gid 1000)
    # so files land with the right ownership for Plex.
    exports = ''
      /home/jsh/TV      192.168.0.107(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)
      /home/jsh/Movies  192.168.0.107(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)
    '';
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
        "lifx"
      ];
      config = {
        default_config = {};
      };
    };
    plex = {
      enable = true;
      user = "jsh";
      package = latest3.plex;
    };
    tailscale.enable = true;
    immich = {
      enable = true;
      openFirewall = true;
      host = "192.168.0.106";
    };
    uptime-kuma.enable = true;
    nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."0.0.0.0" = {
        locations."/" = {
          root = pkgs.writeTextDir "index.html" ''
            Hello world
          '';
        };
      };
      #virtualHosts."192.168.0.106" = {
      #  default = false;
      #  enableACME = false;
      #  #locations."/kuma/" = {
      #  #  proxyPass = "http://localhost:3001";
      #  #};
      #  #locations."/plex/" = {
      #  #  proxyPass = "http://localhost:32400/web/index.html";
      #  #};
      #  #locations."/immich/" = {
      #  #  proxyPass = "http://localhost:2283";
      #  #};
      #  #locations."/vikunja/" = {
      #  #  proxyPass = "http://localhost:3456/";
      #  #};
      #  locations."/home-assistant/" = {
      #    proxyPass = "http://localhost:8123";
      #  };
      #};
    }; 
    rathole = {
      enable = true;
      role = "client";
      credentialsFile = config.sops.templates."rathole-client-creds.toml".path;
      settings = {
        client = {
          remote_addr = "helium.api.predictablehorizons.com:2333";
          services."square_api" = {
            local_addr = "127.0.0.1:80";
          };
        };
      };
    };
    minio = {
      enable = true;
      region = "us-west-dineral";
      dataDir = ["/var/lib/minio/data"];
    };
    ollama = {
      enable = true;
      package = latest2.ollama-cpu.overrideAttrs (finalAttrs: previousAttrs: {
        version = "0.15.5";
        src = pkgs.fetchFromGitHub {
          owner = "ollama";
          repo = "ollama";
          tag = "v${finalAttrs.version}";
          hash = "sha256-VJrAUHX+BVQXsH34BDI4YqVXEqD14ERnKhSpMByAdrQ=";
        };
        vendorHash = "sha256-r7bSHOYAB5f3fRz7lKLejx6thPx0dR4UXoXu0XD7kVM=";
      });
    };
    #open-webui = {
    #  enable = true;
    #  package = pkgs.open-webui;
    #  environment = {
    #    ANONYMIZED_TELEMETRY = "False";
    #    DO_NOT_TRACK = "True";
    #    SCARF_NO_ANALYTICS = "True";
    #    WEBUI_AUTH = "False";
    #    OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
    #  };
    #  host = "0.0.0.0";
    #  openFirewall = true;
    #};
  };

  # Disabled: Cloudflare quick tunnel exposes internal services publicly without auth
  # systemd.services.uptime-kuma-tunnel = {
  #   enable = true;
  #   description = "Cloudflare quick tunnel for Uptime Kuma";
  #   after = [ "network.target" "uptime-kuma.service" ];
  #   wants = [ "uptime-kuma.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     ExecStart = pkgs.writeShellScript "tunnel-with-notify" ''
  #       ${pkgs.cloudflared}/bin/cloudflared tunnel --protocol http2 --url localhost:3001 2>&1 | \
  #       while IFS= read -r line; do
  #         echo "$line"
  #         if [[ "$line" =~ https://[a-zA-Z0-9-]+\.trycloudflare\.com ]]; then
  #           url=$(echo "$line" | grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com')
  #           echo "Detected tunnel URL: $url"
  #           existing=$(curl -s -X POST https://api.porkbun.com/api/json/v3/domain/getUrlForwarding/jshcmpbll.com ...)
  #           ...
  #         fi
  #       done
  #     '';
  #     Restart = "always";
  #     RestartSec = "5";
  #     User = "nobody";
  #     Group = "nobody";
  #   };
  # };

  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = "127.0.0.1";
    configFile = pkgs.writeText "blackbox.yml" ''
      modules:
        http_2xx:
          prober: http
          timeout: 5s
          http:
            valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
            method: GET
        icmp:
          prober: icmp
          timeout: 5s
          icmp:
            preferred_ip_protocol: ip4
    '';
  };

  services.alloy = {
    enable = true;
  };


  system.stateVersion = "25.05"; # Did you read the comment?
}
