{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
    poetry2nix = {
      #url = "/home/finkernagel/upstream/poetry2nix";
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    poetry2nix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (poetry2nix.lib.mkPoetry2Nix {inherit pkgs;}) mkPoetryEnv defaultPoetryOverrides;
    in {
      packages = {
        myapp = mkPoetryEnv {
          projectDir = self;
          python = pkgs.python312;
          overrides = defaultPoetryOverrides.extend (final: prev: {
            safetensors = prev.safetensors.override {preferWheel = true;};
          });
          # preferWheels = true; if uncommented, safetensors wheel is being used
        };
      };

      defaultPackage = self.packages.${system}.myapp;

      # Shell for app dependencies.
      devShells.default = pkgs.mkShell {
        inputsFrom = [self.packages.${system}.myapp];
      };

      # Shell for poetry.
      devShells.poetry = pkgs.mkShell {
        packages = [pkgs.poetry];
      };
    });
}
