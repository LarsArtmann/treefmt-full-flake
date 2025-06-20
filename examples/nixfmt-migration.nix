# Example configurations for migrating from Alejandra to nixfmt-rfc-style
{
  # Example 1: Simple migration using the flake module option
  example1-simple = {
    imports = [treefmt-full-flake.flakeModule];

    treefmtFlake = {
      nix = true;
      nixFormatter = "nixfmt-rfc-style"; # Switch from default alejandra

      # Enable other formatters as needed
      markdown = true;
      yaml = true;
    };
  };

  # Example 2: Gradual migration with exclusions
  example2-gradual = {
    imports = [treefmt-full-flake.flakeModule];

    treefmtFlake = {
      nix = true;
      nixFormatter = "nixfmt-rfc-style";

      # Exclude directories not yet ready for migration
      enableDefaultExcludes = true;
    };

    perSystem = {...}: {
      treefmt.settings.excludes = [
        "legacy/**/*.nix" # Old code not yet migrated
        "vendor/**/*.nix" # Third-party code
        "generated/**/*.nix" # Auto-generated files
      ];
    };
  };

  # Example 3: Custom formatter configuration
  example3-custom = {
    perSystem = {pkgs, ...}: {
      treefmt = {
        projectRootFile = "flake.nix";

        programs = {
          # Use nixfmt-rfc-style instead of alejandra
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rfc-style;
            includes = ["**/*.nix"];
            excludes = ["**/hardware-configuration.nix"];
          };

          # Keep other Nix tools
          deadnix = {
            enable = true;
            includes = ["**/*.nix"];
          };

          statix = {
            enable = true;
            includes = ["**/*.nix"];
          };
        };
      };
    };
  };

  # Example 4: Side-by-side comparison setup
  example4-comparison = {
    perSystem = {pkgs, ...}: {
      packages = {
        # Create formatter using alejandra
        format-alejandra = pkgs.writeShellScriptBin "format-alejandra" ''
          ${pkgs.alejandra}/bin/alejandra "$@"
        '';

        # Create formatter using nixfmt-rfc-style
        format-nixfmt = pkgs.writeShellScriptBin "format-nixfmt" ''
          ${pkgs.nixfmt-rfc-style}/bin/nixfmt "$@"
        '';

        # Compare formatters
        compare-formatters = pkgs.writeShellScriptBin "compare-formatters" ''
          #!/usr/bin/env bash
          set -euo pipefail

          if [[ $# -eq 0 ]]; then
            echo "Usage: $0 <nix-file>"
            exit 1
          fi

          FILE="$1"
          TEMP_DIR=$(mktemp -d)

          echo "Formatting with Alejandra..."
          cp "$FILE" "$TEMP_DIR/alejandra.nix"
          ${pkgs.alejandra}/bin/alejandra "$TEMP_DIR/alejandra.nix" 2>/dev/null || true

          echo "Formatting with nixfmt-rfc-style..."
          cp "$FILE" "$TEMP_DIR/nixfmt.nix"
          ${pkgs.nixfmt-rfc-style}/bin/nixfmt "$TEMP_DIR/nixfmt.nix" 2>/dev/null || true

          echo "Showing differences..."
          ${pkgs.diffutils}/bin/diff -u "$TEMP_DIR/alejandra.nix" "$TEMP_DIR/nixfmt.nix" || true

          rm -rf "$TEMP_DIR"
        '';
      };
    };
  };

  # Example 5: CI/CD configuration with determinism check
  example5-ci = {
    imports = [treefmt-full-flake.flakeModule];

    treefmtFlake = {
      nix = true;
      nixFormatter = "nixfmt-rfc-style";
    };

    perSystem = {
      pkgs,
      config,
      ...
    }: {
      packages = {
        # Check formatter determinism
        check-determinism = pkgs.writeShellScriptBin "check-determinism" ''
          #!/usr/bin/env bash
          set -euo pipefail

          echo "Checking formatter determinism..."

          # Create temporary directory
          TEMP_DIR=$(mktemp -d)
          cp -r . "$TEMP_DIR/test"
          cd "$TEMP_DIR/test"

          # Format once
          echo "First formatting pass..."
          ${config.formatter}/bin/treefmt
          find . -name "*.nix" -type f -exec sha256sum {} \; | sort > ../first-pass.sha

          # Format again
          echo "Second formatting pass..."
          ${config.formatter}/bin/treefmt
          find . -name "*.nix" -type f -exec sha256sum {} \; | sort > ../second-pass.sha

          # Compare
          if diff ../first-pass.sha ../second-pass.sha > /dev/null; then
            echo "✓ Formatter is deterministic!"
            exit 0
          else
            echo "✗ Formatter is NOT deterministic!"
            echo "Files that changed between runs:"
            diff ../first-pass.sha ../second-pass.sha || true
            exit 1
          fi
        '';
      };

      # Add to CI checks
      checks = {
        formatting-determinism = pkgs.runCommand "check-formatting-determinism" {} ''
          ${config.packages.check-determinism}/bin/check-determinism
          touch $out
        '';
      };
    };
  };

  # Example 6: Project template with nixfmt-rfc-style
  example6-template = {
    description = "Template using nixfmt-rfc-style";

    path = ./template;

    # Template files would include:
    # - flake.nix with nixFormatter = "nixfmt-rfc-style"
    # - .envrc for direnv integration
    # - justfile with formatting commands
    # - README.md explaining the formatter choice
  };
}
