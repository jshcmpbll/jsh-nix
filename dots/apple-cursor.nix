{ lib, config, pkgs, latest, ... }:
let
  cursor-theme = "macOS-BigSur";
  gtk-settings = pkgs.writeText "settings.ini" ''
    [Settings]
      gtk-cursor-theme-name=${cursor-theme}
  '';
in
{
  imports = [
    (import ../lib/home-file.nix [
      {
        origin = "${pkgs.apple-cursor}/share/icons/${cursor-theme}/cursors";
        target = "/home/jsh/.local/share/icons/${cursor-theme}/cursors";
      }
      {
        origin = "${pkgs.apple-cursor}/share/icons/${cursor-theme}/cursor.theme";
        target = "/home/jsh/.local/share/icons/${cursor-theme}/cursor.theme";
      }
      {
        origin = "${pkgs.apple-cursor}/share/icons/${cursor-theme}/index.theme";

        target = "/home/jsh/.local/share/icons/${cursor-theme}/index.theme";
      }
      {
        origin = "${gtk-settings}";
        target = "/home/jsh/.config/gtk-3.0/settings.ini";
      }
    ])
  ];

  environment.variables = {
    GTK_CURSOR_THEME_NAME = cursor-theme;
  };
}

