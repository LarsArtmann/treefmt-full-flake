{
  description = "Complete treefmt-flake configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-flake.url = "github:LarsArtmann/treefmt-full-flake";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.treefmt-flake.flakeModules.default
      ];

      treefmtFlake = {
        projectRootFile = "flake.nix";

        formatters = {
          nix = {
            enable = true;
            formatter = "nixfmt-rfc-style";
          };
          web.enable = true;
          python.enable = true;
          shell.enable = true;
          rust.enable = true;
          yaml.enable = true;
          markdown.enable = true;
          json.enable = true;
          misc.enable = true;
        };

        behavior = {
          allowMissingFormatter = false;
          enableDefaultExcludes = true;
        };

        incremental = {
          enable = true;
          mode = "git";
          cache = "./.cache/treefmt";
          gitBased = true;
        };

        git = {
          branch = "main";
        };
      };

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          buildInputs = [config.treefmt.build.wrapper];
        };
      };
    };
}
