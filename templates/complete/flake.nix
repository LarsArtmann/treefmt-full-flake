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

        autoDetection = {
          enable = true;
          aggressive = false;
          override = "merge";
        };

        formatters = {
          nix = {
            enable = true;
            formatter = "nixfmt-rfc-style";
            linting = {
              deadnix = true;
              statix = true;
            };
          };
          web = {
            enable = true;
            formatter = "biome";
            languages = {
              javascript = true;
              typescript = true;
              css = true;
              scss = true;
              json = true;
            };
          };
          python = {
            enable = true;
            formatters = {
              black = true;
              isort = true;
              ruff = true;
            };
          };
          shell = {
            enable = true;
            formatters = {
              shfmt = true;
              shellcheck = true;
            };
          };
          rust = {
            enable = true;
            formatters = {rustfmt = true;};
          };
          yaml = {
            enable = true;
            formatters = {yamlfmt = true;};
          };
          markdown = {
            enable = true;
            formatters = {mdformat = true;};
          };
          json = {
            enable = true;
            formatters = {jsonfmt = true;};
          };
          misc = {
            enable = true;
            tools = {
              buf = true;
              taplo = true;
              just = true;
              actionlint = true;
            };
          };
        };

        behavior = {
          performance = "balanced";
          allowMissingFormatter = false;
          enableDefaultExcludes = true;
        };

        incremental = {
          enable = true;
          mode = "git";
          cache = "./.cache/treefmt";
          gitBased = true;
          performance = {
            parallel = true;
            maxJobs = 4;
          };
        };

        git = {
          branch = "main";
          stagedOnly = false;
          hooks = {
            preCommit = false;
            prePush = false;
          };
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
