# Treefmt Full Flake

A reusable [treefmt](https://github.com/numtide/treefmt) configuration for multiple projects, packaged as a Nix flake.

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
    
    # Import the treefmt-full-flake
    treefmt-full-flake = {
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
    # Import the treefmt-full-flake module
    inputs.treefmt-full-flake.flakeModule
  ];
  
  # Configure which formatter groups to enable
  treefmtFlake = {
    enableNix = true;
    enableWeb = true;
    enablePython = true;
    enableShell = true;
    enableYaml = true;
    enableMarkdown = true;
    enableJson = true;
    
    # Configure project root
    projectRootFile = "flake.nix";
    
    # Enable global excludes
    enableGlobalExcludes = true;
    
    # Don't allow missing formatters
    allowMissingFormatter = false;
  };
}
```

### Available Formatter Groups

- `enableNix`: Nix formatters (alejandra, deadnix, statix)
- `enableWeb`: Web formatters (biome for JS/TS/CSS)
- `enablePython`: Python formatters (black, isort, ruff)
- `enableShell`: Shell formatters (shfmt, shellcheck)
- `enableRust`: Rust formatters (rustfmt)
- `enableYaml`: YAML formatters (yamlfmt)
- `enableMarkdown`: Markdown formatters (mdformat)
- `enableJson`: JSON formatters (jsonfmt, jq)
- `enableMisc`: Miscellaneous formatters

### Configuration Options

- `projectRootFile`: File that marks the project root (default: "flake.nix")
- `enableGlobalExcludes`: Enable global excludes for common patterns (default: true)
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

## Adding to Justfile

For projects using [just](https://github.com/casey/just), you can add these commands:

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
