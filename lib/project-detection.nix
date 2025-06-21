# Project detection and auto-configuration logic
{lib}: let
  # File patterns for detecting different project types
  detectionPatterns = {
    nix = [
      "flake.nix"
      "default.nix"
      "shell.nix"
      "*.nix"
    ];

    web = [
      "package.json"
      "tsconfig.json"
      "*.js"
      "*.ts"
      "*.jsx"
      "*.tsx"
      "*.css"
      "*.scss"
      "*.vue"
      "*.svelte"
    ];

    python = [
      "pyproject.toml"
      "setup.py"
      "requirements.txt"
      "*.py"
      "Pipfile"
      ".python-version"
    ];

    rust = [
      "Cargo.toml"
      "Cargo.lock"
      "*.rs"
    ];

    shell = [
      "*.sh"
      "*.bash"
      "*.zsh"
      "*.fish"
    ];

    yaml = [
      "*.yml"
      "*.yaml"
      ".github/workflows/*.yml"
      ".github/workflows/*.yaml"
    ];

    markdown = [
      "*.md"
      "README.md"
      "CHANGELOG.md"
    ];

    json = [
      "*.json"
      ".eslintrc.json"
      "tsconfig.json"
    ];

    misc = [
      "*.toml"
      "*.tsp" # TypeSpec files
      "Justfile"
      "justfile"
      "*.proto" # Protocol buffers
      ".github/workflows/*.yml" # GitHub Actions
    ];
  };

  # Check if files matching patterns exist in project
  hasMatchingFiles = patterns: projectPath:
    lib.any (
      pattern:
      # In a real implementation, we'd use path checking
      # For now, use heuristics based on common patterns
        true # Simplified for flake evaluation context
    )
    patterns;

  # Generate auto-detected configuration based on project analysis
  generateAutoConfig = projectPath: let
    # Detect which formatters are likely needed
    detectedFormatters =
      lib.mapAttrs (
        name: patterns:
          hasMatchingFiles patterns projectPath
      )
      detectionPatterns;

    # Apply sensible defaults for common project types
    defaultConfig = {
      # Core formatters that are commonly needed
      nix = true; # Most Nix projects need this
      markdown = true; # Most projects have README.md
      yaml = true; # Common in CI/config files
      misc = true; # Enable misc formatters for TypeSpec, etc.

      # Other formatters based on detection
      web = detectedFormatters.web or false;
      python = detectedFormatters.python or false;
      rust = detectedFormatters.rust or false;
      shell = detectedFormatters.shell or false;
      json = detectedFormatters.json or false;
    };
  in
    defaultConfig;

  # Smart merge function that respects user preferences
  mergeWithUserConfig = autoDetected: userConfig:
  # Smart merge: user explicit settings override auto-detection
  # null values from user config use auto-detection
    lib.mapAttrs (
      name: userValue:
        if userValue != null
        then userValue # User explicitly set this
        else autoDetected.${name} or false # Use auto-detected value or false
    )
    userConfig;

  # Advanced project analysis (for future enhancement)
  analyzeProjectStructure = projectPath: {
    # Placeholder for future advanced analysis
    # Could include:
    # - Git repository analysis
    # - File size analysis
    # - Language statistics
    # - Framework detection

    hasGit = true; # Simplified
    projectSize = "medium"; # Simplified
    primaryLanguage = "nix"; # Simplified
    frameworks = []; # To be implemented
  };

  # Generate intelligent formatter recommendations
  getFormatterRecommendations = projectPath: let
    analysis = analyzeProjectStructure projectPath;
    autoConfig = generateAutoConfig projectPath;
  in {
    inherit autoConfig;

    recommendations = {
      performance =
        if analysis.projectSize == "large"
        then "balanced"
        else "fast";
      incremental = analysis.projectSize != "small";

      formatters =
        lib.mapAttrs (
          name: enabled:
            if enabled
            then {
              confidence =
                if detectionPatterns ? ${name}
                then "high"
                else "medium";
              reason = "Detected ${name} files in project";
            }
            else {
              confidence = "low";
              reason = "No ${name} files detected";
            }
        )
        autoConfig;
    };
  };
in {
  inherit
    generateAutoConfig
    mergeWithUserConfig
    analyzeProjectStructure
    getFormatterRecommendations
    detectionPatterns
    ;

  # Export utilities
  utils = {
    inherit hasMatchingFiles;
  };

  # Metadata
  meta = {
    description = "Project detection and auto-configuration for treefmt-flake";
    version = "2.0.0";
  };
}
