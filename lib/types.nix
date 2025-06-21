# Centralized type definitions for treefmt-flake
# This module consolidates all custom types used throughout the library
{lib}: let
  # Import necessary modules for type composition
  configValidation = import ./config-validation.nix {inherit lib;};
  securityValidation = import ./security-validation.nix {inherit lib;};

  # Inherit basic type constructors from other modules
  inherit (configValidation) betterEnum validatedString stringValidators;
  inherit (securityValidation) secureTypes;
in {
  # Re-export existing type constructors
  inherit betterEnum validatedString stringValidators secureTypes;

  # Core configuration types
  types = {
    # Performance profile type with enhanced validation
    performanceProfile =
      betterEnum
      ["fast" "balanced" "thorough"]
      "Performance optimization profile for formatting operations"
      "balanced";

    # Incremental mode type
    incrementalMode =
      betterEnum
      ["auto" "cache" "git"]
      "Mode for incremental formatting optimization"
      "auto";

    # Nix formatter choice
    nixFormatter =
      betterEnum
      ["alejandra" "nixfmt-rfc-style"]
      "Nix code formatter to use"
      "alejandra";

    # Web formatter choice
    webFormatter =
      betterEnum
      ["biome" "prettier" "deno"]
      "Web development formatter to use"
      "biome";

    # Validated file name (no paths)
    fileName =
      validatedString
      stringValidators.isFileName
      "Must be a filename without directory paths";

    # Validated cache directory
    cacheDir =
      validatedString
      stringValidators.isCacheDir
      "Cache directory path (relative paths preferred)";

    # Non-empty string type
    nonEmptyStr =
      validatedString
      stringValidators.nonEmpty
      "String must not be empty";

    # Enhanced boolean with null for auto-detection
    nullableBool = lib.types.nullOr lib.types.bool;

    # Formatter priority (1-100)
    formatterPriority =
      lib.types.ints.between 1 100
      // {
        description = "Formatter execution priority (1 = highest, 100 = lowest)";
      };

    # Project size enumeration
    projectSize =
      betterEnum
      ["small" "medium" "large"]
      "Detected project size category"
      "medium";

    # File pattern type (for includes/excludes)
    filePattern =
      lib.types.either lib.types.str (lib.types.listOf lib.types.str)
      // {
        description = "File pattern(s) for matching - can be a string or list of strings";
      };

    # Git branch name with validation
    gitBranch =
      lib.types.strMatching "^[a-zA-Z0-9/_.-]+$"
      // {
        description = "Valid git branch name";
      };

    # Git commit SHA (partial or full)
    gitCommit =
      lib.types.strMatching "^[a-f0-9]{7,40}$"
      // {
        description = "Git commit SHA (7-40 hex characters)";
      };

    # URL type with basic validation
    url =
      lib.types.strMatching "^https?://[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"
      // {
        description = "Valid HTTP(S) URL";
      };

    # Semantic version type
    semver =
      lib.types.strMatching "^v?[0-9]+\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9.-]+)?(\\+[a-zA-Z0-9.-]+)?$"
      // {
        description = "Semantic version string (e.g., 1.2.3, v2.0.0-beta.1)";
      };

    # Command with arguments type
    commandWithArgs =
      lib.types.oneOf [
        lib.types.str # Simple command
        (lib.types.listOf lib.types.str) # Command with args list
      ]
      // {
        description = "Command string or list of command and arguments";
      };

    # Environment variable name
    envVarName =
      lib.types.strMatching "^[A-Z_][A-Z0-9_]*$"
      // {
        description = "Valid environment variable name (uppercase with underscores)";
      };

    # Positive integer for counts/sizes
    positiveInt =
      lib.types.ints.positive
      // {
        description = "Positive integer value (> 0)";
      };

    # Percentage type (0-100)
    percentage =
      lib.types.ints.between 0 100
      // {
        description = "Percentage value (0-100)";
      };

    # Duration in seconds
    durationSeconds =
      lib.types.either lib.types.int (lib.types.strMatching "^[0-9]+(s|m|h)$")
      // {
        description = "Duration in seconds (number or string like '30s', '5m', '2h')";
      };

    # File size with units
    fileSize =
      lib.types.either lib.types.int (lib.types.strMatching "^[0-9]+(B|K|M|G)$")
      // {
        description = "File size (number of bytes or string like '100K', '50M', '2G')";
      };
  };

  # Composite types for complex configurations
  composite = {
    # Formatter configuration with all options
    formatterConfig = lib.types.submodule {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable this formatter";
        };

        command = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Override default formatter command";
        };

        options = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Additional command-line options";
        };

        includes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "File patterns to include";
        };

        excludes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "File patterns to exclude";
        };

        priority = lib.mkOption {
          type = lib.types.ints.between 1 100;
          default = 50;
          description = "Execution priority (1 = highest)";
        };
      };
    };

    # Validation result type
    validationResult = lib.types.submodule {
      options = {
        isValid = lib.mkOption {
          type = lib.types.bool;
          description = "Whether validation passed";
        };

        errors = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Validation errors";
        };

        warnings = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Validation warnings";
        };

        recommendations = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Improvement recommendations";
        };
      };
    };

    # Performance metrics type
    performanceMetrics = lib.types.submodule {
      options = {
        startTime = lib.mkOption {
          type = lib.types.float;
          description = "Operation start time (unix timestamp)";
        };

        endTime = lib.mkOption {
          type = lib.types.float;
          description = "Operation end time (unix timestamp)";
        };

        fileCount = lib.mkOption {
          type = lib.types.int;
          description = "Number of files processed";
        };

        totalSize = lib.mkOption {
          type = lib.types.int;
          description = "Total size of files processed (bytes)";
        };

        formatterTimes = lib.mkOption {
          type = lib.types.attrsOf lib.types.float;
          default = {};
          description = "Time spent in each formatter";
        };
      };
    };
  };

  # Type validation helpers
  validators = rec {
    # Check if a value matches a type
    isType = type: value: type.check value;

    # Get type description
    typeDescription = type: type.description or "No description available";

    # Validate with detailed error
    validateType = type: value:
      if type.check value
      then {
        valid = true;
        error = null;
      }
      else {
        valid = false;
        error = "Value '${toString value}' does not match type: ${typeDescription type}";
      };
  };

  # Type composition utilities
  utils = {
    # Create a type that accepts multiple formats
    multiFormat = types:
      lib.types.oneOf types
      // {
        description = "Accepts multiple format types";
      };

    # Create optional type with default
    optionalWithDefault = type: default:
      lib.mkOption {
        type = lib.types.nullOr type;
        inherit default;
        description = type.description or "";
      };

    # Create deprecated type with warning
    deprecatedType = type: warning:
      type
      // {
        check = x:
          lib.warn warning (type.check x);
      };
  };

  # Export metadata
  meta = {
    description = "Centralized type definitions for treefmt-flake";
    version = "1.0.0";
    features = [
      "Enhanced type validation"
      "Security-focused types"
      "Composite type definitions"
      "Type composition utilities"
      "Validation helpers"
    ];
  };
}
