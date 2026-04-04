{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master";
    nixpkgs-unstable2.url = "github:nixos/nixpkgs/master";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixpkgs-scan.url = "github:nixos/nixpkgs/bf3c55095633ed6d504b10e3612e30a9a72fcb6e";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { self, disko, nixpkgs, nixos-hardware, nixpkgs-unstable, nixpkgs-unstable2, nixpkgs-scan }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      sA = {
        inherit inputs;
        latest = import nixpkgs-unstable {
          system = "x86_64-linux";
          config = {
            allowUnfree = true;
            allowBroken = true;
          };
        };
        latest2 = import nixpkgs-unstable2 {
          system = "x86_64-linux";
          config = {
            allowUnfree = true;
            allowBroken = true;
          };
        };
        scan = import nixpkgs-scan {
          system = "x86_64-linux";
        };
      };

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
      packages.x86_64-linux = {
        finvizrec = pkgs.callPackage ./apps/finvizrec/default.nix { };
        receipt-api = pkgs.callPackage ./apps/receipt-api/default.nix { };
      };
      nixosModules = import ./nixos-modules inputs;
      nixosConfigurations = {
        jsh-server = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/server/configuration.nix
          ];
          specialArgs = sA;
        };
        jsh-lenovo = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/lenovo/configuration.nix
            nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen3
          ];
          specialArgs = sA;
        };
        jsh-mm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.self.nixosModules.default
            ./hosts/mm/configuration.nix
            ./hosts/mm/disko.nix
            nixos-hardware.nixosModules.common-cpu-intel-cpu-only
            inputs.disko.nixosModules.disko
          ];
          specialArgs = sA;
        };
        jsh-mms = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/mms/configuration.nix
          ];
          specialArgs = {
            latest = import nixpkgs-unstable {
              system = "x86_64-linux";
              config = {
                allowUnfree = true;
                allowBroken = true;
              };
            };
          };
        };
        pool = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/pool/configuration.nix
            nixos-hardware.nixosModules.common-cpu-intel-cpu-only
          ];
          specialArgs = sA;
        };
      };
      disko.devices = {
        disk = nixpkgs.lib.listToAttrs (map (d: {
          name = d.name;
          value = mkDisk d;
        }) disks);
        zpool = {
          cpool = {
            type = "zpool";
            mode = "raidz1";
            options.cachefile = "none";
            options.ashift = "12";
            rootFsOptions = {
              compression = "zstd";
              acltype = "psixacl";
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
            };
          };
        };
      };
    };
}
