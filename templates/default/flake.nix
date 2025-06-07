{
  description = "Project using treefmt-flake";

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

      # Configure which formatter groups to enable
      treefmtFlake = {
        nix = true;
        web = true;
        python = true;
        shell = true;
        yaml = true;
        markdown = true;
        json = true;

        # Configure project root
        projectRootFile = "flake.nix";

        # Enable default excludes
        enableDefaultExcludes = true;

        # Don't allow missing formatters
        allowMissingFormatter = false;
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

          shellHook = ''
            echo "Welcome to the project development environment!"
            echo ""
            echo "Available commands:"
            echo "  nix fmt                - Format all files"
            echo "  nix fmt -- --check     - Check formatting without changing files"
            echo ""
          '';
        };
      };
    };
}
