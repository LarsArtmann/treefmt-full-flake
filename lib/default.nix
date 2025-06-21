# Centralized library exports for treefmt-flake
# This provides a single entry point for all library functions
{ lib }:

let
  # Import all library modules
  securityValidation = import ./security-validation.nix { inherit lib; };
  configValidation = import ./config-validation.nix { inherit lib; };
  configSchema = import ./config-schema.nix { inherit lib; };
  performanceTracking = import ./performance-tracking.nix { inherit lib; };
  projectDetection = import ./project-detection.nix { inherit lib; };
  errorFormatting = import ./error-formatting.nix { inherit lib; };
  formatterRegistry = import ./formatter-registry.nix { inherit lib; };
in
{
  # Export all library functions with organized namespaces
  inherit
    securityValidation
    configValidation
    configSchema
    performanceTracking
    projectDetection
    errorFormatting
    formatterRegistry
    ;

  # Convenience exports for commonly used functions
  inherit (configValidation) betterEnum validatedString;
  inherit (configSchema.validation) validateConfig migrateConfig;
  inherit (securityValidation) validateSecurity secureFileCheck;
  inherit (projectDetection) generateAutoConfig mergeWithUserConfig;
  inherit (formatterRegistry) getFormatterModule getAllFormatterModules loadFormatterModules;

  # Version information
  version = "2.0.0";
  apiVersion = "v2";
}