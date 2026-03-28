{lib}: let
  # Import shared utilities
  sharedUtils = import ./utils.nix {inherit lib;};
  inherit (sharedUtils) debug validation;
  inherit (sharedUtils.functional) pipe const id composeValidators;

  # Apply validator with debug tracing (using shared debug utilities)
  validateWithTrace = name: validator: input:
    lib.trivial.pipe input [
      validator
      (debug.traceValidation name)
    ];
  # Common validation patterns
  validators = {
    # Check if user enabled formatters but project has no matching files
    checkFormatterRelevance = cfg: projectPath: let
      # This would ideally scan the project, but we'll provide warnings based on common patterns
      warnings = [];

      # Check for common misconfigurations
      nixWarning =
        if
          cfg.nix
          && !lib.pathExists (projectPath + "/flake.nix")
          && !lib.pathExists (projectPath + "/default.nix")
        then [
          "Warning: Nix formatters enabled but no Nix files detected. Consider disabling 'nix = true' if not needed."
        ]
        else [];

      rustWarning =
        if cfg.rust && !lib.pathExists (projectPath + "/Cargo.toml")
        then [
          "Warning: Rust formatters enabled but no Cargo.toml found. Consider disabling 'rust = true' if this isn't a Rust project."
        ]
        else [];

      pythonWarning =
        if
          cfg.python
          && !lib.pathExists (projectPath + "/requirements.txt")
          && !lib.pathExists (projectPath + "/pyproject.toml")
          && !lib.pathExists (projectPath + "/setup.py")
        then [
          "Warning: Python formatters enabled but no Python project files detected. Consider disabling 'python = true' if not needed."
        ]
        else [];
    in
      warnings ++ nixWarning ++ rustWarning ++ pythonWarning;

    # Validate incremental configuration
    validateIncrementalConfig = incremental: let
      errors = [];

      cacheDirError =
        if incremental.enable && incremental.cache == ""
        then ["Error: incremental.cache cannot be empty when incremental formatting is enabled"]
        else [];

      modeError =
        if incremental.enable && incremental.mode == "git" && !incremental.gitBased
        then ["Error: incremental.mode='git' requires incremental.gitBased=true"]
        else [];

      conflictError =
        if incremental.enable && incremental.mode == "cache" && incremental.gitBased
        then [
          "Warning: incremental.mode='cache' with gitBased=true may cause conflicts. Consider mode='auto' instead."
        ]
        else [];
    in
      errors ++ cacheDirError ++ modeError ++ conflictError;

    # Validate performance profile makes sense
    validatePerformanceConfig = performance: incremental: let
      warnings = [];

      perfIncrementalWarning =
        if performance == "fast" && incremental.enable && incremental.mode == "cache"
        then ["Info: 'fast' performance profile with cache mode is optimal for incremental formatting"]
        else [];

      thoroughWarning =
        if performance == "thorough" && incremental.enable
        then [
          "Warning: 'thorough' performance profile may slow down incremental formatting. Consider 'balanced' for better performance."
        ]
        else [];
    in
      warnings ++ perfIncrementalWarning ++ thoroughWarning;

    # Check for logical inconsistencies
    validateLogicalConsistency = cfg: let
      errors = [];

      # Check if any formatters are enabled
      anyEnabled =
        cfg.nix
        || cfg.web
        || cfg.python
        || cfg.shell
        || cfg.rust
        || cfg.yaml
        || cfg.markdown
        || cfg.json
        || cfg.misc;
      noFormattersError =
        if !anyEnabled
        then [
          "Error: No formatters enabled. Enable at least one formatter group (nix, web, python, etc.) or this configuration will have no effect."
        ]
        else [];

      # Check projectRootFile exists (this would need to be done at evaluation time)
      rootFileWarning =
        if
          cfg.projectRootFile
          != "flake.nix"
          && cfg.projectRootFile != "package.json"
          && cfg.projectRootFile != "Cargo.toml"
          && cfg.projectRootFile != "pyproject.toml"
        then [
          "Warning: projectRootFile '${cfg.projectRootFile}' is not a common project root marker. Ensure this file exists in your project root."
        ]
        else [];

      # Warn about deprecated patterns
      missingFormatterWarning =
        if cfg.allowMissingFormatter
        then [
          "Warning: allowMissingFormatter=true can hide configuration issues. Consider using allowMissingFormatter=false and installing required formatters."
        ]
        else [];
    in
      errors ++ noFormattersError ++ rootFileWarning ++ missingFormatterWarning;
  };

  # Generate comprehensive validation report
  validateConfiguration = cfg: let
    incrementalValidation = validators.validateIncrementalConfig cfg.incremental;
    performanceValidation = validators.validatePerformanceConfig cfg.performance cfg.incremental;
    logicalValidation = validators.validateLogicalConsistency cfg;

    allMessages = incrementalValidation ++ performanceValidation ++ logicalValidation;

    errors = lib.filter (msg: lib.hasPrefix "Error:" msg) allMessages;
    warnings = lib.filter (msg: lib.hasPrefix "Warning:" msg) allMessages;
    info = lib.filter (msg: lib.hasPrefix "Info:" msg) allMessages;
  in {
    valid = errors == [];
    inherit errors;
    inherit warnings;
    inherit info;

    # Helper to format all messages nicely
    formatMessages = let
      formatSection = title: messages:
        if messages == []
        then ""
        else "\n${title}:\n${lib.concatMapStringsSep "\n" (msg: "  - ${msg}") messages}";
    in
      (formatSection "ERRORS" errors) + (formatSection "WARNINGS" warnings) + (formatSection "INFO" info);
  };

  # Enhanced option types with validation
  validatedSubmodule = submoduleOptions:
    lib.types.submodule {
      options = submoduleOptions;

      # Add validation that runs when the config is finalized
      check = config: let
        validation = validateConfiguration config;
      in
        if validation.valid
        then config
        else throw "treefmt-flake configuration validation failed:${validation.formatMessages}";
    };

  # Helper to create better error messages for enum options
  # Enhanced with lib.generators for structured error output
  betterEnum = values: description: exampleValue:
    lib.types.enum values
    // {
      name = "enum";
      description = "${description}\nAllowed values: ${lib.concatStringsSep ", " values}\nExample: ${exampleValue}";
      check = x:
        if lib.elem x values
        then true
        else let
          # Find the closest match for better user guidance
          closestMatch = lib.findFirst (v: lib.hasPrefix (lib.substring 0 1 (toString x)) v) (lib.head values) values;

          # Generate structured error message using lib.generators
          errorDetails = {
            invalid_value = toString x;
            allowed_values = values;
            suggestion = "Use one of: ${lib.concatStringsSep " | " values}";
            closest_match = "Did you mean '${closestMatch}'?";
            example = "Example: ${exampleValue}";
            documentation = "See documentation for more details";
          };
          formattedError = lib.generators.toPretty {allowPrettyValues = true;} errorDetails;
        in
          throw "❌ Invalid enum value!\n${formattedError}";
    };

  # Helper for string options with validation
  validatedString = validator: description:
    lib.types.str
    // {
      check = x:
        if lib.isString x && validator x
        then true
        else let
          errorDetails = {
            invalid_value = toString x;
            requirement = description;
            value_type = builtins.typeOf x;
            suggestion =
              if !lib.isString x
              then "Provide a string value"
              else "Check the format requirements";
          };
          formattedError = lib.generators.toPretty {allowPrettyValues = true;} errorDetails;
        in
          throw "❌ Invalid string value!\n${formattedError}";
    };

  # User-friendly path type with helpful error messages
  userFriendlyPath = description:
    lib.types.path
    // {
      name = "user-friendly-path";
      description = "${description}\nMust be a valid file system path";
      check = x:
        if lib.types.path.check x
        then true
        else let
          errorDetails = {
            invalid_value = toString x;
            requirement = description;
            suggestion =
              if lib.isString x
              then "Use a path type: ./your/path or /absolute/path"
              else "Provide a valid path";
            examples = ["./relative/path" "/absolute/path" "~/home/path"];
          };
        in
          throw "❌ Invalid path!\n${lib.generators.toPretty {allowPrettyValues = true;} errorDetails}";
    };

  # Enhanced port type with range validation
  userFriendlyPort = description:
    lib.types.ints.between 1 65535
    // {
      name = "user-friendly-port";
      description = "${description}\nMust be a port number between 1 and 65535";
      check = x:
        if lib.isInt x && x >= 1 && x <= 65535
        then true
        else let
          errorDetails = {
            invalid_value = toString x;
            requirement = "Port number between 1 and 65535";
            suggestion =
              if lib.isInt x
              then "Use a port in valid range"
              else "Provide an integer";
            common_ports = {
              http = 80;
              https = 443;
              ssh = 22;
              development = 3000;
            };
          };
        in
          throw "❌ Invalid port!\n${lib.generators.toPretty {allowPrettyValues = true;} errorDetails}";
    };

  # Common validators for string options
  stringValidators = {
    nonEmpty = x: x != "";
    isPath = x: lib.hasPrefix "/" x || lib.hasPrefix "./" x || lib.hasPrefix "../" x;
    isFileName = x: !lib.hasInfix "/" x && x != "";
    isCacheDir = x: x != "" && !lib.hasPrefix "/" x; # Relative paths preferred for cache
  };

  # Helper to create file existence warnings (to be shown at runtime)
  createFileExistenceCheck = filePath: description: ''
    if [[ ! -e "${filePath}" ]]; then
      echo "⚠️  Warning: ${description} - file '${filePath}' not found"
      echo "   Consider verifying the path or updating projectRootFile option"
    fi
  '';

  # Generate runtime validation script
  generateRuntimeValidation = cfg: ''
    #!/usr/bin/env bash
    # Runtime validation for treefmt-flake configuration

    ${createFileExistenceCheck cfg.projectRootFile "projectRootFile"}

    ${lib.optionalString cfg.incremental.enable (
      createFileExistenceCheck cfg.incremental.cache "incremental cache directory"
    )}

    ${lib.optionalString (cfg.incremental.enable && cfg.incremental.gitBased) ''
      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "⚠️  Warning: incremental.gitBased=true but not in a git repository"
        echo "   Incremental formatting may not work as expected"
      fi
    ''}

    # Check if enabled formatters make sense for the project
    ${lib.optionalString cfg.nix ''
      if [[ ! -f "flake.nix" && ! -f "default.nix" && ! -f "shell.nix" ]]; then
        echo "💡 Info: Nix formatters enabled but no common Nix files found"
        echo "   Files will be formatted if they match *.nix pattern"
      fi
    ''}

    ${lib.optionalString cfg.rust ''
      if [[ ! -f "Cargo.toml" ]]; then
        echo "💡 Info: Rust formatters enabled but no Cargo.toml found"
        echo "   Files will be formatted if they match *.rs pattern"
      fi
    ''}

    ${lib.optionalString cfg.python ''
      if [[ ! -f "pyproject.toml" && ! -f "setup.py" && ! -f "requirements.txt" ]]; then
        echo "💡 Info: Python formatters enabled but no Python project files found"
        echo "   Files will be formatted if they match *.py pattern"
      fi
    ''}
  '';
in {
  inherit
    validators
    validateConfiguration
    validatedSubmodule
    betterEnum
    validatedString
    stringValidators
    generateRuntimeValidation
    debug
    userFriendlyPath
    userFriendlyPort
    ;

  # Re-export functional utilities as a namespace
  functional = {
    inherit pipe const id composeValidators;
  };

  # Export enhanced types
  types = {
    inherit validatedSubmodule;
    inherit betterEnum;
    inherit validatedString;
    inherit userFriendlyPath;
    inherit userFriendlyPort;
  };
}
