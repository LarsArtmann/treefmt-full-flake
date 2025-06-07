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
      systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      flake = {
        # Export the treefmt modules for use in other flakes
        flakeModule = ./flake-module.nix;

        # Export individual formatter modules
        formatterModules = {
          nix = ./formatters/nix.nix;
          web = ./formatters/web.nix;
          python = ./formatters/python.nix;
          shell = ./formatters/shell.nix;
          rust = ./formatters/rust.nix;
          yaml = ./formatters/yaml.nix;
          markdown = ./formatters/markdown.nix;
          json = ./formatters/json.nix;
          misc = ./formatters/misc.nix;
        };

        # Export templates for common configurations
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
        };
      };

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        # Example configuration for this flake itself
        # This serves as a demonstration of how to use the flake

        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            prettier.enable = true;
            shfmt.enable = true;
          };
        };

        # Make the formatter available as a package
        formatter = config.treefmt.build.wrapper;

        # Create a development shell with all tools
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Formatters
            config.treefmt.build.wrapper
          ];

          shellHook = ''
            echo "Welcome to the treefmt-flake development environment!"
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
