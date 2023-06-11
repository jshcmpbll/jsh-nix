{ pkgs, ... }:
{
  systemd.services.x11vnc-local = {
    enable = true;
    path = [ pkgs.gawk pkgs.nettools ];
    requires = [ "graphical.target" ];
    after = [ "display-manager.service" ];
    description = "Localhost VNC server";
    serviceConfig = {
      User = "jsh";
      Group = "users";
      Type = "simple";
      ExecStart = "${pkgs.x11vnc}/bin/x11vnc -listen 127.0.0.1 -xkb -auth /run/user/1000/gdm/Xauthority -display :1 -forever -nopw";
    };
    reloadIfChanged = true;
    restartIfChanged = true;
  };
}
