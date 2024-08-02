{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    vfio = {
      url = "github:clemenscodes/vfio";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
  };
  outputs = {
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        inherit (pkgs) lib;
        pkgs = import nixpkgs {inherit system;};
      in {
        packages = {
          nixosConfigurations = {
            default = lib.nixosSystem {
              specialArgs = {inherit inputs nixpkgs system pkgs;};
              modules = [
                ./hardware-configuration.nix
                ./configuration.nix
              ];
            };
          };
        };
      }
    );
}
