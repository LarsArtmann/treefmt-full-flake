{
  description = "Project using minimal treefmt-flake configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Import the treefmt-flake
    treefmt-flake = {
      url = "github:LarsArtmann/treefmt-full-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

      imports = [
        # Import treefmt-nix and treefmt-flake modules
        inputs.treefmt-nix.flakeModule
        inputs.treefmt-flake.flakeModule
      ];

      # Configure minimal formatter set
      treefmtFlake = {
        nix = true;
        markdown = true;
        yaml = true;

        # Configure project root
        projectRootFile = "flake.nix";
      };

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        # Create a development shell with all tools
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Formatters
            config.treefmt.build.wrapper
          ];
        };
      };
    };
}
