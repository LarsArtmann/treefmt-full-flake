# Formatter registry for organized formatter module management
{ lib }:

let
  # Registry of all available formatter modules
  formatterModules = {
    # Nix formatters
    nix = {
      path = ../formatters/nix.nix;
      description = "Nix code formatting with alejandra";
      languages = [ "nix" ];
      tools = [ "alejandra" "deadnix" "statix" ];
    };
    
    nix-nixfmt = {
      path = ../formatters/nix-nixfmt.nix;
      description = "Nix code formatting with nixfmt-rfc-style (deterministic)";
      languages = [ "nix" ];
      tools = [ "nixfmt-rfc-style" "deadnix" "statix" ];
    };
    
    # Web development formatters
    web = {
      path = ../formatters/web.nix;
      description = "Web development formatting with biome";
      languages = [ "javascript" "typescript" "css" "scss" "json" ];
      tools = [ "biome" ];
    };
    
    # Python formatters
    python = {
      path = ../formatters/python.nix;
      description = "Python code formatting";
      languages = [ "python" ];
      tools = [ "black" "isort" "ruff-format" ];
    };
    
    # Shell script formatters
    shell = {
      path = ../formatters/shell.nix;
      description = "Shell script formatting";
      languages = [ "shell" "bash" "zsh" ];
      tools = [ "shfmt" "shellcheck" ];
    };
    
    # Rust formatters
    rust = {
      path = ../formatters/rust.nix;
      description = "Rust code formatting";
      languages = [ "rust" ];
      tools = [ "rustfmt" ];
    };
    
    # YAML formatters
    yaml = {
      path = ../formatters/yaml.nix;
      description = "YAML file formatting";
      languages = [ "yaml" ];
      tools = [ "yamlfmt" ];
    };
    
    # Markdown formatters
    markdown = {
      path = ../formatters/markdown.nix;
      description = "Markdown document formatting";
      languages = [ "markdown" ];
      tools = [ "mdformat" ];
    };
    
    # JSON formatters
    json = {
      path = ../formatters/json.nix;
      description = "JSON file formatting";
      languages = [ "json" ];
      tools = [ "jsonfmt" "jq" ];
    };
    
    # Miscellaneous formatters
    misc = {
      path = ../formatters/misc.nix;
      description = "Miscellaneous formatters";
      languages = [ "toml" "proto" "typespec" ];
      tools = [ "buf" "taplo" "actionlint" "just" ];
    };
  };

  # Get a specific formatter module
  getFormatterModule = name:
    if formatterModules ? ${name} then
      import formatterModules.${name}.path
    else
      throw "Unknown formatter module: ${name}";

  # Get formatter module for Nix based on configuration
  getNixFormatterModule = formatter:
    if formatter == "nixfmt-rfc-style" then
      getFormatterModule "nix-nixfmt"
    else
      getFormatterModule "nix";

  # Get all formatter modules as an attribute set
  getAllFormatterModules = lib.mapAttrs (name: info: import info.path) formatterModules;

  # Load formatter modules based on enabled configuration
  loadFormatterModules = enabledFormatters: nixFormatter:
    let
      moduleList = lib.optionals (enabledFormatters.nix or false) [
        (getNixFormatterModule nixFormatter)
      ]
      ++ lib.optionals (enabledFormatters.web or false) [
        (getFormatterModule "web")
      ]
      ++ lib.optionals (enabledFormatters.python or false) [
        (getFormatterModule "python")
      ]
      ++ lib.optionals (enabledFormatters.shell or false) [
        (getFormatterModule "shell")
      ]
      ++ lib.optionals (enabledFormatters.rust or false) [
        (getFormatterModule "rust")
      ]
      ++ lib.optionals (enabledFormatters.yaml or false) [
        (getFormatterModule "yaml")
      ]
      ++ lib.optionals (enabledFormatters.markdown or false) [
        (getFormatterModule "markdown")
      ]
      ++ lib.optionals (enabledFormatters.json or false) [
        (getFormatterModule "json")
      ]
      ++ lib.optionals (enabledFormatters.misc or false) [
        (getFormatterModule "misc")
      ];
    in
    lib.mkMerge moduleList;

  # Get formatter information
  getFormatterInfo = name:
    formatterModules.${name} or null;

  # List all available formatters
  listAvailableFormatters = lib.attrNames formatterModules;

  # Get formatters by language
  getFormattersByLanguage = language:
    lib.filterAttrs (name: info:
      lib.elem language info.languages
    ) formatterModules;

  # Get formatters by tool
  getFormattersByTool = tool:
    lib.filterAttrs (name: info:
      lib.elem tool info.tools
    ) formatterModules;

  # Validate formatter configuration
  validateFormatterConfig = config:
    let
      errors = lib.concatMap (name:
        if formatterModules ? ${name} then
          []
        else
          [ "Unknown formatter: ${name}" ]
      ) (lib.attrNames config);
    in
    {
      isValid = errors == [];
      inherit errors;
    };
in
{
  inherit
    formatterModules
    getFormatterModule
    getNixFormatterModule
    getAllFormatterModules
    loadFormatterModules
    getFormatterInfo
    listAvailableFormatters
    getFormattersByLanguage
    getFormattersByTool
    validateFormatterConfig
    ;

  # Metadata
  meta = {
    description = "Formatter registry and module management";
    version = "2.0.0";
    totalFormatters = lib.length (lib.attrNames formatterModules);
    supportedLanguages = lib.unique (lib.concatMap (info: info.languages) (lib.attrValues formatterModules));
  };
}