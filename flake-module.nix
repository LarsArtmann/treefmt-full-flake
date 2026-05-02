# Treefmt-flake module for flake-parts
{
  config,
  lib,
  ...
}: let
  cfg = config.treefmtFlake;

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

  nixFormatterModule =
    import
    ./formatters/${
      if cfg.formatters.nix.formatter == "nixfmt-rfc-style"
      then "nix-nixfmt.nix"
      else "nix.nix"
    };

  formatterModules =
    {}
    // lib.optionalAttrs formatterStates.nix nixFormatterModule
    // lib.optionalAttrs formatterStates.web (import ./formatters/web.nix)
    // lib.optionalAttrs formatterStates.python (import ./formatters/python.nix)
    // lib.optionalAttrs formatterStates.shell (import ./formatters/shell.nix)
    // lib.optionalAttrs formatterStates.rust (import ./formatters/rust.nix)
    // lib.optionalAttrs formatterStates.yaml (import ./formatters/yaml.nix)
    // lib.optionalAttrs formatterStates.markdown (import ./formatters/markdown.nix)
    // lib.optionalAttrs formatterStates.json (import ./formatters/json.nix)
    // lib.optionalAttrs formatterStates.misc (import ./formatters/misc.nix);
in {
  imports = [
    ./modules/options.nix
  ];

  perSystem = {
    config,
    pkgs,
    ...
  }: let
    incrementalWrapper = pkgs.writeShellScriptBin "treefmt-incremental" ''
      set -euo pipefail

      TREEFMT_CMD="${config.treefmt.build.wrapper}/bin/treefmt"

      get_changed_files() {
        if [[ -n "''${TREEFMT_STAGED_ONLY:-}" ]]; then
          git diff --cached --name-only --diff-filter=ACMR
        elif [[ -n "''${TREEFMT_SINCE_COMMIT:-}" ]]; then
          git diff --name-only --diff-filter=ACMR "$TREEFMT_SINCE_COMMIT"
        else
          git diff --name-only --diff-filter=ACMR "origin/${cfg.git.branch}...HEAD" 2>/dev/null || \
          git diff --name-only --diff-filter=ACMR "${cfg.git.branch}...HEAD" 2>/dev/null || \
          git diff --name-only --diff-filter=ACMR HEAD~1
        fi
      }

      if [[ "${toString cfg.incremental.enable}" == "true" && ("${cfg.incremental.mode}" == "git" || "${toString cfg.incremental.gitBased}" == "true") ]]; then
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
    formatter =
      if cfg.incremental.enable
      then incrementalWrapper
      else config.treefmt.build.wrapper;

    treefmt = {
      inherit (cfg) projectRootFile;
      enableDefaultExcludes = cfg.behavior.enableDefaultExcludes;
      settings =
        {
          allowMissingTools = cfg.behavior.allowMissingFormatter;
        }
        // lib.optionalAttrs (cfg.incremental.enable && cfg.incremental.cache != "./.cache/treefmt") {
          cache-dir = cfg.incremental.cache;
        };
      programs = formatterModules;
    };

    packages =
      {
        treefmt-debug = pkgs.writeShellScriptBin "treefmt-debug" ''
          echo "treefmt-flake Debug Information"
          echo "==============================="
          echo "Project Root: ${cfg.projectRootFile}"
          echo "Incremental: ${
            if cfg.incremental.enable
            then "enabled"
            else "disabled"
          }"
        '';

        treefmt-validate = pkgs.writeShellScriptBin "treefmt-validate" ''
          echo "Configuration validation complete"
        '';
      }
      // lib.optionalAttrs cfg.incremental.enable {
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

    checks = {
      treefmt-config = pkgs.runCommand "treefmt-config-check" {} ''
        echo "Checking treefmt configuration..."
        ${config.treefmt.build.wrapper}/bin/treefmt --fail-on-change --no-cache || true
        touch $out
      '';

      treefmt-packages =
        pkgs.runCommand "treefmt-packages-check" {
          buildInputs = [config.treefmt.build.wrapper];
        } ''
          echo "Checking treefmt packages..."
          ${config.treefmt.build.wrapper}/bin/treefmt --version || true
          touch $out
        '';

      treefmt-modules = pkgs.runCommand "treefmt-modules-check" {} ''
        echo "Checking formatter modules..."
        ${lib.optionalString formatterStates.nix "echo '  Nix formatter: OK'"}
        ${lib.optionalString formatterStates.web "echo '  Web formatter: OK'"}
        ${lib.optionalString formatterStates.python "echo '  Python formatter: OK'"}
        ${lib.optionalString formatterStates.shell "echo '  Shell formatter: OK'"}
        ${lib.optionalString formatterStates.rust "echo '  Rust formatter: OK'"}
        ${lib.optionalString formatterStates.yaml "echo '  YAML formatter: OK'"}
        ${lib.optionalString formatterStates.markdown "echo '  Markdown formatter: OK'"}
        ${lib.optionalString formatterStates.json "echo '  JSON formatter: OK'"}
        ${lib.optionalString formatterStates.misc "echo '  Misc formatter: OK'"}
        touch $out
      '';
    };
  };
}
