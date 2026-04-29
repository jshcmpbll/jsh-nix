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
      XAUTHORITY = "/home/jsh/.Xauthority";
    };
    serviceConfig = {
      User = "jsh";
      Group = "users";
      Type = "simple";
      ExecStart = "${pkgs.x11vnc}/bin/x11vnc -listen 0.0.0.0 -display :0 -auth /home/jsh/.Xauthority -forever -shared -nopw -verbose -xrandr -xinerama -clear_mods";
    };
    reloadIfChanged = true;
    restartIfChanged = true;
  };
}
