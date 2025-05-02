{
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  
  options = {
    treefmtFlake = lib.mkOption {
      type = lib.types.submodule {
        options = {
          # Enable specific formatter groups
          enableNix = lib.mkEnableOption "Enable Nix formatters (alejandra, deadnix, statix)";
          enableWeb = lib.mkEnableOption "Enable Web formatters (biome for JS/TS/CSS)";
          enablePython = lib.mkEnableOption "Enable Python formatters (black, isort, ruff)";
          enableShell = lib.mkEnableOption "Enable Shell formatters (shfmt, shellcheck)";
          enableRust = lib.mkEnableOption "Enable Rust formatters (rustfmt)";
          enableYaml = lib.mkEnableOption "Enable YAML formatters (yamlfmt)";
          enableMarkdown = lib.mkEnableOption "Enable Markdown formatters (mdformat)";
          enableJson = lib.mkEnableOption "Enable JSON formatters (jsonfmt, jq)";
          enableMisc = lib.mkEnableOption "Enable miscellaneous formatters";
          
          # Configuration options
          projectRootFile = lib.mkOption {
            type = lib.types.str;
            default = "flake.nix";
            description = "File that marks the project root";
          };
          
          enableGlobalExcludes = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable global excludes for common patterns";
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
    formatterConfigs = lib.flatten (lib.optional cfg.enableNix (import ./formatters/nix.nix)
      ++ lib.optional cfg.enableWeb (import ./formatters/web.nix)
      ++ lib.optional cfg.enablePython (import ./formatters/python.nix)
      ++ lib.optional cfg.enableShell (import ./formatters/shell.nix)
      ++ lib.optional cfg.enableRust (import ./formatters/rust.nix)
      ++ lib.optional cfg.enableYaml (import ./formatters/yaml.nix)
      ++ lib.optional cfg.enableMarkdown (import ./formatters/markdown.nix)
      ++ lib.optional cfg.enableJson (import ./formatters/json.nix)
      ++ lib.optional cfg.enableMisc (import ./formatters/misc.nix));
  in {
    perSystem = {
      config,
      pkgs,
      system,
      ...
    }: {
      treefmt = {
        projectRootFile = cfg.projectRootFile;
        
        # Enable default excludes if requested
        inherit (cfg) enableGlobalExcludes;
        
        # Allow missing formatters if requested
        build.allowMissingTools = cfg.allowMissingFormatter;
        
        # Apply formatter configurations
        programs = lib.mkMerge formatterConfigs;
      };
      
      # Make the formatter available as a package
      formatter = config.treefmt.build.wrapper;
    };
  };
}
