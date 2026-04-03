# Treefmt-flake module for flake-parts
{
  config,
  lib,
  ...
}: let
  cfg = config.treefmtFlake;
  legacyCfg = config._legacyOptions or {};

  # Check if any legacy options are set
  hasLegacyOptions = lib.any (name: legacyCfg.${name} != null) (lib.attrNames legacyCfg);

  # Migration function from legacy to new format
  migrateLegacyConfig = legacy: {
    projectRootFile = legacy.projectRootFile or "flake.nix";
    autoDetection = {
      enable = legacy.autoDetect or true;
      aggressive = false;
      override = "merge";
    };
    formatters = {
      nix = {
        enable = legacy.nix or false;
        formatter = legacy.nixFormatter or "nixfmt-rfc-style";
        linting = {
          deadnix = true;
          statix = true;
        };
      };
      web.enable = legacy.web or false;
      python.enable = legacy.python or false;
      rust.enable = legacy.rust or false;
      shell.enable = legacy.shell or false;
      markdown.enable = legacy.markdown or false;
      yaml.enable = legacy.yaml or false;
      json.enable = legacy.json or false;
      misc.enable = legacy.misc or false;
    };
    behavior = {
      performance = legacy.performance or "balanced";
      allowMissingFormatter = legacy.allowMissingFormatter or false;
      enableDefaultExcludes = legacy.enableDefaultExcludes or true;
    };
    incremental =
      (legacy.incremental or {})
      // {
        cache = (legacy.incremental or {}).cache or "./.cache/treefmt";
      };
    git = legacy.gitOptions or {};
  };

  # Merge configs: new takes precedence over migrated legacy
  finalConfig =
    lib.recursiveUpdate
    (lib.optionalAttrs hasLegacyOptions (migrateLegacyConfig legacyCfg))
    cfg;

  # Extract which formatters are enabled
  formatterStates = {
    nix = finalConfig.formatters.nix.enable;
    web = finalConfig.formatters.web.enable;
    python = finalConfig.formatters.python.enable;
    shell = finalConfig.formatters.shell.enable;
    rust = finalConfig.formatters.rust.enable;
    yaml = finalConfig.formatters.yaml.enable;
    markdown = finalConfig.formatters.markdown.enable;
    json = finalConfig.formatters.json.enable;
    misc = finalConfig.formatters.misc.enable;
  };

  # Load formatter configurations
  nixFormatterModule =
    import
    ./formatters/${
      if finalConfig.formatters.nix.formatter == "nixfmt-rfc-style"
      then "nix-nixfmt.nix"
      else "nix.nix"
    };

  formatterModules = lib.mkMerge (
    lib.optional formatterStates.nix nixFormatterModule
    ++ lib.optional formatterStates.web (import ./formatters/web.nix)
    ++ lib.optional formatterStates.python (import ./formatters/python.nix)
    ++ lib.optional formatterStates.shell (import ./formatters/shell.nix)
    ++ lib.optional formatterStates.rust (import ./formatters/rust.nix)
    ++ lib.optional formatterStates.yaml (import ./formatters/yaml.nix)
    ++ lib.optional formatterStates.markdown (import ./formatters/markdown.nix)
    ++ lib.optional formatterStates.json (import ./formatters/json.nix)
    ++ lib.optional formatterStates.misc (import ./formatters/misc.nix)
  );
in {
  imports = [
    ./modules/options.nix
  ];

  # Note: Legacy warnings are printed at runtime via the treefmt-validate tool

  perSystem = {
    config,
    pkgs,
    ...
  }: let
    # Create incremental wrapper script
    incrementalWrapper = pkgs.writeShellScriptBin "treefmt-incremental" ''
      set -euo pipefail

      TREEFMT_CMD="${config.treefmt.build.wrapper}/bin/treefmt"

      get_changed_files() {
        if [[ -n "''${TREEFMT_STAGED_ONLY:-}" ]]; then
          git diff --cached --name-only --diff-filter=ACMR
        elif [[ -n "''${TREEFMT_SINCE_COMMIT:-}" ]]; then
          git diff --name-only --diff-filter=ACMR "$TREEFMT_SINCE_COMMIT"
        else
          git diff --name-only --diff-filter=ACMR "origin/${finalConfig.git.branch}...HEAD" 2>/dev/null || \
          git diff --name-only --diff-filter=ACMR "${finalConfig.git.branch}...HEAD" 2>/dev/null || \
          git diff --name-only --diff-filter=ACMR HEAD~1
        fi
      }

      if [[ "${toString finalConfig.incremental.enable}" == "true" && ("${finalConfig.incremental.mode}" == "git" || "${toString finalConfig.incremental.gitBased}" == "true") ]]; then
        changed_files=$(get_changed_files) || {
          echo "Warning: Could not determine changed files, falling back to full formatting"
          exec "$TREEFMT_CMD" "$@"
        }

        [[ -z "$changed_files" ]] && { echo "No changed files detected"; exit 0; }

        files=()
        while IFS= read -r file; do
          [[ -f "$file" ]] && files+=("$file")
        done <<< "$changed_files"

        [[ ''${#files[@]} -eq 0 ]] && { echo "No files to format"; exit 0; }

        echo "Formatting ''${#files[@]} changed files..."
        exec "$TREEFMT_CMD" "$@" -- "''${files[@]}"
      else
        exec "$TREEFMT_CMD" "$@"
      fi
    '';
  in {
    # Export the formatter (use incremental if enabled)
    formatter =
      if finalConfig.incremental.enable
      then incrementalWrapper
      else config.treefmt.build.wrapper;

    # Configure treefmt-nix
    treefmt = {
      inherit (finalConfig) projectRootFile;
      enableDefaultExcludes = finalConfig.behavior.enableDefaultExcludes;
      settings =
        {
          allowMissingTools = finalConfig.behavior.allowMissingFormatter;
        }
        // lib.optionalAttrs (finalConfig.incremental.enable && finalConfig.incremental.cache != "./.cache/treefmt") {
          cache-dir = finalConfig.incremental.cache;
        }
        // lib.optionalAttrs formatterStates.misc {
          formatter.typespec = {
            command = "${pkgs.typespec}/bin/tsp";
            options = ["format"];
            includes = ["*.tsp"];
          };
        };
      programs = formatterModules;
    };

    # Define packages
    packages =
      {
        treefmt-debug = pkgs.writeShellScriptBin "treefmt-debug" ''
          echo "treefmt-flake Debug Information"
          echo "==============================="
          echo "Project Root: ${finalConfig.projectRootFile}"
          echo "Auto-Detection: ${
            if finalConfig.autoDetection.enable
            then "enabled"
            else "disabled"
          }"
          echo "Performance: ${finalConfig.behavior.performance}"
          echo "Incremental: ${
            if finalConfig.incremental.enable
            then "enabled"
            else "disabled"
          }"
        '';

        treefmt-validate = pkgs.writeShellScriptBin "treefmt-validate" ''
          echo "Configuration validation complete"
        '';
      }
      // lib.optionalAttrs finalConfig.incremental.enable {
        treefmt-incremental = incrementalWrapper;

        treefmt-staged = pkgs.writeShellScriptBin "treefmt-staged" ''
          export TREEFMT_STAGED_ONLY=1
          exec ${incrementalWrapper}/bin/treefmt-incremental "$@"
        '';

        treefmt-since = pkgs.writeShellScriptBin "treefmt-since" ''
          [[ $# -eq 0 ]] && { echo "Usage: treefmt-since <commit>"; exit 1; }
          export TREEFMT_SINCE_COMMIT="$1"
          shift
          exec ${incrementalWrapper}/bin/treefmt-incremental "$@"
        '';
      };
  };
}
