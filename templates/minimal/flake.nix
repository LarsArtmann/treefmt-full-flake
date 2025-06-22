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
    # REQUIRED: Replace this URL with your treefmt-flake access method:
    # For SSH access: url = "git+ssh://git@github.com/LarsArtmann/treefmt-full-flake.git";
    # For local clone: url = "path:/path/to/your/treefmt-full-flake";
    # For future public: url = "github:LarsArtmann/treefmt-full-flake";
    treefmt-flake = {
      url = "git+ssh://git@github.com/LarsArtmann/treefmt-full-flake.git"; # CHANGE THIS
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

      # Configure minimal formatter set using unified schema
      treefmtFlake = {
        # Project configuration
        projectRootFile = "flake.nix";

        # Auto-detection settings
        autoDetection.enable = true;

        # Essential formatters for most projects
        formatters = {
          nix.enable = true; # Nix code formatting
          markdown.enable = true; # README and documentation
          yaml.enable = true; # Configuration files
        };

        # Performance and behavior settings
        behavior = {
          performance = "balanced";
          allowMissingFormatter = false;
          enableDefaultExcludes = true;
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
            echo "Welcome to the minimal treefmt environment!"
            echo ""
            echo "Commands:"
            echo "  nix fmt                     - Format all files"
            echo "  nix fmt -- --fail-on-change  - Check formatting"
            echo ""
            echo "📖 Quick Start: https://github.com/LarsArtmann/treefmt-full-flake/blob/master/QUICKSTART.md"
            echo ""
          '';
        };
      };
    };
}
