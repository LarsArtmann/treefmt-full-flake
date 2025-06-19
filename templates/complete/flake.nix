{
  description = "Project using complete treefmt-flake configuration";

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
      url = "git+ssh://git@github.com/LarsArtmann/treefmt-full-flake.git"; # using the ssh url to support private repo auth
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

      # Enable all formatter groups
      treefmtFlake = {
        nix = true;
        web = true;
        python = true;
        shell = true;
        rust = true;
        yaml = true;
        markdown = true;
        json = true;
        misc = true;

        # Configure project root
        projectRootFile = "flake.nix";

        # Enable default excludes
        enableDefaultExcludes = true;

        # Don't allow missing formatters
        allowMissingFormatter = false;

        # Enable incremental formatting for 10-100x faster formatting
        incremental = {
          enable = true;
          mode = "git"; # Use git for change detection
          gitBased = true;
          cache = "./.cache/treefmt"; # Project-local cache
        };

        # Use balanced performance profile (fast/balanced/thorough)
        performance = "balanced";

        # Git-specific options for incremental formatting
        gitOptions = {
          branch = "main"; # Compare against main branch
          stagedOnly = false; # Format all changed files, not just staged
        };
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
            echo "Available formatting commands:"
            echo "  nix fmt                     - Format all files (incremental when enabled)"
            echo "  nix fmt -- --fail-on-change  - Check formatting without changes"
            echo ""
            echo "Incremental formatting commands (10-100x faster):"
            echo "  nix run .#treefmt-fast     - Ultra-fast formatting (no cache)"
            echo "  nix run .#treefmt-staged   - Format only staged files"
            echo "  nix run .#treefmt-since    - Format files changed since commit"
            echo ""
            echo "Performance profiles:"
            echo "  fast      - Skip expensive operations, no cache"
            echo "  balanced  - Default performance with smart caching"
            echo "  thorough  - Comprehensive checking with full walk"
            echo ""
            echo "📖 Quick Start Guide: https://github.com/LarsArtmann/treefmt-full-flake/blob/master/QUICKSTART.md"
            echo ""
          '';
        };

        # Example of extending the configuration with custom formatters
        treefmt.programs = {
          # Add any project-specific formatter configurations here
        };
      };
    };
}
