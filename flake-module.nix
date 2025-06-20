{
  config,
  lib,
  ...
}: {
  options = {
    treefmtFlake = lib.mkOption {
      type = lib.types.submodule {
        options = {
          # Enable specific formatter groups
          nix = lib.mkEnableOption "Enable Nix formatters (alejandra, deadnix, statix)";
          web = lib.mkEnableOption "Enable Web formatters (biome for JS/TS/CSS)";

          # Nix formatter choice
          nixFormatter = lib.mkOption {
            type = lib.types.enum ["alejandra" "nixfmt-rfc-style"];
            default = "alejandra";
            description = "Which Nix formatter to use. Note: alejandra has known non-determinism issues.";
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
            type = lib.types.str;
            default = "flake.nix";
            description = "File that marks the project root";
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
            type = lib.types.enum ["fast" "balanced" "thorough"];
            default = "balanced";
            description = "Performance profile: fast (skip expensive operations), balanced (default), thorough (comprehensive checking)";
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

    # Import formatter modules conditionally based on enabled options
    formatterConfigs = lib.mkMerge (lib.optional cfg.nix (
        if cfg.nixFormatter == "nixfmt-rfc-style"
        then import ./formatters/nix-nixfmt.nix
        else import ./formatters/nix.nix
      )
      ++ lib.optional cfg.web (import ./formatters/web.nix)
      ++ lib.optional cfg.python (import ./formatters/python.nix)
      ++ lib.optional cfg.shell (import ./formatters/shell.nix)
      ++ lib.optional cfg.rust (import ./formatters/rust.nix)
      ++ lib.optional cfg.yaml (import ./formatters/yaml.nix)
      ++ lib.optional cfg.markdown (import ./formatters/markdown.nix)
      ++ lib.optional cfg.json (import ./formatters/json.nix)
      ++ lib.optional cfg.misc (import ./formatters/misc.nix));

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
      pkgs.writeShellScriptBin "treefmt-incremental" ''
        #!/usr/bin/env bash
        set -euo pipefail

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

        # Function to run treefmt with performance profiling
        run_treefmt() {
          local start_time=$(date +%s.%N)
          local file_count=0

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

          echo "Formatting completed in ''${duration}s (''${file_count} files, ${cfg.performance} profile)"
        }

        # Main execution
        run_treefmt "$@"
      '';
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
