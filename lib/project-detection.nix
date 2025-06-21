{lib}: let
  # Project detection logic for automatic formatter discovery
  # Analyzes project files to determine which formatters should be enabled
  # File patterns that indicate specific project types
  projectIndicators = {
    # Nix projects
    nix = [
      "flake.nix"
      "default.nix"
      "shell.nix"
      "configuration.nix"
    ];

    # Web development projects
    web = [
      "package.json"
      "yarn.lock"
      "package-lock.json"
      "bun.lockb"
      "tsconfig.json"
      "vite.config.js"
      "vite.config.ts"
      "webpack.config.js"
      "next.config.js"
      "nuxt.config.js"
      "svelte.config.js"
    ];

    # Python projects
    python = [
      "pyproject.toml"
      "setup.py"
      "setup.cfg"
      "requirements.txt"
      "Pipfile"
      "poetry.lock"
      "conda.yaml"
      "environment.yml"
    ];

    # Rust projects
    rust = [
      "Cargo.toml"
      "Cargo.lock"
    ];

    # Shell scripting projects
    shell = [
      ".bashrc"
      ".zshrc"
      "install.sh"
      "build.sh"
      "deploy.sh"
    ];

    # Always useful formatters
    yaml = [
      ".github/workflows"
      "docker-compose.yml"
      "docker-compose.yaml"
      ".gitlab-ci.yml"
      "action.yml"
      "action.yaml"
    ];

    # Documentation projects
    markdown = [
      "README.md"
      "CHANGELOG.md"
      "docs/"
      ".mdx"
    ];

    # JSON configuration
    json = [
      ".vscode/settings.json"
      "tsconfig.json"
      "eslint.json"
      ".eslintrc.json"
    ];

    # Miscellaneous tools
    misc = [
      "justfile"
      "Justfile"
      "buf.yaml"
      "buf.gen.yaml"
      ".proto"
    ];
  };

  # Check if any files/directories exist that match the patterns
  checkProjectType = projectPath: patterns: let
    # Convert relative patterns to absolute paths
    absolutePaths =
      map (
        pattern:
          if lib.hasSuffix "/" pattern
          then projectPath + "/${pattern}" # Directory
          else projectPath + "/${pattern}" # File
      )
      patterns;

    # Check if any of the files/directories exist
    hasMatches =
      lib.any (
        path:
          lib.pathExists path
      )
      absolutePaths;
  in
    hasMatches;

  # Check for file extensions in the project
  checkFileExtensions = projectPath: extensions: let
    # This is a simplified check - in practice you'd want to scan the directory
    # For now, we'll assume if the project type is detected by other means,
    # the extensions are likely present
    # TODO: Implement proper directory scanning
    hasExtensions = true; # Placeholder
  in
    hasExtensions;

  # Main detection function
  detectProjectTypes = projectPath: let
    # Check each project type
    detectedTypes =
      lib.mapAttrs (
        typeName: patterns:
          checkProjectType projectPath patterns
      )
      projectIndicators;

    # Always include these if they're generally useful
    alwaysInclude = {
      markdown = true; # Most projects have README.md
      yaml = true; # YAML is common in modern projects
    };

    # Merge detected types with always-included ones
    finalTypes = detectedTypes // alwaysInclude;
  in
    finalTypes;

  # Generate treefmt configuration based on detected types
  generateAutoConfig = projectPath: let
    detectedTypes = detectProjectTypes projectPath;

    # Convert boolean flags to configuration
    autoConfig = lib.filterAttrs (name: enabled: enabled) detectedTypes;
  in
    autoConfig;

  # Smart defaults with user override capability
  mergeWithUserConfig = autoDetected: userConfig: let
    # User config takes precedence over auto-detection
    # But auto-detection provides sensible defaults
    merged = autoDetected // userConfig;

    # Special handling: if user explicitly sets a formatter to false,
    # respect that even if auto-detection would enable it
    respectUserDisables =
      lib.mapAttrs (
        name: value:
          if lib.hasAttr name userConfig && userConfig.${name} == false
          then false
          else value
      )
      merged;
  in
    respectUserDisables;

  # Validation and recommendations
  validateAutoConfig = projectPath: autoConfig: let
    warnings = [];
    recommendations = [];

    # Check for potential issues
    noFormattersWarning =
      if autoConfig == {}
      then ["No formatters auto-detected. You may need to manually enable formatters or check your project structure."]
      else [];

    # Recommend additional formatters based on detected patterns
    webButNoJson =
      if autoConfig.web or false && !(autoConfig.json or false)
      then ["Consider enabling JSON formatters for web projects (package.json, tsconfig.json, etc.)"]
      else [];

    nixButNoShell =
      if autoConfig.nix or false && !(autoConfig.shell or false)
      then ["Consider enabling shell formatters for Nix projects (often have build scripts)"]
      else [];

    allWarnings = warnings ++ noFormattersWarning;
    allRecommendations = recommendations ++ webButNoJson ++ nixButNoShell;
  in {
    warnings = allWarnings;
    recommendations = allRecommendations;
    isValid = allWarnings == [];
  };

  # Helper to create project detection report
  createDetectionReport = projectPath: userConfig: let
    autoDetected = generateAutoConfig projectPath;
    finalConfig = mergeWithUserConfig autoDetected userConfig;
    validation = validateAutoConfig projectPath finalConfig;

    # Format detection summary
    detectionSummary = let
      enabledFormatters = lib.attrNames (lib.filterAttrs (n: v: v) finalConfig);
      autoEnabledFormatters = lib.attrNames (lib.filterAttrs (n: v: v) autoDetected);
      userEnabledFormatters = lib.attrNames (lib.filterAttrs (n: v: v) userConfig);
    in {
      auto = autoEnabledFormatters;
      user = userEnabledFormatters;
      final = enabledFormatters;
    };
  in {
    autoDetected = autoDetected;
    finalConfig = finalConfig;
    validation = validation;
    summary = detectionSummary;

    # Formatted report for display
    formatReport = ''
      🔍 Project Detection Report:

      Auto-detected formatters: ${lib.concatStringsSep ", " detectionSummary.auto}
      User-specified formatters: ${lib.concatStringsSep ", " detectionSummary.user}
      Final enabled formatters: ${lib.concatStringsSep ", " detectionSummary.final}

      ${lib.optionalString (validation.warnings != []) ''
        ⚠️  Warnings:
        ${lib.concatMapStringsSep "\n" (w: "  - ${w}") validation.warnings}
      ''}

      ${lib.optionalString (validation.recommendations != []) ''
        💡 Recommendations:
        ${lib.concatMapStringsSep "\n" (r: "  - ${r}") validation.recommendations}
      ''}
    '';
  };
in {
  inherit
    projectIndicators
    checkProjectType
    detectProjectTypes
    generateAutoConfig
    mergeWithUserConfig
    validateAutoConfig
    createDetectionReport
    ;

  # Export helper functions
  helpers = {
    # Check if specific project type is detected
    isNixProject = projectPath: checkProjectType projectPath projectIndicators.nix;
    isWebProject = projectPath: checkProjectType projectPath projectIndicators.web;
    isPythonProject = projectPath: checkProjectType projectPath projectIndicators.python;
    isRustProject = projectPath: checkProjectType projectPath projectIndicators.rust;

    # Get minimal auto-config (only definitive project types)
    getMinimalAutoConfig = projectPath: let
      detected = detectProjectTypes projectPath;
      # Only include definitive indicators, not the "always include" ones
      definitive =
        lib.filterAttrs (
          name: _:
            name != "markdown" && name != "yaml"
        )
        detected;
    in
      lib.filterAttrs (name: enabled: enabled) definitive;
  };
}
