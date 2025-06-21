{
  config,
  lib,
  ...
}: let
  # Import security validation
  securityValidation = import ./lib/security-validation.nix {inherit lib;};

  # Import config validation
  configValidation = import ./lib/config-validation.nix {inherit lib;};

  # Import unified config schema
  configSchema = import ./lib/config-schema.nix {inherit lib;};

  # Import performance tracking
  performanceTracking = import ./lib/performance-tracking.nix {inherit lib;};

  # Import project detection - inline for now due to flake evaluation context
  # TODO: Extract to separate module once import path issues are resolved
  projectDetection = {
    # Simplified auto-detection for initial implementation
    generateAutoConfig = projectPath: {
      # Enable commonly needed formatters by default
      nix = true; # Most Nix projects need this
      markdown = true; # Most projects have README.md
      yaml = true; # Common in CI/config files

      # Enable others based on simple heuristics
      # In a real implementation, we'd check for specific files
      # For now, provide sensible defaults
    };

    mergeWithUserConfig = autoDetected: userConfig:
    # User config overrides auto-detection
      autoDetected // userConfig;
  };

  # Use imported validation helpers
  inherit (configValidation) betterEnum;

  # Use proper filename validation
  validatedFileName =
    configValidation.validatedString
    configValidation.stringValidators.isFileName
    "projectRootFile must be a filename (not a path) that exists in your project root";

  # Runtime validation warnings with security checks
  generateRuntimeValidation = cfg: let
    securityReport = securityValidation.validateSecurity cfg;
  in ''
    # Security validation first
    ${lib.optionalString (!securityReport.isValid) ''
      echo "🔒 Security validation failed:"
      ${lib.concatMapStringsSep "\n" (error: "echo \"❌ ${error}\"") securityReport.errors}
      exit 1
    ''}

    # Security warnings and recommendations
    ${lib.optionalString (securityReport.warnings != []) ''
      ${lib.concatMapStringsSep "\n" (warning: "echo \"⚠️  ${warning}\"") securityReport.warnings}
    ''}

    ${lib.optionalString (securityReport.recommendations != []) ''
      ${lib.concatMapStringsSep "\n" (recommendation: "echo \"🔒 ${recommendation}\"") securityReport.recommendations}
    ''}

    # Secure file existence checks
    ${securityValidation.secureFileCheck cfg.projectRootFile "projectRootFile"}

    ${lib.optionalString cfg.nix ''
      if [[ ! -f "flake.nix" && ! -f "default.nix" && ! -f "shell.nix" ]]; then
        echo "💡 Info: Nix formatters enabled - will format *.nix files if found"
      fi
    ''}

    ${lib.optionalString cfg.rust ''
      if [[ ! -f "Cargo.toml" ]]; then
        echo "💡 Info: Rust formatters enabled - will format *.rs files if found"
      fi
    ''}
  '';
in {
  options = {
    treefmtFlake = lib.mkOption {
      type = lib.types.submodule {
        options = {
          # Auto-detection configuration
          autoDetect = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Automatically detect and enable formatters based on project files (package.json → web, Cargo.toml → rust, etc.)";
          };

          # Enable specific formatter groups
          nix = lib.mkEnableOption "Enable Nix formatters (alejandra, deadnix, statix)";
          web = lib.mkEnableOption "Enable Web formatters (biome for JS/TS/CSS)";

          # Nix formatter choice
          nixFormatter = lib.mkOption {
            type =
              betterEnum
              ["alejandra" "nixfmt-rfc-style"]
              "Which Nix formatter to use. nixfmt-rfc-style is deterministic and recommended for consistent formatting across environments"
              "nixfmt-rfc-style";
            default = "nixfmt-rfc-style";
            description = "Nix code formatter selection";
          };
          python = lib.mkEnableOption "Enable Python formatters (black, isort, ruff)";
          shell = lib.mkEnableOption "Enable Shell formatters (shfmt, shellcheck)";
          rust = lib.mkEnableOption "Enable Rust formatters (rustfmt)";
          yaml = lib.mkEnableOption "Enable YAML formatters (yamlfmt)";
          markdown = lib.mkEnableOption "Enable Markdown formatters (mdformat)";
          json = lib.mkEnableOption "Enable JSON formatters (jsonfmt, jq)";
          misc = lib.mkEnableOption "Enable miscellaneous formatters";

          # Configuration options
          projectRootFile = lib.mkOption {
            type = validatedFileName;
            default = "flake.nix";
            description = "File that marks the project root. Common choices: flake.nix, package.json, Cargo.toml, pyproject.toml";
            example = "package.json";
          };

          enableDefaultExcludes = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable default excludes for common patterns";
          };

          allowMissingFormatter = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Allow missing formatters";
          };

          # Incremental formatting options
          incremental = lib.mkOption {
            type = lib.types.submodule {
              options = {
                enable = lib.mkEnableOption "Enable incremental formatting features";

                mode = lib.mkOption {
                  type = lib.types.enum ["git" "cache" "auto"];
                  default = "auto";
                  description = "Incremental mode: git (use git for change detection), cache (use treefmt cache), auto (detect best method)";
                };

                cache = lib.mkOption {
                  type = lib.types.str;
                  default = "~/.cache/treefmt";
                  description = "Cache directory for treefmt";
                };

                gitBased = lib.mkEnableOption "Use git for change detection";
              };
            };
            default = {};
            description = "Incremental formatting configuration";
          };

          # Performance profiles
          performance = lib.mkOption {
            type =
              betterEnum
              ["fast" "balanced" "thorough"]
              "Performance profile that balances speed vs thoroughness. 'fast' skips caching for speed, 'balanced' is recommended for most use cases, 'thorough' enables comprehensive checking but may be slower"
              "balanced";
            default = "balanced";
            description = "Performance vs thoroughness trade-off";
          };

          # Git-specific options
          gitOptions = lib.mkOption {
            type = lib.types.submodule {
              options = {
                sinceCommit = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Format files changed since this commit";
                };

                stagedOnly = lib.mkEnableOption "Format only staged files";

                branch = lib.mkOption {
                  type = lib.types.str;
                  default = "main";
                  description = "Compare against this branch for change detection";
                };
              };
            };
            default = {};
            description = "Git-based formatting options";
          };
        };
      };
      default = {};
      description = "Configuration for treefmt-flake";
    };
  };

  config = let
    cfg = config.treefmtFlake;

    # Auto-detect project types and merge with user configuration
    autoDetectedConfig =
      if cfg.autoDetect
      then projectDetection.generateAutoConfig ./.
      else {};

    # Merge auto-detected settings with user-specified settings
    # User settings take precedence over auto-detection
    finalFormatterConfig = projectDetection.mergeWithUserConfig autoDetectedConfig {
      inherit (cfg) nix web python shell rust yaml markdown json misc;
    };

    # Import formatter modules conditionally based on final enabled options
    formatterConfigs = lib.mkMerge (lib.optional (finalFormatterConfig.nix or false) (
        if cfg.nixFormatter == "nixfmt-rfc-style"
        then import ./formatters/nix-nixfmt.nix
        else import ./formatters/nix.nix
      )
      ++ lib.optional (finalFormatterConfig.web or false) (import ./formatters/web.nix)
      ++ lib.optional (finalFormatterConfig.python or false) (import ./formatters/python.nix)
      ++ lib.optional (finalFormatterConfig.shell or false) (import ./formatters/shell.nix)
      ++ lib.optional (finalFormatterConfig.rust or false) (import ./formatters/rust.nix)
      ++ lib.optional (finalFormatterConfig.yaml or false) (import ./formatters/yaml.nix)
      ++ lib.optional (finalFormatterConfig.markdown or false) (import ./formatters/markdown.nix)
      ++ lib.optional (finalFormatterConfig.json or false) (import ./formatters/json.nix)
      ++ lib.optional (finalFormatterConfig.misc or false) (import ./formatters/misc.nix));

    # Generate treefmt CLI arguments based on configuration
    generateTreefmtArgs = pkgs: let
      baseArgs = [];

      # Performance profile flags
      performanceArgs =
        {
          fast = ["--no-cache"];
          balanced = [];
          thorough = ["--walk"];
        }.${
          cfg.performance
        };

      # Incremental flags
      incrementalArgs = lib.optionals cfg.incremental.enable (
        if cfg.incremental.mode == "cache" || (cfg.incremental.mode == "auto" && !cfg.incremental.gitBased)
        then []
        else if cfg.incremental.mode == "git" || cfg.incremental.gitBased
        then ["--walk"] # Use --walk for git mode to process specific files
        else []
      );

      # Cache directory configuration
      cacheArgs = lib.optionals (cfg.incremental.enable && cfg.incremental.cache != "~/.cache/treefmt") [
        "--cache-dir=${cfg.incremental.cache}"
      ];
    in
      baseArgs ++ performanceArgs ++ incrementalArgs ++ cacheArgs;

    # Create git-aware wrapper script for incremental formatting
    createIncrementalWrapper = pkgs: baseWrapper:
      pkgs.writeShellScriptBin "treefmt-incremental" (securityValidation.createSecureWrapper ''
        # Runtime configuration validation
        ${generateRuntimeValidation cfg}

        # Default treefmt wrapper
        TREEFMT_CMD="${baseWrapper}/bin/treefmt"
        CACHE_DIR="${cfg.incremental.cache}"

        STAGED_ONLY="${
          if cfg.gitOptions.stagedOnly
          then "1"
          else ""
        }"
        SINCE_COMMIT="${
          if cfg.gitOptions.sinceCommit != null
          then cfg.gitOptions.sinceCommit
          else ""
        }"

        # Ensure cache directory exists
        mkdir -p "$CACHE_DIR"

        # Function to get changed files based on git
        get_changed_files() {
          if [[ -n "$STAGED_ONLY" ]]; then
            # Only staged files
            git diff --cached --name-only --diff-filter=ACMR
          ${lib.optionalString (cfg.gitOptions.sinceCommit != null) ''
          elif [[ -n "$SINCE_COMMIT" ]]; then
            # Files changed since specific commit
            git diff --name-only --diff-filter=ACMR "$SINCE_COMMIT"
        ''}
          else
            # Files changed compared to main branch
            git diff --name-only --diff-filter=ACMR "origin/${cfg.gitOptions.branch}...HEAD" 2>/dev/null || \
            git diff --name-only --diff-filter=ACMR "${cfg.gitOptions.branch}...HEAD" 2>/dev/null || \
            git diff --name-only --diff-filter=ACMR HEAD~1
          fi
        }

        # Function to run treefmt with comprehensive performance tracking
        run_treefmt() {
          # Import performance tracking functions
          ${performanceTracking.shellHelpers.exportAll}

          # Initialize performance tracking
          local start_time=$(date +%s.%N)
          local file_count=0

          # Set performance environment variables
          export PERFORMANCE_PROFILE="${cfg.behavior.performance or cfg.performance}"
          export CACHE_DIR="${cfg.incremental.cache}"
          export INCREMENTAL_MODE="${
          if cfg.incremental.enable
          then
            if cfg.incremental.gitBased
            then "git"
            else cfg.incremental.mode
          else "full"
        }"
          export CACHE_ENABLED="${
          if cfg.incremental.enable
          then "enabled"
          else "disabled"
        }"
          export PARALLEL_ENABLED="${
          if cfg.incremental.performance.parallel or false
          then "enabled"
          else "disabled"
        }"

          INCREMENTAL_ENABLE="${
          if cfg.incremental.enable
          then "1"
          else ""
        }"
          INCREMENTAL_MODE="${cfg.incremental.mode}"
          GIT_BASED="${
          if cfg.incremental.gitBased
          then "1"
          else ""
        }"

          if [[ -n "$INCREMENTAL_ENABLE" && ( "$INCREMENTAL_MODE" == "git" || -n "$GIT_BASED" ) ]]; then
            # Get list of changed files
            local changed_files
            if ! changed_files=$(get_changed_files); then
              echo "Warning: Could not determine changed files, falling back to full formatting"
              "$TREEFMT_CMD" "$@"
              return $?
            fi

            if [[ -z "$changed_files" ]]; then
              echo "No changed files detected, skipping formatting"
              return 0
            fi

            # Convert to array and filter existing files
            local files_array=()
            while IFS= read -r file; do
              if [[ -f "$file" ]]; then
                files_array+=("$file")
                ((file_count++))
              fi
            done <<< "$changed_files"

            if [[ $file_count -eq 0 ]]; then
              echo "No files to format"
              return 0
            fi

            echo "Formatting $file_count changed files..."
            if [[ $file_count -le 10 ]]; then
              printf "Files: %s\n" "''${files_array[*]}"
            fi

            # Run treefmt on specific files
            "$TREEFMT_CMD" ${lib.concatStringsSep " " (generateTreefmtArgs pkgs)} "$@" -- "''${files_array[@]}"
          else
            # Standard treefmt execution
            echo "Running full formatting..."
            "$TREEFMT_CMD" ${lib.concatStringsSep " " (generateTreefmtArgs pkgs)} "$@"
          fi

          local end_time=$(date +%s.%N)
          local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")

          # Generate comprehensive performance report
          if [[ "''${TREEFMT_VERBOSE:-}" == "1" || "$file_count" -gt 20 ]]; then
            # Full detailed report for verbose mode or large file counts
            generate_performance_report "$start_time" "$end_time" "$file_count" "''${files_array[@]}"
          else
            # Quick summary for normal operations
            generate_quick_report "$duration" "$file_count" "''${PERFORMANCE_PROFILE}"
          fi
        }

        # Main execution
        run_treefmt "$@"
      '');
  in {
    perSystem = {
      config,
      pkgs,
      ...
    }: {
      treefmt = {
        inherit (cfg) projectRootFile;

        # Enable default excludes if requested
        inherit (cfg) enableDefaultExcludes;

        # Allow missing formatters if requested
        settings =
          {
            allowMissingTools = cfg.allowMissingFormatter;
          }
          // lib.optionalAttrs (cfg.incremental.enable && cfg.incremental.cache != "~/.cache/treefmt") {
            # Configure cache directory if specified
            cache-dir = cfg.incremental.cache;
          };

        # Apply formatter configurations
        programs = formatterConfigs;
      };

      # Create enhanced formatter with incremental capabilities
      formatter =
        if cfg.incremental.enable
        then createIncrementalWrapper pkgs config.treefmt.build.wrapper
        else config.treefmt.build.wrapper;

      # Add development packages and scripts
      packages = lib.optionalAttrs cfg.incremental.enable {
        treefmt-fast = pkgs.writeShellScriptBin "treefmt-fast" ''
          ${
            if cfg.incremental.enable
            then "${createIncrementalWrapper pkgs config.treefmt.build.wrapper}/bin/treefmt-incremental"
            else "${config.treefmt.build.wrapper}/bin/treefmt"
          } --no-cache "$@"
        '';

        treefmt-staged = pkgs.writeShellScriptBin "treefmt-staged" ''
          export TREEFMT_STAGED_ONLY=true
          ${
            if cfg.incremental.enable
            then "${createIncrementalWrapper pkgs config.treefmt.build.wrapper}/bin/treefmt-incremental"
            else "${config.treefmt.build.wrapper}/bin/treefmt"
          } "$@"
        '';

        treefmt-since = pkgs.writeShellScriptBin "treefmt-since" ''
          if [[ $# -eq 0 ]]; then
            echo "Usage: treefmt-since <commit>"
            exit 1
          fi
          export TREEFMT_SINCE_COMMIT="$1"
          shift
          ${
            if cfg.incremental.enable
            then "${createIncrementalWrapper pkgs config.treefmt.build.wrapper}/bin/treefmt-incremental"
            else "${config.treefmt.build.wrapper}/bin/treefmt"
          } "$@"
        '';
      };
    };
  };
}
