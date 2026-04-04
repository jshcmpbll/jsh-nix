{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.immich-protondrive-backup;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str bool;
in
{
  options.immich-protondrive-backup = {
    enable = mkEnableOption "Service to backup immich data to ProtonDrive via rclone";
    
    remoteName = mkOption {
      type = str;
      default = "protondrive";
      description = "Name for the rclone remote";
      example = "protondrive";
    };
    
    username = mkOption {
      type = str;
      description = "ProtonDrive username (email address)";
      example = "you@protonmail.com";
    };
    
    password = mkOption {
      type = str;
      description = "ProtonDrive login password (will be obscured by rclone)";
    };
    
    mailboxPassword = mkOption {
      type = str;
      description = "Mailbox password / second password for two-password Proton accounts (will be obscured by rclone)";
    };
    
    otpSecretKey = mkOption {
      type = str;
      description = "OTP secret key for automatic 2FA authentication (will be obscured by rclone)";
    };
    
    syncLocation = mkOption {
      type = str;
      default = "/var/lib/immich";
      description = "Local directory to sync to ProtonDrive";
    };
    
    syncDestination = mkOption {
      type = str;
      default = "immich-backup";
      description = "Destination path within ProtonDrive";
      example = "backups/immich";
    };
    
    enableCaching = mkOption {
      type = bool;
      default = false;
      description = "Enable ProtonDrive metadata caching (disable if mounting as VFS)";
    };
    
    replaceExistingDraft = mkOption {
      type = bool;
      default = true;
      description = "Replace existing draft files on conflict";
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
    
    extraRcloneArgs = mkOption {
      type = str;
      default = "--progress --verbose";
      description = "Additional arguments to pass to rclone sync";
      example = "--progress --verbose --transfers 4";
    };
  };

  config = mkIf cfg.enable {
    # Validate required options
    assertions = [
      {
        assertion = cfg.password != "";
        message = "immich-protondrive-backup.password must be set";
      }
      {
        assertion = cfg.mailboxPassword != "";
        message = "immich-protondrive-backup.mailboxPassword must be set";
      }
      {
        assertion = cfg.otpSecretKey != "";
        message = "immich-protondrive-backup.otpSecretKey must be set";
      }
    ];
    
    # Ensure rclone is available
    environment.systemPackages = [ pkgs.rclone ];

    # Create rclone config directory and file
    systemd.tmpfiles.rules = [
      "d /var/cache/immich-protondrive-backup 0700 ${cfg.user} ${cfg.user} -"
      "d /var/cache/immich-protondrive-backup/rclone 0700 ${cfg.user} ${cfg.user} -"
    ];

    systemd.services.immich-protondrive-backup-setup = {
      description = "Setup rclone configuration for ProtonDrive";
      
      before = [ "immich-protondrive-backup.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        RemainAfterExit = true;
      };
      
      script = ''
        # Create rclone config directory
        mkdir -p /var/cache/immich-protondrive-backup/rclone
        
        # Obscure passwords and OTP secret key
        OBSCURED_PASSWORD=$(${pkgs.rclone}/bin/rclone obscure "${cfg.password}")
        OBSCURED_MAILBOX_PASSWORD=$(${pkgs.rclone}/bin/rclone obscure "${cfg.mailboxPassword}")
        OBSCURED_OTP_KEY=$(${pkgs.rclone}/bin/rclone obscure "${cfg.otpSecretKey}")
        
        # Create rclone config file
        cat > /var/cache/immich-protondrive-backup/rclone/rclone.conf <<EOF
        [${cfg.remoteName}]
        type = protondrive
        username = ${cfg.username}
        password = $OBSCURED_PASSWORD
        mailbox_password = $OBSCURED_MAILBOX_PASSWORD
        otp_secret_key = $OBSCURED_OTP_KEY
        enable_caching = ${if cfg.enableCaching then "true" else "false"}
        replace_existing_draft = ${if cfg.replaceExistingDraft then "true" else "false"}
        EOF
        
        chmod 600 /var/cache/immich-protondrive-backup/rclone/rclone.conf
      '';
    };

    systemd.services.immich-protondrive-backup = {
      description = "Backup Immich data to ProtonDrive via rclone";
      
      after = [ "network-online.target" "immich-protondrive-backup-setup.service" ];
      wants = [ "network-online.target" ];
      requires = [ "immich-protondrive-backup-setup.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        
        # Environment variables for rclone
        Environment = [
          "RCLONE_CONFIG=/var/cache/immich-protondrive-backup/rclone/rclone.conf"
        ];
        
        # Security hardening
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [
          cfg.syncLocation
          "/var/cache/immich-protondrive-backup"
        ];
        CacheDirectory = "immich-protondrive-backup";
      };
      
      script = ''
        ${pkgs.rclone}/bin/rclone sync \
          ${cfg.syncLocation} \
          ${cfg.remoteName}:${cfg.syncDestination} \
          ${cfg.extraRcloneArgs}
      '';
    };

    systemd.timers.immich-protondrive-backup = {
      description = "Timer for Immich backup to ProtonDrive";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = cfg.backupSchedule;
        Persistent = true;
        Unit = "immich-protondrive-backup.service";
      };
    };
  };
}
