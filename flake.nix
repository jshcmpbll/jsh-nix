{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, nixpkgs, nixos-hardware, nixpkgs-unstable }: {
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
          #inherit inputs;
        };
      };
      jsh-lenovo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/lenovo/configuration.nix
        ];
        specialArgs = {
          latest = import nixpkgs-unstable {
            system = "x86_64-linux";
            config = {
              allowUnfree = true;
              allowBroken = true;
            };
          };
          #inherit inputs;
        };
      };
    };
  };
}
