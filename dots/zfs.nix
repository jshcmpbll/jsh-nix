{ config, lib, ... }:
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
  systemd.timers.zfs-snapshot-frequent.timerConfig = if config.networking.hostName == "jsh-server" then lib.mkForce {
    OnCalendar = "*:0,5,10,15,20,25,30,35,40,45,50,55";
    Persistent = "yes";
  } else lib.mkForce {
    OnCalendar = "*:0,10,20,30,40,50";
    Persistent = "yes";
  };
  services.zfs.autoSnapshot.frequent = if config.networking.hostName == "jsh-server" then 12 else 6;
}
