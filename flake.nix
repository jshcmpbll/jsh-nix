{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixpkgs-scan.url = "github:nixos/nixpkgs/bf3c55095633ed6d504b10e3612e30a9a72fcb6e";
  };

  outputs = { self, nixpkgs, nixos-hardware, nixpkgs-unstable, nixpkgs-scan }: {
    nixosConfigurations = {
      jsh-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server/configuration.nix
        ];
        specialArgs = {
          latest = import nixpkgs-unstable {
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
      };
      jsh-lenovo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/lenovo/configuration.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen3
        ];
        specialArgs = {
          latest = import nixpkgs-unstable {
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
      };
      jsh-mm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/mm/configuration.nix
          nixos-hardware.nixosModules.common-cpu-intel-cpu-only
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
    };
  };
}
