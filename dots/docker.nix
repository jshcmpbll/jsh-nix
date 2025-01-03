{ config, pkgs, lib, ... }:
{
  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
  };
  hardware.nvidia-container-toolkit.enable = builtins.elem "nvidia" config.services.xserver.videoDrivers;
}
