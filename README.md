# Treefmt Flake

A reusable [treefmt](https://github.com/numtide/treefmt) configuration for
multiple projects, packaged as a Nix flake.

> **⚡ [Quick Start Guide](./QUICKSTART.md) - Get up and running in 2 minutes!**

## Features

- Preconfigured formatters for various languages and file types
- Modular design allowing selective enabling of formatter groups
- Works across multiple platforms (Linux, macOS, x86_64, aarch64)
- Easy to integrate into existing flake-based projects

## Usage

### Basic Usage

Add the flake to your inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Import the treefmt-flake
    treefmt-flake = {
      url = "github:LarsArtmann/treefmt-full-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Import the flake module and configure which formatter groups to enable:

```nix
{
  imports = [
    # Import the treefmt-flake module
    inputs.treefmt-flake.flakeModule
  ];

  # Configure which formatter groups to enable
  treefmtFlake = {
    nix = true;
    web = true;
    python = true;
    shell = true;
    yaml = true;
    markdown = true;
    json = true;

    # Configure project root
    projectRootFile = "flake.nix";

    # Enable default excludes
    enableDefaultExcludes = true;

    # Don't allow missing formatters
    allowMissingFormatter = false;
  };
}
```

### Available Formatter Groups

- `nix`: Nix formatters (alejandra, deadnix, statix)
- `web`: Web formatters (biome for JS/TS/CSS)
- `python`: Python formatters (black, isort, ruff)
- `shell`: Shell formatters (shfmt, shellcheck)
- `rust`: Rust formatters (rustfmt)
- `yaml`: YAML formatters (yamlfmt)
- `markdown`: Markdown formatters (mdformat)
- `json`: JSON formatters (jsonfmt, jq)
- `misc`: Miscellaneous formatters

### Configuration Options

- `projectRootFile`: File that marks the project root (default: "flake.nix")
- `enableDefaultExcludes`: Enable default excludes for common patterns (default: true)
- `allowMissingFormatter`: Allow missing formatters (default: false)

## Using Templates

This flake provides templates to get started quickly:

```bash
# Create a new project with the default template
nix flake init -t github:LarsArtmann/treefmt-full-flake

# Or use a specific template
nix flake init -t github:LarsArtmann/treefmt-full-flake#minimal
nix flake init -t github:LarsArtmann/treefmt-full-flake#complete
```

## Running Formatters

Once integrated into your project, you can run the formatters with:

```bash
# Format all files
nix fmt

# Check formatting without changing files
nix fmt -- --check
```

### Incremental Formatting (10-100x Faster)

For large codebases, enable incremental formatting for dramatic performance improvements:

```nix
treefmtFlake = {
  # Enable incremental formatting
  incremental = {
    enable = true;
    mode = "git";
    cache = "./.cache/treefmt";
  };
  performance = "balanced";
};
```

Then use specialized commands:

```bash
# Ultra-fast formatting (no cache)
nix run .#treefmt-fast

# Format only staged files
nix run .#treefmt-staged

# Format files changed since commit
nix run .#treefmt-since HEAD~5
```

See [INCREMENTAL.md](./INCREMENTAL.md) for full details.

## Editor Integration

### JetBrains IDEs (IntelliJ, WebStorm, PyCharm, etc.)

Enable automatic format-on-save in JetBrains IDEs:

```bash
# Quick setup (from your project root)
curl -sSL https://raw.githubusercontent.com/LarsArtmann/treefmt-full-flake/master/docs/jetbrains-configs/setup-jetbrains.sh | bash
```

Or manually configure:

1. Install the **File Watchers** plugin
2. Add a new watcher with:
   - Program: `$ProjectFileDir$/result/bin/treefmt`
   - Arguments: `$FilePath$`
   - Trigger: On file save

See [docs/jetbrains-integration.md](./docs/jetbrains-integration.md) for detailed instructions.

### VS Code

_(Coming soon)_

### Neovim

_(Coming soon)_

## Adding to Justfile

For projects using [just](https://github.com/casey/just), you can add these
commands:

```justfile
# Format all files in the repository using Nix
format:
    @echo "Formatting all files..."
    @nix fmt
    @echo "All formatting complete!"

# Check if all files are properly formatted
format-check:
    @echo "Checking formatting..."
    @nix fmt -- --check
```

## Extending

You can extend the configuration by adding your own formatters:

```nix
perSystem = {
  config,
  pkgs,
  ...
}: {
  treefmt.programs = {
    # Add a custom formatter
    my-custom-formatter = {
      enable = true;
      includes = ["**/*.custom"];
      priority = 1;
    };
  };
};
```

## License

MIT
