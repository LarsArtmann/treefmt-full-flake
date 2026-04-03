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

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
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
        lib = import ./lib {inherit (inputs.nixpkgs) lib;};

        # Export overlay for extending nixpkgs
        overlays.default = final: prev: {
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

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        # Configure treefmt for this project
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            prettier.enable = true;
            shfmt.enable = true;
          };
        };

        # Development shell with all tools
        devShells.default = pkgs.mkShell {
          buildInputs = [
            config.treefmt.build.wrapper
            pkgs.typespec
          ];

          shellHook = ''
            echo "treefmt-flake development environment"
            echo ""
            echo "Available commands:"
            echo "  nix fmt              - Format all files"
            echo "  nix fmt -- --check   - Check formatting without changes"
            echo "  nix run .#treefmt-debug - Show debug information"
          '';
        };
      };
    };
}
