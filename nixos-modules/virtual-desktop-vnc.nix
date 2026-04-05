# Virtual headless desktop accessible over VNC.
#
# Starts three systemd services: Xvfb → i3 → x11vnc
# Designed for machines with no physical display (Intel iGPU, no dummy plug).
#
# Minimal usage example:
#   virtual-desktop = {
#     enable = true;
#     user = "jsh";
#     vncPort = 5999;
#   };
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.virtual-desktop;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool enum int listOf nullOr path port str;

  display = ":${toString cfg.displayNumber}";
  xauth = "/run/virtual-desktop/xauth";

  # Wait for the Xvfb display to be accepting connections before proceeding.
  waitForDisplay = pkgs.writeShellScript "wait-for-display" ''
    until ${pkgs.xorg.xdpyinfo}/bin/xdpyinfo -display ${display} >/dev/null 2>&1; do
      sleep 0.1
    done
  '';

  commonEnv = {
    DISPLAY = display;
    XAUTHORITY = xauth;
  };
in
{
  options.virtual-desktop = {
    enable = mkEnableOption "Headless virtual desktop accessible over VNC";

    displayNumber = mkOption {
      type = int;
      default = 99;
      description = ''
        X display number for the virtual framebuffer (e.g. 99 → DISPLAY=:99).
        Avoid :0, which is reserved for physical display managers.
      '';
    };

    resolution = mkOption {
      type = str;
      default = "1920x1080x24";
      description = "Resolution and color depth for Xvfb in WxHxD format.";
      example = "2560x1440x24";
    };

    vncPort = mkOption {
      type = port;
      default = 5900;
      description = "TCP port for x11vnc to listen on.";
      example = 5999;
    };

    vncListenAddress = mkOption {
      type = str;
      default = "0.0.0.0";
      description = "IP address x11vnc binds to.";
    };

    user = mkOption {
      type = str;
      default = "jsh";
      description = "Unix user that runs Xvfb, i3, and x11vnc. Must already exist.";
    };

    windowManager = mkOption {
      type = enum [ "i3" "none" ];
      default = "i3";
      description = ''
        Window manager to start inside the virtual framebuffer.
        Use "none" for Xvfb + x11vnc only (no WM).
      '';
    };

    i3ConfigFile = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Path to an i3 config file. If null, i3 uses its built-in defaults.
        Supply a config that omits hardware-specific exec lines
        (NVIDIA settings, display brightness, etc.).
      '';
      example = "/etc/i3/virtual-config";
    };

    vncAuth = {
      enable = mkOption {
        type = bool;
        default = false;
        description = ''
          Require VNC password authentication. When false, x11vnc runs -nopw.
          WARNING: VNC passwords are weakly encrypted. Prefer SSH tunneling
          and binding vncListenAddress to 127.0.0.1 for production use.
        '';
      };

      passwordFile = mkOption {
        type = nullOr path;
        default = null;
        description = ''
          Path to an x11vnc password file created with:
            x11vnc -storepasswd <password> /path/to/passwd-file
          Must be readable by the configured user.
        '';
        example = "/persist/vnc-passwd";
      };
    };

    openFirewall = mkOption {
      type = bool;
      default = false;
      description = "Open vncPort in the NixOS firewall.";
    };

    extraXvfbArgs = mkOption {
      type = listOf str;
      default = [];
      description = "Extra arguments passed to Xvfb.";
      example = [ "-dpi" "96" ];
    };

    extraX11vncArgs = mkOption {
      type = listOf str;
      default = [];
      description = "Extra arguments passed to x11vnc.";
      example = [ "-cursor" "arrow" ];
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.displayNumber >= 1 && cfg.displayNumber <= 99;
        message = "virtual-desktop.displayNumber must be between 1 and 99 (display :0 is reserved)";
      }
      {
        assertion = !cfg.vncAuth.enable || cfg.vncAuth.passwordFile != null;
        message = "virtual-desktop.vncAuth.passwordFile must be set when vncAuth.enable = true";
      }
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.vncPort ];

    systemd.services.virtual-desktop-xvfb = {
      description = "Virtual framebuffer (Xvfb) for headless desktop";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = cfg.user;
        Type = "simple";
        RuntimeDirectory = "virtual-desktop";
        RuntimeDirectoryMode = "0700";
        ExecStart = lib.concatStringsSep " " ([
          "${pkgs.xorg.xorgserver}/bin/Xvfb"
          display
          "-screen" "0" cfg.resolution
          "-auth" xauth
        ] ++ cfg.extraXvfbArgs);
        Restart = "on-failure";
        RestartSec = "2s";
      };
    };

    systemd.services.virtual-desktop-wm = mkIf (cfg.windowManager == "i3") {
      description = "i3 window manager on virtual desktop";
      wantedBy = [ "multi-user.target" ];
      after = [ "virtual-desktop-xvfb.service" ];
      requires = [ "virtual-desktop-xvfb.service" ];
      environment = commonEnv;
      serviceConfig = {
        User = cfg.user;
        Type = "simple";
        ExecStartPre = "${waitForDisplay}";
        ExecStart = lib.concatStringsSep " " (
          [ "${pkgs.i3-gaps}/bin/i3" ]
          ++ lib.optionals (cfg.i3ConfigFile != null) [ "-c" cfg.i3ConfigFile ]
        );
        Restart = "on-failure";
        RestartSec = "2s";
      };
    };

    systemd.services.virtual-desktop-vnc = {
      description = "x11vnc VNC server on virtual desktop";
      wantedBy = [ "multi-user.target" ];
      after = [ "virtual-desktop-xvfb.service" "virtual-desktop-wm.service" ];
      requires = [ "virtual-desktop-xvfb.service" ];
      environment = commonEnv;
      serviceConfig = {
        User = cfg.user;
        Type = "simple";
        ExecStartPre = "${waitForDisplay}";
        ExecStart = lib.concatStringsSep " " ([
          "${pkgs.x11vnc}/bin/x11vnc"
          "-display" display
          "-auth" xauth
          "-rfbport" (toString cfg.vncPort)
          "-listen" cfg.vncListenAddress
          "-forever"
          "-shared"
          (if cfg.vncAuth.enable then "-rfbauth ${cfg.vncAuth.passwordFile}" else "-nopw")
        ] ++ cfg.extraX11vncArgs);
        Restart = "on-failure";
        RestartSec = "2s";
      };
    };
  };
}
