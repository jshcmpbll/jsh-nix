{ lib, config, pkgs, latest, ... }:
let
  config = pkgs.writeText "config.nix" ''
  { allowUnfree = true; }
  '';
in
{
  nixpkgs.config.allowUnfree = true;
  imports = [
    (import ../lib/home-file.nix [
      { origin = "${config}"; target = "/home/jsh/.config"; }
    ])
  ];
}
