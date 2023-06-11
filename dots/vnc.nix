{ pkgs, ... }:
{
  systemd.services.x11vnc = {
    enable = true;
    path = [ pkgs.gawk pkgs.nettools ];
    requires = [ "graphical.target" ];
    after = [ "display-manager.service" ];
    description = "VNC server";
    serviceConfig = {
      User = "jsh";
      Group = "users";
      Type = "simple";
      ExecStart = "${pkgs.x11vnc}/bin/x11vnc -xkb -auth /run/user/1000/gdm/Xauthority -display :1 -forever -nopw";
    };
    reloadIfChanged = true;
    restartIfChanged = true;
  };
}
