# Module options for treefmt-flake
{lib, ...}: let
  mkEnum = values: default: description:
    lib.mkOption {
      type = lib.types.enum values;
      inherit default description;
    };
in {
  options.treefmtFlake = lib.mkOption {
    type = lib.types.submodule {
      options = {
        projectRootFile = lib.mkOption {
          type = lib.types.str;
          default = "flake.nix";
          description = "File that marks the project root";
        };

        formatters = lib.mkOption {
          type = lib.types.submodule {
            options = {
              nix = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Nix formatters";
                    formatter = mkEnum ["alejandra" "nixfmt-rfc-style"] "nixfmt-rfc-style" "Nix code formatter to use";
                  };
                };
                default = {};
                description = "Nix language formatting and linting";
              };

              web = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Web formatters (JS/TS/CSS)";
                  };
                };
                default = {};
                description = "Web development formatting (biome for JS/TS/CSS/JSON)";
              };

              python = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Python formatters";
                  };
                };
                default = {};
                description = "Python code formatting (black, isort, ruff)";
              };

              rust = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Rust formatters";
                  };
                };
                default = {};
                description = "Rust code formatting (rustfmt)";
              };

              shell = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Shell formatters";
                  };
                };
                default = {};
                description = "Shell script formatting (shfmt, shellcheck)";
              };

              markdown = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Markdown formatters";
                  };
                };
                default = {};
                description = "Markdown document formatting (mdformat)";
              };

              yaml = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "YAML formatters";
                  };
                };
                default = {};
                description = "YAML file formatting (yamlfmt)";
              };

              json = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "JSON formatters";
                  };
                };
                default = {};
                description = "JSON file formatting (jsonfmt)";
              };

              misc = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Miscellaneous formatters";
                  };
                };
                default = {};
                description = "Miscellaneous formatting tools (buf, taplo, just, actionlint, typespec)";
              };
            };
          };
          default = {};
          description = "Formatter configurations organized by domain";
        };

        behavior = lib.mkOption {
          type = lib.types.submodule {
            options = {
              allowMissingFormatter = lib.mkEnableOption "allow missing formatters without failing";
              enableDefaultExcludes = lib.mkEnableOption "default exclude patterns" // {default = true;};
            };
          };
          default = {};
          description = "Behavior configuration";
        };

        incremental = lib.mkOption {
          type = lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "incremental formatting";
              mode = mkEnum ["auto" "cache" "git"] "auto" "Incremental mode";
              cache = lib.mkOption {
                type = lib.types.str;
                default = "./.cache/treefmt";
                description = "Cache directory for treefmt";
              };
              gitBased = lib.mkEnableOption "git for change detection";
            };
          };
          default = {};
          description = "Incremental formatting configuration";
        };

        git = lib.mkOption {
          type = lib.types.submodule {
            options = {
              branch = lib.mkOption {
                type = lib.types.str;
                default = "main";
                description = "Compare against this branch for change detection";
              };
            };
          };
          default = {};
          description = "Git integration configuration";
        };
      };
    };
    default = {};
    description = "Configuration for treefmt-flake";
  };
}
