# Module options for treefmt-flake
# Separated from implementation for cleaner structure
{lib, ...}: let
  # Helper for enum types with better error messages
  mkEnum = values: default: description:
    lib.mkOption {
      type = lib.types.enum values;
      inherit default description;
    };

  # Helper for nullable boolean
  mkNullableBool = default: description:
    lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
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

        autoDetection = lib.mkOption {
          type = lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "automatic formatter detection" // {default = true;};
              aggressive = lib.mkEnableOption "aggressive auto-detection";
              override = mkEnum ["user" "auto" "merge"] "merge" "How to handle conflicts between auto-detection and user settings";
            };
          };
          default = {};
          description = "Automatic formatter detection configuration";
        };

        formatters = lib.mkOption {
          type = lib.types.submodule {
            options = {
              nix = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Nix formatters";
                    formatter = mkEnum ["alejandra" "nixfmt-rfc-style"] "nixfmt-rfc-style" "Nix code formatter to use";
                    linting = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          deadnix = lib.mkEnableOption "deadnix (dead code detection)" // {default = true;};
                          statix = lib.mkEnableOption "statix (linting and suggestions)" // {default = true;};
                        };
                      };
                      default = {};
                      description = "Nix linting tool configuration";
                    };
                  };
                };
                default = {};
                description = "Nix language formatting and linting";
              };

              web = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Web formatters (JS/TS/CSS)";
                    formatter = mkEnum ["biome" "prettier" "eslint"] "biome" "Web code formatter to use";
                    languages = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          javascript = lib.mkEnableOption "JavaScript formatting" // {default = true;};
                          typescript = lib.mkEnableOption "TypeScript formatting" // {default = true;};
                          css = lib.mkEnableOption "CSS formatting" // {default = true;};
                          scss = lib.mkEnableOption "SCSS formatting" // {default = true;};
                          json = lib.mkEnableOption "JSON formatting" // {default = true;};
                          html = lib.mkEnableOption "HTML formatting";
                        };
                      };
                      default = {};
                      description = "Web language-specific formatting options";
                    };
                  };
                };
                default = {};
                description = "Web development formatting";
              };

              python = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Python formatters";
                    formatters = lib.mkOption {
                      type = lib.types.attrsOf lib.types.bool;
                      default = {
                        black = true;
                        isort = true;
                        ruff = true;
                      };
                      description = "Enable/disable specific Python formatters";
                    };
                  };
                };
                default = {};
                description = "Python code formatting";
              };

              rust = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Rust formatters";
                    formatters = lib.mkOption {
                      type = lib.types.attrsOf lib.types.bool;
                      default = {rustfmt = true;};
                      description = "Enable/disable specific Rust formatters";
                    };
                  };
                };
                default = {};
                description = "Rust code formatting";
              };

              shell = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Shell formatters";
                    formatters = lib.mkOption {
                      type = lib.types.attrsOf lib.types.bool;
                      default = {
                        shfmt = true;
                        shellcheck = true;
                      };
                      description = "Enable/disable specific Shell formatters";
                    };
                  };
                };
                default = {};
                description = "Shell script formatting";
              };

              markdown = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Markdown formatters";
                    formatters = lib.mkOption {
                      type = lib.types.attrsOf lib.types.bool;
                      default = {mdformat = true;};
                      description = "Enable/disable specific Markdown formatters";
                    };
                  };
                };
                default = {};
                description = "Markdown document formatting";
              };

              yaml = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "YAML formatters";
                    formatters = lib.mkOption {
                      type = lib.types.attrsOf lib.types.bool;
                      default = {yamlfmt = true;};
                      description = "Enable/disable specific YAML formatters";
                    };
                  };
                };
                default = {};
                description = "YAML file formatting";
              };

              json = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "JSON formatters";
                    formatters = lib.mkOption {
                      type = lib.types.attrsOf lib.types.bool;
                      default = {
                        jsonfmt = true;
                        jq = true;
                      };
                      description = "Enable/disable specific JSON formatters";
                    };
                  };
                };
                default = {};
                description = "JSON file formatting";
              };

              misc = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Miscellaneous formatters";
                    tools = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          buf = lib.mkEnableOption "Protocol Buffer formatting" // {default = true;};
                          taplo = lib.mkEnableOption "TOML file formatting" // {default = true;};
                          just = lib.mkEnableOption "Justfile formatting" // {default = true;};
                          actionlint = lib.mkEnableOption "GitHub Actions workflow linting" // {default = true;};
                        };
                      };
                      default = {};
                      description = "Miscellaneous formatting tools";
                    };
                  };
                };
                default = {};
                description = "Miscellaneous formatting tools";
              };
            };
          };
          default = {};
          description = "Formatter configurations organized by domain";
        };

        behavior = lib.mkOption {
          type = lib.types.submodule {
            options = {
              performance = mkEnum ["fast" "balanced" "thorough"] "balanced" "Performance profile";
              allowMissingFormatter = lib.mkEnableOption "allow missing formatters without failing";
              enableDefaultExcludes = lib.mkEnableOption "default exclude patterns" // {default = true;};
            };
          };
          default = {};
          description = "Performance and behavior configuration";
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
              performance = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    parallel = lib.mkEnableOption "parallel processing" // {default = true;};
                    maxJobs = lib.mkOption {
                      type = lib.types.ints.positive;
                      default = 4;
                      description = "Maximum parallel formatting jobs";
                    };
                  };
                };
                default = {};
                description = "Incremental formatting performance settings";
              };
            };
          };
          default = {};
          description = "Incremental formatting configuration";
        };

        git = lib.mkOption {
          type = lib.types.submodule {
            options = {
              sinceCommit = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Format files changed since this commit";
              };
              stagedOnly = lib.mkEnableOption "format only staged files";
              branch = lib.mkOption {
                type = lib.types.str;
                default = "main";
                description = "Compare against this branch for change detection";
              };
              hooks = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    preCommit = lib.mkEnableOption "pre-commit hook";
                    prePush = lib.mkEnableOption "pre-push hook";
                  };
                };
                default = {};
                description = "Git hook configuration";
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

  # Legacy compatibility options (deprecated)
  options._legacyOptions = lib.mkOption {
    type = lib.types.submodule {
      options = {
        autoDetect = mkNullableBool null "DEPRECATED: Use treefmtFlake.autoDetection.enable";
        nix = mkNullableBool null "DEPRECATED: Use treefmtFlake.formatters.nix.enable";
        nixFormatter = mkNullableBool null "DEPRECATED: Use treefmtFlake.formatters.nix.formatter";
        web = mkNullableBool null "DEPRECATED: Use treefmtFlake.formatters.web.enable";
        python = mkNullableBool null "DEPRECATED: Use treefmtFlake.formatters.python.enable";
        rust = mkNullableBool null "DEPRECATED: Use treefmtFlake.formatters.rust.enable";
        shell = mkNullableBool null "DEPRECATED: Use treefmtFlake.formatters.shell.enable";
        yaml = mkNullableBool null "DEPRECATED: Use treefmtFlake.formatters.yaml.enable";
        markdown = mkNullableBool null "DEPRECATED: Use treefmtFlake.formatters.markdown.enable";
        json = mkNullableBool null "DEPRECATED: Use treefmtFlake.formatters.json.enable";
        misc = mkNullableBool null "DEPRECATED: Use treefmtFlake.formatters.misc.enable";
        performance = mkNullableBool null "DEPRECATED: Use treefmtFlake.behavior.performance";
        allowMissingFormatter = mkNullableBool null "DEPRECATED: Use treefmtFlake.behavior.allowMissingFormatter";
        enableDefaultExcludes = mkNullableBool null "DEPRECATED: Use treefmtFlake.behavior.enableDefaultExcludes";
        incremental = lib.mkOption {
          type = lib.types.nullOr lib.types.attrs;
          default = null;
          description = "DEPRECATED: Use treefmtFlake.incremental";
        };
        gitOptions = lib.mkOption {
          type = lib.types.nullOr lib.types.attrs;
          default = null;
          description = "DEPRECATED: Use treefmtFlake.git";
        };
      };
    };
    default = {};
    internal = true;
    description = "Legacy options for backward compatibility";
  };
}
