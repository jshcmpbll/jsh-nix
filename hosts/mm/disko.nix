{ lib, ... }:
let
  mkDisk = { name, device }: {
    type = "disk";
    device = device;
    content = {
      type = "gpt";
      partitions = {
        zfs = {
          size = "100%";
          content = {
            type = "zfs";
            pool = "cpool";
          };
        };
      };
    };
  };

  disks = [
    { name = "a"; device = "/dev/disk/by-id/ata-HGST_HUH721008ALE604_2SGJA9EJ"; }
    { name = "b"; device = "/dev/disk/by-id/ata-HGST_HUH721008ALE604_2SGJDR9J"; }
    { name = "c"; device = "/dev/disk/by-id/ata-HGST_HUH721008ALE604_2SGKWE2J"; }
    { name = "d"; device = "/dev/disk/by-id/ata-HGST_HUH721008ALE604_2SGJAJYJ"; }
  ];
in
{
  disko.devices = {
    disk = lib.listToAttrs (map
      (d: {
        name = d.name;
        value = mkDisk d;
      })
      disks);
    zpool = {
      cpool = {
        type = "zpool";
        mode = "raidz1";
        options.cachefile = "none";
        options.ashift = "12";
        rootFsOptions = {
          compression = "zstd";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot@blank$' || zfs snapshot zroot@blank";
        datasets = {
          "TV" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home/jsh/TV";
          };
          "Movies" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home/jsh/Movies";
          };
          "immich" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/lib/immich";
          };
        };
      };
    };
  };
}
