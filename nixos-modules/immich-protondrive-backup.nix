{
  config,
  lib,
  pkgs,
  latest2,
  ...
}:
let
  cfg = config.immich-protondrive-backup;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str bool nullOr path;
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
      default = "";
      description = "ProtonDrive username (email address; prefer usernameFile)";
      example = "you@protonmail.com";
    };

    usernameFile = mkOption {
      type = nullOr path;
      default = null;
      description = "File containing ProtonDrive username (email address)";
    };
    
    password = mkOption {
      type = str;
      default = "";
      description = "ProtonDrive login password (plaintext; prefer passwordFile)";
    };

    passwordFile = mkOption {
      type = nullOr path;
      default = null;
      description = "File containing ProtonDrive login password";
    };

    mailboxPassword = mkOption {
      type = str;
      default = "";
      description = "Mailbox password for two-password Proton accounts (plaintext; prefer mailboxPasswordFile)";
    };

    mailboxPasswordFile = mkOption {
      type = nullOr path;
      default = null;
      description = "File containing Proton mailbox password";
    };

    otpSecretKey = mkOption {
      type = str;
      default = "";
      description = "OTP secret key for automatic 2FA (plaintext; prefer otpSecretKeyFile)";
    };

    otpSecretKeyFile = mkOption {
      type = nullOr path;
      default = null;
      description = "File containing OTP secret key";
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
      default = "--verbose";
      description = "Additional arguments to pass to rclone sync";
      example = "--progress --verbose --transfers 4";
    };
  };

  config = mkIf cfg.enable {
    # Validate required options
    assertions = [
      {
        assertion = cfg.username != "" || cfg.usernameFile != null;
        message = "immich-protondrive-backup: set username or usernameFile";
      }
      {
        assertion = cfg.password != "" || cfg.passwordFile != null;
        message = "immich-protondrive-backup: set password or passwordFile";
      }
      {
        assertion = cfg.mailboxPassword != "" || cfg.mailboxPasswordFile != null;
        message = "immich-protondrive-backup: set mailboxPassword or mailboxPasswordFile";
      }
      {
        assertion = cfg.otpSecretKey != "" || cfg.otpSecretKeyFile != null;
        message = "immich-protondrive-backup: set otpSecretKey or otpSecretKeyFile";
      }
    ];
    
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

        # Read secrets (from file if configured, otherwise from inline value)
        ${if cfg.usernameFile != null
          then "USERNAME=$(cat ${cfg.usernameFile})"
          else "USERNAME=${lib.escapeShellArg cfg.username}"}
        ${if cfg.passwordFile != null
          then "PASSWORD=$(cat ${cfg.passwordFile})"
          else "PASSWORD=${lib.escapeShellArg cfg.password}"}
        ${if cfg.mailboxPasswordFile != null
          then "MAILBOX_PASSWORD=$(cat ${cfg.mailboxPasswordFile})"
          else "MAILBOX_PASSWORD=${lib.escapeShellArg cfg.mailboxPassword}"}
        ${if cfg.otpSecretKeyFile != null
          then "OTP_KEY=$(cat ${cfg.otpSecretKeyFile})"
          else "OTP_KEY=${lib.escapeShellArg cfg.otpSecretKey}"}

        # Obscure passwords for rclone config
        OBSCURED_PASSWORD=$(${latest2.pkgs.rclone}/bin/rclone obscure "$PASSWORD")
        OBSCURED_MAILBOX_PASSWORD=$(${latest2.pkgs.rclone}/bin/rclone obscure "$MAILBOX_PASSWORD")
        OBSCURED_OTP_KEY=$(${latest2.pkgs.rclone}/bin/rclone obscure "$OTP_KEY")
        
        # Create rclone config file
        cat > /var/cache/immich-protondrive-backup/rclone/rclone.conf <<EOF
        [${cfg.remoteName}]
        type = protondrive
        username = $USERNAME
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
        ${latest2.pkgs.rclone}/bin/rclone copy \
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
