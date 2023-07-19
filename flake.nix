{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({lib, ...}: {
      systems = lib.subtractLists [
        "armv5tel-linux"
        "mipsel-linux"
      ] (lib.intersectLists lib.systems.flakeExposed lib.platforms.linux);

      imports = [
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
        ./nix/checks.nix
        ./nix/devshells.nix
        ./nix/packages.nix
      ];
    });
}
