{ lib, config, pkgs, latest, ... }:
let
  ssh-config = pkgs.writeText "config" ''
    Include /persist/ssh-config
  '';
in
{
  imports = [
    (import ../lib/home-file.nix [
      {
        origin = "${ssh-config}";
        target = "/home/jsh/.ssh/config";
      }
    ])
  ];
}
