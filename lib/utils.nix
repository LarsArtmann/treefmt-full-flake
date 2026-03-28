# Shared utility functions for treefmt-flake
# This module consolidates common patterns used across the library
{lib}: let
  # Functional programming utilities
  functional = {
    inherit (lib.trivial) pipe const id;

    # Compose two functions: (f . g)(x) = f(g(x))
    compose = f: g: x: f (g x);

    # Compose multiple validators into one
    composeValidators = validators: input:
      lib.trivial.pipe input [
        (lib.foldl (acc: validator: acc // validator input) {
            isValid = true;
            errors = [];
            warnings = [];
          }
          validators)
      ];

    # Apply a processor with optional debug tracing
    processWithDebug = name: processor: input:
      lib.trivial.pipe input [
        processor
        (
          result:
            if builtins.getEnv "TREEFMT_DEBUG" == "1"
            then builtins.trace "DEBUG[${name}]: result" result
            else result
        )
      ];
  };

  # Debug utilities - centralized tracing
  debug = {
    # Trace validation result
    traceValidation = name: result:
      lib.debug.traceVal "VALIDATION[${name}]: ${
        if result.isValid or result.valid or false
        then "PASS"
        else "FAIL"
      }";

    # Trace errors
    traceErrors = errors:
      lib.debug.traceVal "ERRORS: ${lib.generators.toJSON {} errors}";

    # Trace warnings
    traceWarnings = warnings:
      lib.debug.traceVal "WARNINGS: ${lib.generators.toJSON {} warnings}";

    # Conditional tracing
    traceIf = condition: message:
      lib.debug.traceIf condition message;

    # Trace with environment variable check
    traceIfDebug = name: value:
      if builtins.getEnv "TREEFMT_DEBUG_${lib.strings.toUpper name}" == "1"
      then lib.debug.traceVal "DEBUG[${name}]: ${toString value}" value
      else value;
  };

  # Common validation result structure helpers
  validation = {
    # Create a valid result
    valid = {
      isValid = true;
      valid = true;
      errors = [];
      warnings = [];
    };

    # Create an invalid result with errors
    invalid = errors: {
      isValid = false;
      valid = false;
      inherit errors;
      warnings = [];
    };

    # Create a result with warnings
    withWarnings = base: warnings: base // {inherit warnings;};

    # Merge multiple validation results
    mergeResults = results: let
      allErrors = lib.concatMap (r: r.errors or []) results;
      allWarnings = lib.concatMap (r: r.warnings or []) results;
    in {
      isValid = allErrors == [];
      valid = allErrors == [];
      errors = allErrors;
      warnings = allWarnings;
    };

    # Check if result is valid (handles both isValid and valid fields)
    isValid = result: (result.isValid or result.valid or false);
  };
in {
  inherit functional debug validation;

  # Metadata
  meta = {
    description = "Shared utility functions for treefmt-flake";
    version = "1.0.0";
  };
}
