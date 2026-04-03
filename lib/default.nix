# Library functions for treefmt-flake
# Exports commonly used utilities for external consumers
{lib}: {
  # Import formatter modules
  formatterModules = {
    nix = import ../formatters/nix.nix;
    nix-nixfmt = import ../formatters/nix-nixfmt.nix;
    web = import ../formatters/web.nix;
    python = import ../formatters/python.nix;
    shell = import ../formatters/shell.nix;
    rust = import ../formatters/rust.nix;
    yaml = import ../formatters/yaml.nix;
    markdown = import ../formatters/markdown.nix;
    json = import ../formatters/json.nix;
    misc = import ../formatters/misc.nix;
  };

  # Project detection utilities
  projectDetection = import ./project-detection.nix {inherit lib;};

  # Version
  version = "2.0.0";
}
