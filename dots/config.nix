{ lib, config, pkgs, latest, ... }:
let
  config = pkgs.writeText "config.nix" ''
  {
    allowUnfree = true;
    download-buffer-size = 500000000
  }
  '';
in
{
  nixpkgs.config.allowUnfree = true;
  imports = [
    (import ../lib/home-file.nix [
      { origin = "${config}"; target = "/home/jsh/.config/nixpkgs/config.nix"; }
    ])
  ];
}
