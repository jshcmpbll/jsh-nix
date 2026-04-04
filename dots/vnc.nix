{ pkgs, ... }:
{
  systemd.services.x11vnc = {
    enable = true;
    path = [ pkgs.gawk pkgs.nettools ];
    requires = [ "graphical.target" ];
    after = [ "display-manager.service" ];
    description = "VNC server";
    environment = {
      DISPLAY = ":0";
      XAUTHORITY = "/var/run/lightdm/root/:0";
    };
    serviceConfig = {
      User = "jsh";
      Group = "users";
      Type = "simple";
      ExecStart = "${pkgs.x11vnc}/bin/x11vnc -listen 0.0.0.0 -display :0 -auth /var/run/lightdm/root/:0 -forever -shared -nopw -verbose -xrandr -xinerama";
    };
    reloadIfChanged = true;
    restartIfChanged = true;
  };
}
