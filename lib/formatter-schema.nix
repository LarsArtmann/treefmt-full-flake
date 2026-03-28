{lib}: let
  # Import centralized types
  types = import ./types.nix {inherit lib;};

  # Use centralized formatter config type
  formatterConfigType = types.composite.formatterConfig;

  # Language-specific formatter group schema
  formatterGroupType = lib.types.attrsOf formatterConfigType;

  # Validation functions
  validateFormatterConfig = name: config: let
    errors = [];

    # Check required fields
    includesError =
      if config.includes == []
      then ["Formatter '${name}' must specify 'includes' patterns"]
      else [];

    # Check priority conflicts within same includes
    priorityError =
      if config.priority < 1 || config.priority > 100
      then ["Formatter '${name}' priority must be between 1 and 100"]
      else [];

    # Check include patterns are valid
    patternErrors = lib.filter (x: x != null) (
      map (
        pattern:
          if lib.hasPrefix "/" pattern
          then "Formatter '${name}' include pattern '${pattern}' should not start with '/'"
          else null
      )
      config.includes
    );

    allErrors = errors ++ includesError ++ priorityError ++ patternErrors;
  in
    if allErrors == []
    then {
      valid = true;
      errors = [];
    }
    else {
      valid = false;
      errors = allErrors;
    };

  # Validate entire formatter group for conflicts
  validateFormatterGroup = groupName: formatters: let
    # Check for priority conflicts within same file patterns
    priorityConflicts = let
      formatterPairs = lib.cartesianProductOfSets {
        a = lib.attrNames formatters;
        b = lib.attrNames formatters;
      };

      conflicts =
        lib.filter (
          pair: let
            fmtA = formatters.${pair.a};
            fmtB = formatters.${pair.b};
            # Check if formatters have overlapping includes and same priority
            hasOverlap =
              lib.any (
                patternA: lib.any (patternB: patternA == patternB) fmtB.includes
              )
              fmtA.includes;
          in
            pair.a != pair.b && fmtA.priority == fmtB.priority && hasOverlap
        )
        formatterPairs;
    in
      map (
        conflict: "Priority conflict in group '${groupName}': formatters '${conflict.a}' and '${conflict.b}' have same priority ${
          toString formatters.${conflict.a}.priority
        } for overlapping patterns"
      )
      conflicts;

    # Validate individual formatters
    individualErrors = lib.flatten (
      lib.mapAttrsToList (
        name: config: let
          result = validateFormatterConfig name config;
        in
          if result.valid
          then []
          else result.errors
      )
      formatters
    );

    allErrors = priorityConflicts ++ individualErrors;
  in
    if allErrors == []
    then {
      valid = true;
      errors = [];
    }
    else {
      valid = false;
      errors = allErrors;
    };

  # Helper to create validated formatter config
  mkFormatterConfig = name: config: let
    # Apply defaults and validate
    fullConfig = formatterConfigType.check config;
    validation = validateFormatterConfig name fullConfig;
  in
    if validation.valid
    then fullConfig
    else throw "Invalid formatter configuration for '${name}':\n${lib.concatStringsSep "\n" validation.errors}";

  # Helper to create validated formatter group
  mkFormatterGroup = groupName: formatters: let
    # Validate entire group
    validation = validateFormatterGroup groupName formatters;
    validatedFormatters = lib.mapAttrs mkFormatterConfig formatters;
  in
    if validation.valid
    then validatedFormatters
    else throw "Invalid formatter group '${groupName}':\n${lib.concatStringsSep "\n" validation.errors}";

  # Common formatter configurations with validation
  commonConfigs = {
    # Priority-ordered Nix formatters
    nixFormatters = mkFormatterGroup "nix" {
      alejandra = {
        includes = ["*.nix"];
        priority = 1;
      };
      deadnix = {
        includes = ["*.nix"];
        priority = 2;
      };
      statix = {
        includes = ["*.nix"];
        priority = 3;
      };
    };

    # Web development formatters
    webFormatters = mkFormatterGroup "web" {
      biome = {
        includes = [
          "*.js"
          "*.jsx"
          "*.ts"
          "*.tsx"
          "*.css"
          "*.scss"
          "*.json"
        ];
        priority = 1;
      };
    };

    # Multi-language formatters with proper priorities
    miscFormatters = mkFormatterGroup "misc" {
      buf = {
        includes = ["*.proto"];
        priority = 1;
      };
      taplo = {
        includes = ["*.toml"];
        priority = 1;
      };
      just = {
        includes = [
          "justfile"
          "Justfile"
          "*.just"
        ];
        priority = 1;
      };
    };
  };
in {
  inherit
    formatterConfigType
    formatterGroupType
    validateFormatterConfig
    validateFormatterGroup
    mkFormatterConfig
    mkFormatterGroup
    commonConfigs
    ;

  # Export types for use in other modules
  types = {
    formatterConfig = formatterConfigType;
    formatterGroup = formatterGroupType;
  };
}
