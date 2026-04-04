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
  inherit (lib.types) str;
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
      description = "BackBlaze B2 application key ID";
    };
    
    applicationKey = mkOption {
      type = str;
      description = "BackBlaze B2 application key";
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
        
        # Environment variables for B2 authentication
        Environment = [
          "B2_APPLICATION_KEY_ID=${cfg.keyID}"
          "B2_APPLICATION_KEY=${cfg.applicationKey}"
          "XDG_CONFIG_HOME=/var/cache/immich-backup"
        ];
        
        # Security hardening
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = cfg.syncLocation;
        CacheDirectory = "immich-backup";
      };
      
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
    
    
    
    
