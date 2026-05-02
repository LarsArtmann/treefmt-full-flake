# Example configurations for migrating from Alejandra to nixfmt-rfc-style
{
  # Example 1: Simple migration using the flake module option
  example1-simple = {
    imports = [treefmt-full-flake.flakeModules.default];

    treefmtFlake = {
      formatters = {
        nix = {
          enable = true;
          formatter = "nixfmt-rfc-style";
        };
        markdown.enable = true;
        yaml.enable = true;
      };
    };
  };

  # Example 2: Gradual migration with exclusions
  example2-gradual = {
    imports = [treefmt-full-flake.flakeModules.default];

    treefmtFlake = {
      formatters.nix = {
        enable = true;
        formatter = "nixfmt-rfc-style";
      };
      behavior.enableDefaultExcludes = true;
    };

    perSystem = _: {
      treefmt.settings.excludes = [
        "legacy/**/*.nix"
        "vendor/**/*.nix"
        "generated/**/*.nix"
      ];
    };
  };

  # Example 3: Custom formatter configuration
  example3-custom = {
    perSystem = {pkgs, ...}: {
      treefmt = {
        projectRootFile = "flake.nix";

        programs = {
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rfc-style;
            includes = ["**/*.nix"];
            excludes = ["**/hardware-configuration.nix"];
          };

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
        format-alejandra = pkgs.writeShellScriptBin "format-alejandra" ''
          ${pkgs.alejandra}/bin/alejandra "$@"
        '';

        format-nixfmt = pkgs.writeShellScriptBin "format-nixfmt" ''
          ${pkgs.nixfmt-rfc-style}/bin/nixfmt "$@"
        '';

        compare-formatters = pkgs.writeShellScriptBin "compare-formatters" ''
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
        '';
      };
    };
  };

  # Example 5: CI/CD configuration with determinism check
  example5-ci = {
    imports = [treefmt-full-flake.flakeModules.default];

    treefmtFlake = {
      formatters.nix = {
        enable = true;
        formatter = "nixfmt-rfc-style";
      };
    };

    perSystem = {
      pkgs,
      config,
      ...
    }: {
      packages = {
        check-determinism = pkgs.writeShellScriptBin "check-determinism" ''
          set -euo pipefail

          echo "Checking formatter determinism..."

          TEMP_DIR=$(mktemp -d)
          cp -r . "$TEMP_DIR/test"
          cd "$TEMP_DIR/test"

          echo "First formatting pass..."
          ${config.formatter}/bin/treefmt
          find . -name "*.nix" -type f -exec sha256sum {} \; | sort > ../first-pass.sha

          echo "Second formatting pass..."
          ${config.formatter}/bin/treefmt
          find . -name "*.nix" -type f -exec sha256sum {} \; | sort > ../second-pass.sha

          if diff ../first-pass.sha ../second-pass.sha > /dev/null; then
            echo "Formatter is deterministic!"
            exit 0
          else
            echo "Formatter is NOT deterministic!"
            diff ../first-pass.sha ../second-pass.sha || true
            exit 1
          fi
        '';
      };

      checks = {
        formatting-determinism = pkgs.runCommand "check-formatting-determinism" {} ''
          ${config.packages.check-determinism}/bin/check-determinism
          touch $out
        '';
      };
    };
  };
}
