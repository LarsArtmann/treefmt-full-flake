{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Import centralized library system
  treefmtLib = import ./lib { inherit lib; };

  # Use imported validation helpers
  inherit (treefmtLib) betterEnum;

  # Use proper filename validation
  validatedFileName = treefmtLib.configValidation.validatedString treefmtLib.configValidation.stringValidators.isFileName "projectRootFile must be a filename (not a path) that exists in your project root";

  # Runtime validation warnings with security checks
  generateRuntimeValidation =
    cfg: deprecationWarnings:
    let
      securityReport = treefmtLib.securityValidation.validateSecurity cfg;
    in
    ''
      # Security validation first
      ${lib.optionalString (!securityReport.isValid) ''
        echo "🔒 Security validation failed:"
        ${lib.concatMapStringsSep "\n" (error: "echo \"❌ ${error}\"") securityReport.errors}
        exit 1
      ''}

      # Deprecation warnings for legacy configuration
      ${lib.optionalString (deprecationWarnings != [ ]) ''
        ${lib.concatMapStringsSep "\n" (warning: "echo \"⚠️  ${warning}\"") deprecationWarnings}
        echo ""
      ''}

      # Security warnings and recommendations
      ${lib.optionalString (securityReport.warnings != [ ]) ''
        ${lib.concatMapStringsSep "\n" (warning: "echo \"⚠️  ${warning}\"") securityReport.warnings}
      ''}

      ${lib.optionalString (securityReport.recommendations != [ ]) ''
        ${lib.concatMapStringsSep "\n" (
          recommendation: "echo \"🔒 ${recommendation}\""
        ) securityReport.recommendations}
      ''}

      # Secure file existence checks
      ${treefmtLib.securityValidation.secureFileCheck cfg.projectRootFile "projectRootFile"}

      ${lib.optionalString cfg.formatters.nix.enable ''
        if [[ ! -f "flake.nix" && ! -f "default.nix" && ! -f "shell.nix" ]]; then
          echo "💡 Info: Nix formatters enabled - will format *.nix files if found"
        fi
      ''}

      ${lib.optionalString cfg.formatters.rust.enable ''
        if [[ ! -f "Cargo.toml" ]]; then
          echo "💡 Info: Rust formatters enabled - will format *.rs files if found"
        fi
      ''}
    '';
in
{
  options = {
    treefmtFlake = lib.mkOption {
      type = treefmtLib.configSchema.types.projectConfig;
      default = { };
      description = "Configuration for treefmt-flake using unified schema";
    };

    # Legacy compatibility layer - automatically migrates old configuration format
    # Deprecated: Use the unified schema in treefmtFlake instead
    # These options are automatically migrated and will be removed in v3.0
    _legacyOptions = lib.mkOption {
      type = lib.types.submodule {
        options = {
          # Old scattered options for backward compatibility
          autoDetect = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.autoDetection.enable instead";
          };
          
          nix = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.formatters.nix.enable instead";
          };
          
          nixFormatter = lib.mkOption {
            type = lib.types.nullOr (treefmtLib.betterEnum [ "alejandra" "nixfmt-rfc-style" ] "" "nixfmt-rfc-style");
            default = null;
            description = "DEPRECATED: Use treefmtFlake.formatters.nix.formatter instead";
          };
          
          web = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.formatters.web.enable instead";
          };
          
          python = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.formatters.python.enable instead";
          };
          
          rust = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.formatters.rust.enable instead";
          };
          
          shell = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.formatters.shell.enable instead";
          };
          
          yaml = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.formatters.yaml.enable instead";
          };
          
          markdown = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.formatters.markdown.enable instead";
          };
          
          json = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.formatters.json.enable instead";
          };
          
          misc = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.formatters.misc.enable instead";
          };
          
          performance = lib.mkOption {
            type = lib.types.nullOr (treefmtLib.betterEnum [ "fast" "balanced" "thorough" ] "" "balanced");
            default = null;
            description = "DEPRECATED: Use treefmtFlake.behavior.performance instead";
          };
          
          allowMissingFormatter = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.behavior.allowMissingFormatter instead";
          };
          
          enableDefaultExcludes = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.behavior.enableDefaultExcludes instead";
          };
          
          incremental = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.incremental instead";
          };
          
          gitOptions = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "DEPRECATED: Use treefmtFlake.git instead";
          };
        };
      };
      default = { };
      internal = true;
      description = "Legacy options for backward compatibility - automatically migrated";
    };
  };

  config =
    let
      legacyCfg = config._legacyOptions;
      
      # Detect if legacy options are being used
      hasLegacyOptions = lib.any (name: legacyCfg.${name} != null) (lib.attrNames legacyCfg);
      
      # Filter out null values from legacy config
      cleanLegacyConfig = lib.filterAttrs (name: value: value != null) legacyCfg;
      
      # Migrate legacy configuration to unified schema if needed
      migratedConfig = if hasLegacyOptions then
        treefmtLib.migrateConfig cleanLegacyConfig
      else
        { };
      
      # Merge user's unified config with migrated legacy config
      # User's unified config takes precedence over migrated legacy config
      finalConfig = lib.recursiveUpdate migratedConfig config.treefmtFlake;
      
      cfg = finalConfig;

      # Generate deprecation warnings for legacy options
      deprecationWarnings = lib.optionals hasLegacyOptions [
        ''
          WARNING: You are using deprecated treefmt-flake configuration options.
          Please migrate to the new unified schema. Legacy options will be removed in v3.0.
          
          Migration guide:
          ${lib.concatMapStringsSep "\n" (name: 
            let value = legacyCfg.${name}; in
            if value != null then
              "  ${name} = ${lib.generators.toPretty {} value}; → treefmtFlake.${
                {
                  autoDetect = "autoDetection.enable";
                  nix = "formatters.nix.enable";
                  nixFormatter = "formatters.nix.formatter";
                  web = "formatters.web.enable";
                  python = "formatters.python.enable";
                  rust = "formatters.rust.enable";
                  shell = "formatters.shell.enable";
                  yaml = "formatters.yaml.enable";
                  markdown = "formatters.markdown.enable";
                  json = "formatters.json.enable";
                  misc = "formatters.misc.enable";
                  performance = "behavior.performance";
                  allowMissingFormatter = "behavior.allowMissingFormatter";
                  enableDefaultExcludes = "behavior.enableDefaultExcludes";
                  incremental = "incremental";
                  gitOptions = "git";
                }.${name} or name
              } = ${lib.generators.toPretty {} value};"
            else
              ""
          ) (lib.attrNames legacyCfg)}
          
          For more details, see: https://github.com/LarsArtmann/treefmt-full-flake/blob/main/MIGRATION.md
        ''
      ];

      # Validate the final unified configuration
      validationResult = treefmtLib.validateConfig cfg;

      # Auto-detect project types and merge with user configuration
      autoDetectedConfig = if cfg.autoDetection.enable then treefmtLib.projectDetection.generateAutoConfig ./. else { };

      # Extract formatter enable states from the unified schema
      formatterStates = {
        nix = cfg.formatters.nix.enable;
        web = cfg.formatters.web.enable;
        python = cfg.formatters.python.enable;
        shell = cfg.formatters.shell.enable;
        rust = cfg.formatters.rust.enable;
        yaml = cfg.formatters.yaml.enable;
        markdown = cfg.formatters.markdown.enable;
        json = cfg.formatters.json.enable;
        misc = cfg.formatters.misc.enable;
      };

      # Merge auto-detected settings with user-specified settings
      # User settings take precedence over auto-detection
      finalFormatterConfig = treefmtLib.projectDetection.mergeWithUserConfig autoDetectedConfig formatterStates;

      # Load formatter modules - temporarily using direct imports during transition
      formatterConfigs = lib.mkMerge (
        lib.optional (finalFormatterConfig.nix or false) (
          if cfg.formatters.nix.formatter == "nixfmt-rfc-style" then
            import ./formatters/nix-nixfmt.nix
          else
            import ./formatters/nix.nix
        )
        ++ lib.optional (finalFormatterConfig.web or false) (import ./formatters/web.nix)
        ++ lib.optional (finalFormatterConfig.python or false) (import ./formatters/python.nix)
        ++ lib.optional (finalFormatterConfig.shell or false) (import ./formatters/shell.nix)
        ++ lib.optional (finalFormatterConfig.rust or false) (import ./formatters/rust.nix)
        ++ lib.optional (finalFormatterConfig.yaml or false) (import ./formatters/yaml.nix)
        ++ lib.optional (finalFormatterConfig.markdown or false) (import ./formatters/markdown.nix)
        ++ lib.optional (finalFormatterConfig.json or false) (import ./formatters/json.nix)
        ++ lib.optional (finalFormatterConfig.misc or false) (import ./formatters/misc.nix)
      );

      # Generate treefmt CLI arguments based on configuration
      generateTreefmtArgs =
        _pkgs:
        let
          baseArgs = [ ];

          # Performance profile flags
          performanceArgs =
            {
              fast = [ "--no-cache" ];
              balanced = [ ];
              thorough = [ "--walk" ];
            }
            .${cfg.behavior.performance};

          # Incremental flags
          incrementalArgs = lib.optionals cfg.incremental.enable (
            if
              cfg.incremental.mode == "cache" || (cfg.incremental.mode == "auto" && !cfg.incremental.gitBased)
            then
              [ ]
            else if cfg.incremental.mode == "git" || cfg.incremental.gitBased then
              [ "--walk" ] # Use --walk for git mode to process specific files
            else
              [ ]
          );

          # Cache directory configuration
          cacheArgs = lib.optionals (cfg.incremental.enable && cfg.incremental.cache != "./.cache/treefmt") [
            "--cache-dir=${cfg.incremental.cache}"
          ];
        in
        baseArgs ++ performanceArgs ++ incrementalArgs ++ cacheArgs;

      # Create git-aware wrapper script for incremental formatting
      createIncrementalWrapper =
        pkgs: baseWrapper:
        pkgs.writeShellScriptBin "treefmt-incremental" (
          treefmtLib.securityValidation.createSecureWrapper ''
            # Runtime configuration validation
            ${generateRuntimeValidation cfg deprecationWarnings}

            # Default treefmt wrapper
            TREEFMT_CMD="${baseWrapper}/bin/treefmt"
            CACHE_DIR="${cfg.incremental.cache}"

            STAGED_ONLY="${if cfg.git.stagedOnly then "1" else ""}"
            SINCE_COMMIT="${if cfg.git.sinceCommit != null then cfg.git.sinceCommit else ""}"

            # Ensure cache directory exists
            mkdir -p "$CACHE_DIR"

            # Function to get changed files based on git
            get_changed_files() {
              if [[ -n "$STAGED_ONLY" ]]; then
                # Only staged files
                git diff --cached --name-only --diff-filter=ACMR
              ${lib.optionalString (cfg.git.sinceCommit != null) ''
                elif [[ -n "$SINCE_COMMIT" ]]; then
                  # Files changed since specific commit
                  git diff --name-only --diff-filter=ACMR "$SINCE_COMMIT"
              ''}
              else
                # Files changed compared to main branch
                git diff --name-only --diff-filter=ACMR "origin/${cfg.git.branch}...HEAD" 2>/dev/null || \
                git diff --name-only --diff-filter=ACMR "${cfg.git.branch}...HEAD" 2>/dev/null || \
                git diff --name-only --diff-filter=ACMR HEAD~1
              fi
            }

            # Function to run treefmt with comprehensive performance tracking
            run_treefmt() {
              # Import performance tracking functions
              ${treefmtLib.performanceTracking.shellHelpers.exportAll}

              # Initialize performance tracking
              local start_time=$(date +%s.%N)
              local file_count=0
              local files_array=()  # Initialize files_array for all code paths

              # Set performance environment variables
              export PERFORMANCE_PROFILE="${cfg.behavior.performance}"
              export CACHE_DIR="${cfg.incremental.cache}"
              export INCREMENTAL_MODE="${
                if cfg.incremental.enable then
                  if cfg.incremental.gitBased then "git" else cfg.incremental.mode
                else
                  "full"
              }"
              export CACHE_ENABLED="${if cfg.incremental.enable then "enabled" else "disabled"}"
              export PARALLEL_ENABLED="${
                if cfg.incremental.performance.parallel or false then "enabled" else "disabled"
              }"

              INCREMENTAL_ENABLE="${if cfg.incremental.enable then "1" else ""}"
              INCREMENTAL_MODE="${cfg.incremental.mode}"
              GIT_BASED="${if cfg.incremental.gitBased then "1" else ""}"

              if [[ -n "$INCREMENTAL_ENABLE" && ( "$INCREMENTAL_MODE" == "git" || -n "$GIT_BASED" ) ]]; then
                # Get list of changed files
                local changed_files
                if ! changed_files=$(get_changed_files); then
                  echo "Warning: Could not determine changed files, falling back to full formatting"
                  # For fallback case, estimate file count from current directory
                  file_count=$(find . -type f \( -name "*.nix" -o -name "*.js" -o -name "*.ts" -o -name "*.css" -o -name "*.md" -o -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | wc -l || echo "0")
                  "$TREEFMT_CMD" "$@"
                  local exit_code=$?
                  local end_time=$(date +%s.%N)
                  local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
                  generate_quick_report "$duration" "$file_count" "''${PERFORMANCE_PROFILE}"
                  return $exit_code
                fi

                if [[ -z "$changed_files" ]]; then
                  echo "No changed files detected, skipping formatting"
                  return 0
                fi

                # Convert to array and filter existing files
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
                # Standard treefmt execution - estimate file count for performance tracking
                echo "Running full formatting..."
                file_count=$(find . -type f \( -name "*.nix" -o -name "*.js" -o -name "*.ts" -o -name "*.css" -o -name "*.md" -o -name "*.yml" -o -name "*.yaml" -o -name "*.py" -o -name "*.rs" -o -name "*.sh" -o -name "*.json" -o -name "*.toml" \) 2>/dev/null | wc -l || echo "0")
                "$TREEFMT_CMD" ${lib.concatStringsSep " " (generateTreefmtArgs pkgs)} "$@"
              fi

              local end_time=$(date +%s.%N)
              local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")

              # Generate comprehensive performance report
              if [[ "''${TREEFMT_VERBOSE:-}" == "1" || "$file_count" -gt 20 ]]; then
                # Full detailed report for verbose mode or large file counts
                # Only pass files_array if it's actually populated (incremental mode)
                if [[ ''${#files_array[@]} -gt 0 ]]; then
                  generate_performance_report "$start_time" "$end_time" "$file_count" "''${files_array[@]}"
                else
                  generate_performance_report "$start_time" "$end_time" "$file_count"
                fi
              else
                # Quick summary for normal operations
                generate_quick_report "$duration" "$file_count" "''${PERFORMANCE_PROFILE}"
              fi
            }

            # Main execution
            run_treefmt "$@"
          ''
        );
    in
    {
      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {
          treefmt = {
            inherit (cfg) projectRootFile;

            # Enable default excludes if requested
            enableDefaultExcludes = cfg.behavior.enableDefaultExcludes;

            # Allow missing formatters if requested
            settings =
              {
                allowMissingTools = cfg.behavior.allowMissingFormatter;
              }
              // lib.optionalAttrs (cfg.incremental.enable && cfg.incremental.cache != "./.cache/treefmt") {
                # Configure cache directory if specified
                cache-dir = cfg.incremental.cache;
              }
              // {
                # Add custom formatters that aren't built into treefmt-nix
                formatter = lib.optionalAttrs (finalFormatterConfig.misc or false) {
                  typespec = {
                    command = "${pkgs.typespec}/bin/tsp"; # Use flake-provided TypeSpec
                    options = [ "format" ];
                    includes = [ "*.tsp" ];
                  };
                };
              };

            # Apply formatter configurations
            programs = formatterConfigs;
          };

          # Create enhanced formatter with incremental capabilities
          formatter =
            if cfg.incremental.enable then
              createIncrementalWrapper pkgs config.treefmt.build.wrapper
            else
              config.treefmt.build.wrapper;

          # Add development packages and CLI tools
          packages = {
            # Debug tool - always available
            treefmt-debug = pkgs.writeShellScriptBin "treefmt-debug" ''
              echo "🔧 treefmt-flake Debug Information"
              echo "=================================="
              echo ""
              
              # Configuration summary
              echo "📋 Configuration Summary:"
              echo "  Project Root: ${cfg.projectRootFile}"
              echo "  Auto-Detection: ${if cfg.autoDetection.enable then "enabled" else "disabled"}"
              echo "  Performance Profile: ${cfg.behavior.performance}"
              echo "  Incremental Mode: ${if cfg.incremental.enable then "enabled (${cfg.incremental.mode})" else "disabled"}"
              echo "  Cache Directory: ''${CACHE_DIR:-${cfg.incremental.cache}}"
              echo ""
              
              # Enabled formatters
              echo "🎯 Enabled Formatters:"
              ${lib.concatMapStringsSep "\n" (name: 
                let enabled = finalFormatterConfig.${name} or false; in
                "echo \"  ${name}: ${if enabled then "✅ enabled" else "❌ disabled"}\""
              ) ["nix" "web" "python" "shell" "rust" "yaml" "markdown" "json" "misc"]}
              echo ""
              
              # Formatter details
              echo "⚙️  Formatter Details:"
              ${lib.optionalString (finalFormatterConfig.nix or false) ''
                echo "  • Nix: ${cfg.formatters.nix.formatter} (deadnix: ${if cfg.formatters.nix.linting.deadnix then "✅" else "❌"}, statix: ${if cfg.formatters.nix.linting.statix then "✅" else "❌"})"
              ''}
              ${lib.optionalString (finalFormatterConfig.web or false) ''
                echo "  • Web: ${cfg.formatters.web.formatter} (JS: ${if cfg.formatters.web.languages.javascript then "✅" else "❌"}, TS: ${if cfg.formatters.web.languages.typescript then "✅" else "❌"}, CSS: ${if cfg.formatters.web.languages.css then "✅" else "❌"})"
              ''}
              echo ""
              
              # Project analysis
              echo "📂 Project Analysis:"
              if [[ -f "${cfg.projectRootFile}" ]]; then
                echo "  Project root file: ✅ found"
              else
                echo "  Project root file: ❌ not found"
              fi
              
              if [[ -d ".git" ]]; then
                echo "  Git repository: ✅ detected"
                if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
                  echo "  Git status: 📝 dirty ($(git status --porcelain 2>/dev/null | wc -l) changes)"
                else
                  echo "  Git status: ✅ clean"
                fi
              else
                echo "  Git repository: ❌ not detected"
              fi
              echo ""
              
              # File counts by type
              echo "📊 File Statistics:"
              for ext in nix js ts py rs sh yml yaml md json toml; do
                count=$(find . -name "*.$ext" -type f 2>/dev/null | wc -l)
                if [[ $count -gt 0 ]]; then
                  echo "  *.$ext files: $count"
                fi
              done
              echo ""
              
              # Validation
              echo "✅ Configuration Validation:"
              if ${if validationResult.isValid then "true" else "false"}; then
                echo "  Status: ✅ Valid configuration"
              else
                echo "  Status: ❌ Configuration errors detected"
                ${lib.concatMapStringsSep "\n" (error: "echo \"    - ${error}\"") (validationResult.errors or [])}
              fi
              
              ${lib.optionalString (validationResult.warnings != []) ''
                echo "  Warnings:"
                ${lib.concatMapStringsSep "\n" (warning: "echo \"    ⚠️  ${warning}\"") validationResult.warnings}
              ''}
              echo ""
              
              # Migration status
              ${lib.optionalString hasLegacyOptions ''
                echo "🚨 Legacy Configuration Detected:"
                echo "  You are using deprecated configuration options."
                echo "  Run 'nix run .#treefmt-validate' for migration guidance."
                echo ""
              ''}
              
              echo "💡 Available Commands:"
              echo "  nix fmt                    - Format all files"
              echo "  nix fmt -- --check        - Check formatting without changes"
              echo "  nix run .#treefmt-debug   - Show this debug information"
              echo "  nix run .#treefmt-validate - Validate configuration"
              ${lib.optionalString cfg.incremental.enable ''
                echo "  nix run .#treefmt-fast    - Fast formatting (no cache)"
                echo "  nix run .#treefmt-staged  - Format only staged files"
                echo "  nix run .#treefmt-since   - Format files since commit"
              ''}
            '';

            # Validation tool - always available
            treefmt-validate = pkgs.writeShellScriptBin "treefmt-validate" ''
              echo "🔍 treefmt-flake Configuration Validation"
              echo "========================================="
              echo ""
              
              # Run all validation checks
              ${generateRuntimeValidation cfg deprecationWarnings}
              
              # Configuration validation
              echo "📋 Schema Validation:"
              if ${if validationResult.isValid then "true" else "false"}; then
                echo "  ✅ Configuration schema is valid"
              else
                echo "  ❌ Configuration schema has errors:"
                ${lib.concatMapStringsSep "\n" (error: "echo \"     - ${error}\"") (validationResult.errors or [])}
                exit 1
              fi
              
              # Formatter availability check
              echo ""
              echo "🔧 Formatter Availability:"
              errors=0
              
              ${lib.concatMapStringsSep "\n" (formatter: ''
                if ${if finalFormatterConfig.${formatter} or false then "true" else "false"}; then
                  # Check if the formatter tools are available
                  case "${formatter}" in
                    nix)
                      if command -v ${if cfg.formatters.nix.formatter == "nixfmt-rfc-style" then "nixfmt" else "alejandra"} >/dev/null 2>&1; then
                        echo "  ✅ ${formatter}: ${if cfg.formatters.nix.formatter == "nixfmt-rfc-style" then "nixfmt" else "alejandra"} available"
                      else
                        echo "  ❌ ${formatter}: ${if cfg.formatters.nix.formatter == "nixfmt-rfc-style" then "nixfmt" else "alejandra"} not found"
                        errors=$((errors + 1))
                      fi
                      ;;
                    web)
                      if command -v ${cfg.formatters.web.formatter or "biome"} >/dev/null 2>&1; then
                        echo "  ✅ ${formatter}: ${cfg.formatters.web.formatter or "biome"} available"
                      else
                        echo "  ❌ ${formatter}: ${cfg.formatters.web.formatter or "biome"} not found"
                        errors=$((errors + 1))
                      fi
                      ;;
                    *)
                      echo "  ℹ️  ${formatter}: enabled (tool check not implemented)"
                      ;;
                  esac
                fi
              '') ["nix" "web" "python" "shell" "rust" "yaml" "markdown" "json" "misc"]}
              
              echo ""
              
              # Final validation summary
              if [[ $errors -eq 0 ]]; then
                echo "🎉 Validation Complete: All checks passed!"
                echo ""
                echo "💡 Your treefmt-flake configuration is ready to use."
                echo "   Run 'nix fmt' to format your files."
              else
                echo "❌ Validation Failed: $errors error(s) found"
                echo ""
                echo "💡 To fix formatter availability issues:"
                echo "   - Make sure you're in a 'nix develop' shell"
                echo "   - Check that all required formatters are installed"
                echo "   - Consider using 'allowMissingFormatter = true' for optional formatters"
                exit 1
              fi
            '';
          } // lib.optionalAttrs cfg.incremental.enable {
            # Incremental tools - only when incremental mode is enabled
            treefmt-fast = pkgs.writeShellScriptBin "treefmt-fast" ''
              ${
                if cfg.incremental.enable then
                  "${createIncrementalWrapper pkgs config.treefmt.build.wrapper}/bin/treefmt-incremental"
                else
                  "${config.treefmt.build.wrapper}/bin/treefmt"
              } --no-cache "$@"
            '';

            treefmt-staged = pkgs.writeShellScriptBin "treefmt-staged" ''
              export TREEFMT_STAGED_ONLY=true
              ${
                if cfg.incremental.enable then
                  "${createIncrementalWrapper pkgs config.treefmt.build.wrapper}/bin/treefmt-incremental"
                else
                  "${config.treefmt.build.wrapper}/bin/treefmt"
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
                if cfg.incremental.enable then
                  "${createIncrementalWrapper pkgs config.treefmt.build.wrapper}/bin/treefmt-incremental"
                else
                  "${config.treefmt.build.wrapper}/bin/treefmt"
              } "$@"
            '';
          };
        };
    };
}
