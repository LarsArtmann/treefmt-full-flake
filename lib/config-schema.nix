{lib}: let
  # Import centralized types module
  types = import ./types.nix {inherit lib;};

  # Import validation modules for migration functions
  configValidation = import ./config-validation.nix {inherit lib;};
  securityValidation = import ./security-validation.nix {inherit lib;};

  # Use types from centralized module
  inherit (types) betterEnum validatedString stringValidators secureTypes;

  # Enhanced type helpers
  mkEnableOptionWithDefault = default: description:
    lib.mkOption {
      type = lib.types.bool;
      inherit default description;
    };

  # Formatter-specific configuration schemas
  formatterTypes = {
    # Nix formatter configuration
    nixConfig = lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "Enable Nix formatters (alejandra, deadnix, statix)";

        formatter = lib.mkOption {
          type = types.types.nixFormatter;
          default = "nixfmt-rfc-style";
          description = "Nix code formatter selection. nixfmt-rfc-style is deterministic and recommended for consistent formatting across environments";
        };

        linting = lib.mkOption {
          type = lib.types.submodule {
            options = {
              deadnix = lib.mkEnableOption "Enable deadnix (dead code detection)";
              statix = lib.mkEnableOption "Enable statix (linting and suggestions)";
            };
          };
          default = {
            deadnix = true;
            statix = true;
          };
          description = "Nix linting tool configuration";
        };
      };
    };

    # Web development configuration
    webConfig = lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "Enable Web formatters (biome for JS/TS/CSS)";

        formatter = lib.mkOption {
          type = betterEnum [
            "biome"
            "prettier"
            "eslint"
          ] "Which web formatter to use. biome is fast and comprehensive, prettier is widely adopted" "biome";
          default = "biome";
          description = "Web code formatter selection";
        };

        languages = lib.mkOption {
          type = lib.types.submodule {
            options = {
              javascript = mkEnableOptionWithDefault true "Format JavaScript files";
              typescript = mkEnableOptionWithDefault true "Format TypeScript files";
              css = mkEnableOptionWithDefault true "Format CSS files";
              scss = mkEnableOptionWithDefault true "Format SCSS files";
              json = mkEnableOptionWithDefault true "Format JSON files";
              html = mkEnableOptionWithDefault false "Format HTML files";
            };
          };
          default = {};
          description = "Web language-specific formatting options";
        };
      };
    };

    # Generic language configuration template
    genericLanguageConfig = name: formatters:
      lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Enable ${name} formatters";

          formatters = lib.mkOption {
            type = lib.types.attrsOf lib.types.bool;
            default = lib.genAttrs formatters (_: true);
            description = "Enable/disable specific ${name} formatters";
          };
        };
      };
  };

  # Project configuration schema
  projectConfigSchema = lib.types.submodule {
    options = {
      # Root project settings
      projectRootFile = lib.mkOption {
        type = validatedString stringValidators.isFileName "projectRootFile must be a filename (not a path) that exists in your project root";
        default = "flake.nix";
        description = "File that marks the project root. Common choices: flake.nix, package.json, Cargo.toml, pyproject.toml";
        example = "package.json";
      };

      # Auto-detection settings
      autoDetection = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Automatically detect and enable formatters based on project files";
            };

            aggressive = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable aggressive auto-detection (may enable more formatters than needed)";
            };

            override = lib.mkOption {
              type = lib.types.enum [
                "user"
                "auto"
                "merge"
              ];
              default = "merge";
              description = "How to handle conflicts between auto-detection and user settings";
            };
          };
        };
        default = {};
        description = "Automatic formatter detection configuration";
      };

      # Formatter configurations grouped by domain
      formatters = lib.mkOption {
        type = lib.types.submodule {
          options = {
            # Core languages
            nix = lib.mkOption {
              type = formatterTypes.nixConfig;
              default = {};
              description = "Nix language formatting and linting";
            };

            web = lib.mkOption {
              type = formatterTypes.webConfig;
              default = {};
              description = "Web development (JS/TS/CSS) formatting";
            };

            # Other languages using generic template
            python = lib.mkOption {
              type = formatterTypes.genericLanguageConfig "Python" [
                "black"
                "isort"
                "ruff"
              ];
              default = {};
              description = "Python code formatting";
            };

            rust = lib.mkOption {
              type = formatterTypes.genericLanguageConfig "Rust" ["rustfmt"];
              default = {};
              description = "Rust code formatting";
            };

            shell = lib.mkOption {
              type = formatterTypes.genericLanguageConfig "Shell" [
                "shfmt"
                "shellcheck"
              ];
              default = {};
              description = "Shell script formatting and linting";
            };

            # Documentation and configuration
            markdown = lib.mkOption {
              type = formatterTypes.genericLanguageConfig "Markdown" ["mdformat"];
              default = {};
              description = "Markdown document formatting";
            };

            yaml = lib.mkOption {
              type = formatterTypes.genericLanguageConfig "YAML" ["yamlfmt"];
              default = {};
              description = "YAML file formatting";
            };

            json = lib.mkOption {
              type = formatterTypes.genericLanguageConfig "JSON" ["jsonfmt"];
              default = {};
              description = "JSON file formatting";
            };

            # Miscellaneous tools
            misc = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  enable = lib.mkEnableOption "Enable miscellaneous formatters";

                  tools = lib.mkOption {
                    type = lib.types.submodule {
                      options = {
                        buf = mkEnableOptionWithDefault true "Protocol Buffer formatting";
                        taplo = mkEnableOptionWithDefault true "TOML file formatting";
                        just = mkEnableOptionWithDefault true "Justfile formatting";
                        actionlint = mkEnableOptionWithDefault true "GitHub Actions workflow linting";
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

      # Performance and behavior settings
      behavior = lib.mkOption {
        type = lib.types.submodule {
          options = {
            performance = lib.mkOption {
              type = types.types.performanceProfile;
              default = "balanced";
              description = "Performance profile that balances speed vs thoroughness. 'fast' skips caching for speed, 'balanced' is recommended for most use cases, 'thorough' enables comprehensive checking but may be slower";
            };

            allowMissingFormatter = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Allow missing formatters without failing";
            };

            enableDefaultExcludes = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable default exclude patterns for common files/directories";
            };
          };
        };
        default = {};
        description = "Performance and behavior configuration";
      };

      # Incremental formatting settings
      incremental = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkEnableOption "Enable incremental formatting features";

            mode = lib.mkOption {
              type = types.types.incrementalMode;
              default = "auto";
              description = "Incremental mode: git (use git for change detection), cache (use treefmt cache), auto (detect best method)";
            };

            cache = lib.mkOption {
              type = secureTypes.securePath;
              default = "./.cache/treefmt";
              description = "Cache directory for treefmt (security validated)";
            };

            gitBased = lib.mkEnableOption "Use git for change detection";

            performance = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  parallel = mkEnableOptionWithDefault true "Enable parallel processing";
                  maxJobs = lib.mkOption {
                    type = lib.types.ints.positive;
                    default = 4;
                    description = "Maximum number of parallel formatting jobs";
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

      # Git integration settings
      git = lib.mkOption {
        type = lib.types.submodule {
          options = {
            sinceCommit = lib.mkOption {
              type = lib.types.nullOr secureTypes.secureShellArg;
              default = null;
              description = "Format files changed since this commit (security validated)";
            };

            stagedOnly = lib.mkEnableOption "Format only staged files";

            branch = lib.mkOption {
              type = secureTypes.secureShellArg;
              default = "main";
              description = "Compare against this branch for change detection (security validated)";
            };

            hooks = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  preCommit = mkEnableOptionWithDefault false "Install pre-commit hook";
                  prePush = mkEnableOptionWithDefault false "Install pre-push hook";
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

  # Validation functions for the unified schema
  validateUnifiedConfig = config: let
    # Use existing validation functions
    securityReport = securityValidation.validateSecurity {
      inherit (config) projectRootFile;
      incremental = {
        inherit (config.incremental) enable;
        inherit (config.incremental) cache;
      };
      gitOptions = {
        inherit (config.git) sinceCommit branch;
        inherit (config.git) stagedOnly;
      };
      inherit (config.behavior) allowMissingFormatter;
    };

    # Additional unified schema validation
    formattersEnabled = let
      fmt = config.formatters;
    in
      fmt.nix.enable
      || fmt.web.enable
      || fmt.python.enable
      || fmt.rust.enable
      || fmt.shell.enable
      || fmt.markdown.enable
      || fmt.yaml.enable
      || fmt.json.enable
      || fmt.misc.enable;

    logicalErrors = lib.optionals (!formattersEnabled) [
      "No formatters enabled. Enable at least one formatter or disable autoDetection to prevent this error."
    ];

    allErrors = securityReport.errors ++ logicalErrors;
    allWarnings = securityReport.warnings;
  in {
    isValid = allErrors == [];
    errors = allErrors;
    warnings = allWarnings;
    inherit (securityReport) recommendations;
  };

  # Migration helpers for backward compatibility
  migrateFromLegacyConfig = legacyConfig: {
    projectRootFile = legacyConfig.projectRootFile or "flake.nix";

    autoDetection = {
      enable = legacyConfig.autoDetect or true;
      aggressive = false;
      override = "merge";
    };

    formatters = {
      nix = {
        enable = legacyConfig.nix or false;
        formatter = legacyConfig.nixFormatter or "nixfmt-rfc-style";
        linting = {
          deadnix = true;
          statix = true;
        };
      };
      web.enable = legacyConfig.web or false;
      python.enable = legacyConfig.python or false;
      rust.enable = legacyConfig.rust or false;
      shell.enable = legacyConfig.shell or false;
      markdown.enable = legacyConfig.markdown or false;
      yaml.enable = legacyConfig.yaml or false;
      json.enable = legacyConfig.json or false;
      misc.enable = legacyConfig.misc or false;
    };

    behavior = {
      performance = legacyConfig.performance or "balanced";
      allowMissingFormatter = legacyConfig.allowMissingFormatter or false;
      enableDefaultExcludes = legacyConfig.enableDefaultExcludes or true;
    };

    incremental =
      (legacyConfig.incremental or {})
      // {
        cache = (legacyConfig.incremental or {}).cache or "./.cache/treefmt";
      };
    git = legacyConfig.gitOptions or {};
  };
in {
  inherit
    projectConfigSchema
    formatterTypes
    validateUnifiedConfig
    migrateFromLegacyConfig
    ;

  # Export type helpers
  types = {
    projectConfig = projectConfigSchema;
    inherit (formatterTypes) nixConfig;
    inherit (formatterTypes) webConfig;
    inherit (formatterTypes) genericLanguageConfig;
  };

  # Export validation
  validation = {
    validateConfig = validateUnifiedConfig;
    migrateConfig = migrateFromLegacyConfig;
  };
}
