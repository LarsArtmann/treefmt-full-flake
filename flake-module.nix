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
        };
      };
      default = {};
      description = "Configuration for treefmt-flake";
    };
  };

  config = let
    cfg = config.treefmtFlake;

    # Import formatter modules conditionally based on enabled options
    formatterConfigs = lib.flatten (lib.optional cfg.nix (import ./formatters/nix.nix)
      ++ lib.optional cfg.web (import ./formatters/web.nix)
      ++ lib.optional cfg.python (import ./formatters/python.nix)
      ++ lib.optional cfg.shell (import ./formatters/shell.nix)
      ++ lib.optional cfg.rust (import ./formatters/rust.nix)
      ++ lib.optional cfg.yaml (import ./formatters/yaml.nix)
      ++ lib.optional cfg.markdown (import ./formatters/markdown.nix)
      ++ lib.optional cfg.json (import ./formatters/json.nix)
      ++ lib.optional cfg.misc (import ./formatters/misc.nix));
  in {
    perSystem = {config, ...}: {
      treefmt = {
        inherit (cfg) projectRootFile;

        # Enable default excludes if requested
        inherit (cfg) enableDefaultExcludes;

        # Allow missing formatters if requested
        settings = {
          allowMissingTools = cfg.allowMissingFormatter;
        };

        # Apply formatter configurations
        programs = lib.mkMerge formatterConfigs;
      };

      # Make the formatter available as a package
      formatter = config.treefmt.build.wrapper;
    };
  };
}
