{ config, ... }:
{
  boot = {
    supportedFilesystems = [ "zfs" ];
  };

  services = {
    zfs = {
      autoScrub.enable = true;
      autoScrub.interval = "weekly";
      autoSnapshot = {
        daily = 1;
        enable = true;
      };
    };
  };
}
