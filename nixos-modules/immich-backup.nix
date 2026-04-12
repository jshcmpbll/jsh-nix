{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.immich-backup;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str nullOr path;
in
{
  options.immich-backup = {
    enable = mkEnableOption "Service to backup immich data to BackBlaze B2";

    bucketName = mkOption {
      type = str;
      description = "BackBlaze B2 bucket name";
      example = "immich-backup";
    };

    keyID = mkOption {
      type = str;
      default = "";
      description = "BackBlaze B2 application key ID (plaintext; prefer keyIDFile)";
    };

    keyIDFile = mkOption {
      type = nullOr path;
      default = null;
      description = "File containing BackBlaze B2 application key ID";
    };

    applicationKey = mkOption {
      type = str;
      default = "";
      description = "BackBlaze B2 application key (plaintext; prefer applicationKeyFile)";
    };

    applicationKeyFile = mkOption {
      type = nullOr path;
      default = null;
      description = "File containing BackBlaze B2 application key";
    };

    syncLocation = mkOption {
      type = str;
      default = "/var/lib/immich";
      description = "Local directory to sync to B2";
    };

    syncDestination = mkOption {
      type = str;
      default = "/";
      description = "Destination path within the B2 bucket";
      example = "/backups/";
      apply = path:
        if lib.hasPrefix "/" path
        then path
        else throw "syncDestination must start with a '/' (got: ${path})";
    };

    threads = mkOption {
      type = str;
      default = "4";
      description = "Number of threads to use for syncing";
    };

    backupSchedule = mkOption {
      type = str;
      default = "daily";
      description = "Systemd calendar expression for backup schedule";
      example = "daily";
    };

    user = mkOption {
      type = str;
      default = "immich";
      description = "User to run the backup service as";
    };
  };

  config = mkIf cfg.enable {
    # Ensure the b2 CLI tool is available
    environment.systemPackages = [ pkgs.backblaze-b2 ];

    systemd.services.immich-backup = {
      description = "Backup Immich data to BackBlaze B2";

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;

        Environment = [
          "XDG_CONFIG_HOME=/var/cache/immich-backup"
        ] ++ lib.optionals (cfg.keyID != "") [
          "B2_APPLICATION_KEY_ID=${cfg.keyID}"
          "B2_APPLICATION_KEY=${cfg.applicationKey}"
        ];

        # preStart writes /run/immich-backup.env when file-based secrets are used
        EnvironmentFile = lib.mkIf (cfg.keyIDFile != null) "/run/immich-backup.env";

        # Security hardening
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.syncLocation "/run" ];
        CacheDirectory = "immich-backup";
      };

      preStart = lib.mkIf (cfg.keyIDFile != null) ''
        printf 'B2_APPLICATION_KEY_ID=%s\nB2_APPLICATION_KEY=%s\n' \
          "$(cat ${cfg.keyIDFile})" \
          "$(cat ${cfg.applicationKeyFile})" \
          > /run/immich-backup.env
        chmod 600 /run/immich-backup.env
      '';

      script = ''
        ${pkgs.backblaze-b2}/bin/b2v4 sync \
          ${cfg.syncLocation} \
          b2://${cfg.bucketName}${cfg.syncDestination} \
          --threads ${cfg.threads}
      '';
    };

    systemd.timers.immich-backup = {
      description = "Timer for Immich backup to BackBlaze B2";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.backupSchedule;
        Persistent = true;
        Unit = "immich-backup.service";
      };
    };
  };
}
