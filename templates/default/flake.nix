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
    # REPLACE THIS with your actual treefmt-flake source:
    # For public release: url = "github:LarsArtmann/treefmt-full-flake";
    # For local development: url = "path:../path/to/treefmt-full-flake";
    # For private repo: url = "git+ssh://git@github.com/LarsArtmann/treefmt-full-flake.git";
    treefmt-flake = {
      url = "path:./treefmt-flake-source"; # REPLACE with actual source
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        # Import treefmt-nix and treefmt-flake modules
        inputs.treefmt-nix.flakeModule
        inputs.treefmt-flake.flakeModule
      ];

      # Configure common formatter set using unified schema
      treefmtFlake = {
        # Project configuration
        projectRootFile = "flake.nix";

        # Auto-detection settings
        autoDetection.enable = true;

        # Common formatters for multi-language projects
        formatters = {
          nix.enable = true; # Nix code formatting
          web.enable = true; # JavaScript/TypeScript/CSS
          python.enable = true; # Python code formatting
          shell.enable = true; # Shell script formatting
          yaml.enable = true; # YAML configuration files
          markdown.enable = true; # Documentation formatting
          json.enable = true; # JSON file formatting
        };

        # Performance and behavior settings
        behavior = {
          performance = "balanced";
          allowMissingFormatter = false;
          enableDefaultExcludes = true;
        };

        # Optional: Enable incremental formatting for better performance
        incremental = {
          enable = false; # Set to true for large projects
          mode = "auto";
          cache = "./.cache/treefmt";
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
            echo "Available commands:"
            echo "  nix fmt                - Format all files"
            echo "  nix fmt -- --fail-on-change  - Check formatting without changing files"
            echo ""
            echo "📖 Quick Start Guide: https://github.com/LarsArtmann/treefmt-full-flake/blob/master/QUICKSTART.md"
            echo ""
          '';
        };
      };
    };
}
