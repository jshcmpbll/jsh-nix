{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.kiro-gateway;

  kiro-python = pkgs.python311.withPackages (ps: with ps; [
    fastapi
    uvicorn
    httpx
    loguru
    python-dotenv
    tiktoken
    uvloop
    httptools
    websockets
  ]);

  token-sync-script = pkgs.writeShellScript "kiro-token-sync" ''
    set -euo pipefail

    SOURCE="${cfg.credentialsFile}"
    STATE="/var/lib/kiro-token-sync/last-hash"

    if [ ! -f "$SOURCE" ]; then
      echo "kiro credentials file not found at $SOURCE, skipping" >&2
      exit 0
    fi

    CURRENT_HASH=$(${pkgs.coreutils}/bin/sha256sum "$SOURCE" | cut -d' ' -f1)

    mkdir -p "$(dirname "$STATE")"

    if [ -f "$STATE" ] && [ "$(cat "$STATE")" = "$CURRENT_HASH" ]; then
      exit 0
    fi

    printf '%s' "$CURRENT_HASH" > "$STATE"
    chmod 600 "$STATE"

    echo "kiro credentials changed, restarting kiro-gateway"
    systemctl restart docker-kiro-gateway.service
  '';

in
{
  options.services.kiro-gateway = {
    enable = mkEnableOption "Kiro LLM gateway (OpenAI-compatible proxy for AWS Kiro)";

    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Port the gateway listens on (host-side).";
    };

    credentialsFile = mkOption {
      type = types.str;
      default = "/home/jsh/.aws/sso/cache/kiro-auth-token.json";
      description = "Path to the Kiro AWS SSO auth token JSON file.";
    };

    region = mkOption {
      type = types.str;
      default = "us-east-1";
      description = "AWS region for the Kiro API.";
    };

    src = mkOption {
      type = types.path;
      description = "Path to the kiro-gateway source (from flake input).";
    };

    tokenSyncInterval = mkOption {
      type = types.str;
      default = "1h";
      description = "How often to check if the credentials file has changed and restart the gateway.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.kiro-gateway = {
      image = "kiro-gateway:latest";
      imageFile =
        let
          image-python = pkgs.python311.withPackages (ps: with ps; [
            fastapi uvicorn httpx loguru python-dotenv tiktoken uvloop httptools websockets
          ]);
        in
        pkgs.dockerTools.buildLayeredImage {
          name = "kiro-gateway";
          tag = "latest";
          contents = [ image-python pkgs.cacert pkgs.bash pkgs.coreutils ];
          fakeRootCommands = ''
            mkdir -p /app
            cp -r ${cfg.src}/* /app/
          '';
          enableFakechroot = true;
          config = {
            WorkingDir = "/app";
            Cmd = [
              "${image-python}/bin/python" "-m" "uvicorn" "main:app"
              "--host" "0.0.0.0" "--port" "8000"
            ];
            Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
          };
        };
      ports = [ "127.0.0.1:${toString cfg.port}:8000" ];
      volumes = [
        "${dirOf cfg.credentialsFile}:/root/.aws/sso/cache"
      ];
      environment = {
        KIRO_CREDS_FILE = "/root/.aws/sso/cache/${baseNameOf cfg.credentialsFile}";
        HOME = "/root";
        KIRO_API_REGION = cfg.region;
      };
    };

    systemd.services.kiro-token-sync = {
      description = "Restart kiro-gateway when credentials file changes";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = token-sync-script;
        StateDirectory = "kiro-token-sync";
      };
    };

    systemd.timers.kiro-token-sync = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = cfg.tokenSyncInterval;
      };
    };
  };
}
