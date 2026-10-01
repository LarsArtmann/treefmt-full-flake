# Project detection utilities for treefmt-flake
{ lib }:
{
  # Generate recommended configuration. Honest about what is detected:
  # only python and rust are actually detected from marker files; the
  # rest are unconditional recommendations. (A former `patterns` attrset
  # lived here claiming file-glob detection that no function ever used —
  # removed.)
  generateConfig = projectPath: {
    # Unconditional recommendations for most projects
    nix = true;
    markdown = true;
    yaml = true;
    misc = true;
    web = true;
    shell = true;
    json = true;

    # Language-specific formatters based on marker files
    python =
      lib.pathExists (projectPath + "/pyproject.toml") || lib.pathExists (projectPath + "/setup.py");
    rust = lib.pathExists (projectPath + "/Cargo.toml");
  };

  # Merge user config with auto-detected config
  # User settings take precedence
  mergeConfigs = auto: user: lib.mapAttrs (name: autoValue: user.${name} or autoValue) auto;
}
