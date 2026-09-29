{
  description = "Reusable treefmt configuration for multiple projects";

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
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
        ./flake-module.nix
      ];

      flake = {
        # Export the flake module for use in other flakes
        flakeModules.default = ./flake-module.nix;
        flakeModule = ./flake-module.nix; # Backward compatibility

        # Export formatter modules for direct use
        formatterModules = {
          nix = ./formatters/nix.nix;
          nix-nixfmt = ./formatters/nix-nixfmt.nix;
          web = ./formatters/web.nix;
          python = ./formatters/python.nix;
          shell = ./formatters/shell.nix;
          rust = ./formatters/rust.nix;
          yaml = ./formatters/yaml.nix;
          markdown = ./formatters/markdown.nix;
          json = ./formatters/json.nix;
          misc = ./formatters/misc.nix;
        };

        # Export lib functions for programmatic use
        lib = import ./lib { inherit (inputs.nixpkgs) lib; };

        # Export overlay for extending nixpkgs
        overlays.default = _final: _prev: {
          treefmt-flake = {
            formatterModules = inputs.self.formatterModules;
            flakeModule = inputs.self.flakeModule;
            lib = inputs.self.lib;
          };
        };

        # Templates for common configurations
        templates = {
          default = {
            path = ./templates/default;
            description = "Default treefmt configuration with common formatters";
          };
          minimal = {
            path = ./templates/minimal;
            description = "Minimal treefmt configuration with essential formatters";
          };
          complete = {
            path = ./templates/complete;
            description = "Complete treefmt configuration with all formatters";
          };
          local-development = {
            path = ./templates/local-development;
            description = "Self-contained template that works immediately without external dependencies";
          };
        };
      };

      perSystem =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        let
          # Eval-time guard: importing the examples evaluates their bodies.
          # With an unbound identifier (they once referenced a bare
          # `treefmt-full-flake`), this import aborts flake evaluation
          # entirely — the failure cannot be silenced downstream.
          nixfmtMigrationExamples = import ./examples/nixfmt-migration.nix;
          exampleKinds = lib.concatStringsSep " " (
            lib.mapAttrsToList (
              name: value: "${name}:${if builtins.isFunction value then "function" else "attrset"}"
            ) nixfmtMigrationExamples
          );
          # Only the examples that import our flakeModule must be functions
          # of the input; example3-custom and example4-comparison use raw
          # treefmt-nix options and take no input.
          moduleExamples = lib.concatStringsSep " " (
            map (name: if builtins.isFunction nixfmtMigrationExamples.${name} then "ok" else name) [
              "example1-simple"
              "example2-gradual"
              "example5-ci"
            ]
          );
        in
        {
          checks.templateEval =
            pkgs.runCommandLocal "template-eval-check"
              {
                nativeBuildInputs = [ pkgs.nix ];
                inherit exampleKinds moduleExamples;
              }
              ''
                set -euo pipefail
                # nix-instantiate initializes user state on startup; point it
                # at the sandbox scratch dir or it dies creating
                # /nix/var/nix/profiles.
                export HOME=$TMPDIR
                export XDG_CONFIG_HOME=$TMPDIR/xdg-config
                export XDG_CACHE_HOME=$TMPDIR/xdg-cache
                # Migration examples: the import in this check's derivation
                # already proved there are no unbound identifiers; the
                # module-based examples must be functions of the input.
                for ex in $moduleExamples; do
                  if [ "$ex" != "ok" ]; then
                    echo "templateEval FAIL: $ex must be a function of the treefmt-full-flake input"
                    exit 1
                  fi
                done
                echo "  examples/nixfmt-migration: $exampleKinds"
                # Templates: every shipped template flake must parse.
                for t in default minimal complete local-development; do
                  nix-instantiate --parse ${./templates}/$t/flake.nix > /dev/null \
                    || { echo "templateEval FAIL: templates/$t/flake.nix does not parse"; exit 1; }
                  echo "  templates/$t: parse OK"
                done
                echo "templateEval OK"
                touch $out
              '';

          # Configure treefmt for this project
          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              prettier.enable = true;
              shfmt.enable = true;
            };
          };

          # Development shell with all tools
          devShells.default = pkgs.mkShellNoCC {
            packages = [ config.treefmt.build.wrapper ];

            shellHook = ''
              echo "treefmt-flake development environment"
              echo ""
              echo "Available commands:"
              echo "  nix fmt              - Format all files"
              echo "  nix fmt -- --fail-on-change - Check formatting without changes"
              echo "  nix run .#treefmt-debug - Show debug information"
            '';
          };
        };
    };
}
