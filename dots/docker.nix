{ config, pkgs, lib, ... }:
{
  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
  };
  hardware.nvidia-container-toolkit.enable = lib.mkIf (config.hardware.nvidia != null) true;
}
