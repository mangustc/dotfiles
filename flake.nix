{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, lanzaboote, ... }: {
    nixosConfigurations = {
      main = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          host = {
            name = "main";
          };
        };
        modules = [
          lanzaboote.nixosModules.lanzaboote
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              host = {
                name = "main";
              };
            };
            home-manager.users.ivan = ./home.nix;
          }
        ];
      };
      gaming = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          host = {
            name = "gaming";
          };
        };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              host = {
                name = "gaming";
              };
            };
            home-manager.users.ivan = ./home.nix;
          }
        ];
      };
    };
  };
}
