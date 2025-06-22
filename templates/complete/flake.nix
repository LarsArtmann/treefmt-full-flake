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

      # Complete configuration using unified schema with all features enabled
      treefmtFlake = {
        # Project configuration
        projectRootFile = "flake.nix";

        # Auto-detection settings with aggressive detection
        autoDetection = {
          enable = true;
          aggressive = false; # Set to true for more formatters
          override = "merge"; # How to handle auto-detection vs user settings
        };

        # All available formatters enabled
        formatters = {
          nix = {
            enable = true;
            formatter = "nixfmt-rfc-style"; # Deterministic Nix formatting
            linting = {
              deadnix = true; # Dead code detection
              statix = true; # Nix linting
            };
          };

          web = {
            enable = true;
            formatter = "biome"; # Fast JS/TS/CSS formatter
            languages = {
              javascript = true;
              typescript = true;
              css = true;
              scss = true;
              json = true;
              html = false; # Optional, enable if needed
            };
          };

          python = {
            enable = true;
            formatters = {
              black = true; # Code formatting
              isort = true; # Import sorting
              ruff = true; # Fast linting and formatting
            };
          };

          shell = {
            enable = true;
            formatters = {
              shfmt = true; # Shell script formatting
              shellcheck = true; # Shell script linting
            };
          };

          rust = {
            enable = true;
            formatters = {
              rustfmt = true; # Rust code formatting
            };
          };

          yaml = {
            enable = true;
            formatters = {
              yamlfmt = true; # YAML formatting
            };
          };

          markdown = {
            enable = true;
            formatters = {
              mdformat = true; # Markdown formatting
            };
          };

          json = {
            enable = true;
            formatters = {
              jsonfmt = true; # JSON formatting
            };
          };

          misc = {
            enable = true;
            tools = {
              buf = true; # Protocol Buffer formatting
              taplo = true; # TOML formatting
              just = true; # Justfile formatting
              actionlint = true; # GitHub Actions linting
            };
          };
        };

        # Performance and behavior settings
        behavior = {
          performance = "balanced"; # fast/balanced/thorough
          allowMissingFormatter = false;
          enableDefaultExcludes = true;
        };

        # Advanced incremental formatting (10-100x faster for large projects)
        incremental = {
          enable = true;
          mode = "git"; # git/cache/auto
          cache = "./.cache/treefmt";
          gitBased = true;
          performance = {
            parallel = true; # Enable parallel processing
            maxJobs = 4; # Maximum parallel jobs
          };
        };

        # Git integration settings
        git = {
          branch = "main"; # Compare against main branch
          stagedOnly = false; # Format all changed files
          sinceCommit = null; # Optional: format since specific commit
          hooks = {
            preCommit = false; # Set to true to install pre-commit hook
            prePush = false; # Set to true to install pre-push hook
          };
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
            echo "🚀 Welcome to the complete treefmt development environment!"
            echo ""
            echo "📝 Formatting Commands:"
            echo "  nix fmt                     - Format all files (incremental)"
            echo "  nix fmt -- --check         - Check formatting without changes"
            echo ""
            echo "⚡ Incremental Commands (10-100x faster):"
            echo "  nix run .#treefmt-fast     - Ultra-fast formatting (no cache)"
            echo "  nix run .#treefmt-staged   - Format only staged files"
            echo "  nix run .#treefmt-since    - Format files changed since commit"
            echo ""
            echo "🔧 Debug & Validation:"
            echo "  nix run .#treefmt-debug    - Show detailed configuration analysis"
            echo "  nix run .#treefmt-validate - Validate configuration and formatters"
            echo "  nix run .#test-validation   - Run integration test suite"
            echo ""
            echo "🎯 Performance Profiles (behavior.performance):"
            echo "  fast      - Skip expensive operations, no cache"
            echo "  balanced  - Default performance with smart caching"
            echo "  thorough  - Comprehensive checking with full walk"
            echo ""
            echo "💡 All formatters enabled: Nix, Web, Python, Shell, Rust, YAML, Markdown, JSON, Misc"
            echo "📖 Documentation: https://github.com/LarsArtmann/treefmt-full-flake"
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
