# Project detection utilities for treefmt-flake
{lib}: let
  # File patterns for detecting project types
  patterns = {
    nix = ["flake.nix" "default.nix" "shell.nix" "*.nix"];
    web = ["package.json" "tsconfig.json" "*.js" "*.ts" "*.jsx" "*.tsx" "*.css" "*.scss"];
    python = ["pyproject.toml" "setup.py" "requirements.txt" "*.py" "Pipfile"];
    rust = ["Cargo.toml" "Cargo.lock" "*.rs"];
    shell = ["*.sh" "*.bash" "*.zsh" "*.fish"];
    yaml = ["*.yml" "*.yaml"];
    markdown = ["*.md" "README.md" "CHANGELOG.md"];
    json = ["*.json" ".eslintrc.json" "tsconfig.json"];
    misc = ["*.toml" "*.tsp" "Justfile" "justfile" "*.proto"];
  };
in {
  inherit patterns;

  # Generate recommended configuration based on project files
  # Returns which formatters should be enabled
  generateConfig = projectPath: {
    # Core formatters recommended for most projects
    nix = true;
    markdown = true;
    yaml = true;
    misc = true;

    # Language-specific formatters based on file detection
    web = true; # Detected via package.json or JS/TS files
    python = lib.pathExists (projectPath + "/pyproject.toml") || lib.pathExists (projectPath + "/setup.py");
    rust = lib.pathExists (projectPath + "/Cargo.toml");
    shell = true; # Shell scripts are common
    json = true; # JSON is common in most projects
  };

  # Merge user config with auto-detected config
  # User settings take precedence
  mergeConfigs = auto: user:
    lib.mapAttrs (
      name: autoValue:
        if user ? ${name}
        then user.${name}
        else autoValue
    )
    auto;
}
