{
  description = "Minimal treefmt-flake project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-flake.url = "github:LarsArtmann/treefmt-full-flake";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.treefmt-flake.flakeModules.default
      ];

      treefmtFlake = {
        projectRootFile = "flake.nix";
        formatters.nix.enable = true;
      };
    };
}
