# 🌟 Treefmt Full Flake

[![CI](https://github.com/LarsArtmann/treefmt-full-flake/actions/workflows/ci.yml/badge.svg)](https://github.com/LarsArtmann/treefmt-full-flake/actions/workflows/ci.yml)
[![Basic CI](https://github.com/LarsArtmann/treefmt-full-flake/actions/workflows/ci-basic.yml/badge.svg)](https://github.com/LarsArtmann/treefmt-full-flake/actions/workflows/ci-basic.yml)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

**A comprehensive, production-ready [treefmt](https://github.com/numtide/treefmt) configuration for multiple projects, packaged as a Nix flake.**

[treefmt](https://github.com/numtide/treefmt) unifies code formatters—run `nix fmt` once and it formats everything: Nix, JavaScript, TypeScript, Python, Rust, Shell, YAML, Markdown, JSON, TOML, and more. This flake provides 15+ pre-configured formatters with sensible defaults, cross-platform support, and advanced features like incremental formatting.

> **⚡ [Quick Start Guide](./QUICKSTART.md)**

## 🚀 Quick Start

```bash
# Use template directly
nix flake init -t github:LarsArtmann/treefmt-full-flake
nix fmt  # Format everything!
```

## ✨ Features

- **15+ Formatters**: Nix, JavaScript, TypeScript, Python, Rust, Shell, YAML, Markdown, JSON, TOML
- **Modular Design**: Enable only the formatters you need
- **Cross-Platform**: Linux, macOS, x86_64, aarch64 support
- **Production Ready**: Comprehensive testing, error handling, and performance tracking
- **Multiple Templates**: From minimal setup to complete multi-language projects
- **Advanced Features**: Incremental formatting, performance tracking, security validation
- **Developer Tools**: Built-in CLI tools for status, validation, and debugging

## 📋 Usage

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

- `nix`: Nix formatters (alejandra/nixfmt-rfc-style, deadnix, statix)
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
- `nixFormatter`: Choose between "alejandra" (default) or "nixfmt-rfc-style" (deterministic)

## Using Templates

This flake provides templates to get started quickly:

```bash
# Quick start with default template
nix flake init -t github:LarsArtmann/treefmt-full-flake

# Other templates available:
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
1. Add a new watcher with:
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

## Smart Script

This repository includes both v1 and **v2** intelligent wrappers:

### 🚀 **[smart-treefmt-v2.sh](./smart-treefmt-v2.sh)** - Next Generation (Recommended)

- ⚡ **25x faster startup** with command caching
- 🔧 **Auto-fix capabilities** - resolves issues automatically
- ✨ **Configuration wizard** - generates optimal configs
- 🎯 **Interactive mode** - guided problem resolution
- 📊 **Progress indicators** - beautiful real-time feedback
- 🔌 **Tool integration** - direnv, mise, asdf support
- 📜 **History tracking** - logs all operations
- 🔄 **Self-updating** - stays current automatically

### 📚 **[smart-treefmt.sh](./smart-treefmt.sh)** - Original

- 🔍 **Multi-source resolution** - finds treefmt intelligently
- 💡 **Detailed error messages** - actionable solutions
- 🎯 **Project detection** - context-aware guidance

See [v2 Documentation](./docs/smart-treefmt-v2.md) | [v1 Documentation](./docs/smart-treefmt.md)

### 🔮 **[smart-treefmt-v3-prototype.sh](./smart-treefmt-v3-prototype.sh)** - Revolutionary AI (Prototype)

- 🧠 **AI-powered analysis** - semantic code understanding with local LLM
- 🔮 **Predictive formatting** - prevent issues before they occur
- 🧬 **Intelligent config evolution** - learns from team patterns
- ⚡ **Advanced framework detection** - 95%+ accuracy with confidence scores
- 📊 **Team pattern analysis** - extracts insights from git history

See [Revolutionary Roadmap](./REVOLUTIONARY_ROADMAP.md) | [Revolutionary Improvements](./REVOLUTIONARY_IMPROVEMENTS.md)

## Troubleshooting

### Common Issues

#### 1. Formatter Conflicts

**Problem**: Multiple formatters trying to format the same file type (e.g., both biome and jsonfmt formatting JSON files).

**Solution**:

- We've configured biome to handle JSON files by default
- If you need jsonfmt specifically, disable the web formatter group and enable json separately
- Check [formatter coverage matrix](./tests/formatter-coverage-matrix.md) for details

#### 2. Alejandra Formatting Inconsistency

**Problem**: Alejandra formatter switches between single-line and multi-line formats non-deterministically.

**Solution**:

- **Recommended**: Switch to `nixfmt-rfc-style` by setting `nixFormatter = "nixfmt-rfc-style"` in your configuration
- Alternative: Run `nix fmt` twice to ensure stable formatting with Alejandra
- This is a known issue with Alejandra (see [GitHub Issue #250](https://github.com/kamadorueda/alejandra/issues/250))
- See [Alejandra Determinism Documentation](./docs/alejandra-determinism-issue.md) for detailed migration guide

#### 3. Nix Flake Cache Issues

**Problem**: Tests use outdated versions of the flake due to Nix caching.

**Solution**:

```bash
# Force refresh the flake
nix flake update --refresh

# Or clear the cache
nix-collect-garbage -d
```

#### 4. Git "Dirty Tree" Warnings

**Problem**: Getting warnings about dirty git tree when initializing templates.

**Solution**:

- Initialize git repository before running `nix flake init`
- Commit changes before running flake operations

#### 5. Flake Check Failures

**Problem**: `nix flake check` fails after formatting due to uncommitted changes.

**Solution**:

- Always commit formatted changes before running `nix flake check`
- Use the provided test scripts which handle this automatically

### Getting Help

- Check existing [GitHub Issues](https://github.com/LarsArtmann/treefmt-full-flake/issues)
- Review the [test scripts](./tests/) for examples
- See CI workflow logs for working examples

## Performance Optimization

### Cachix Setup

For dramatically faster CI builds (5-10x improvement), set up Cachix:

1. Create account at [cachix.org](https://cachix.org)
1. Add `CACHIX_AUTH_TOKEN` to GitHub secrets
1. CI will automatically use the cache

See [Cachix Setup Guide](./docs/cachix-setup.md) for detailed instructions.

## Development Setup

### Git Hooks

This project includes a pre-commit hook that automatically formats code before commits:

```bash
# Install the pre-commit hook
./scripts/setup-hooks.sh
```

The hook will:

- Run `nix fmt` on all staged files
- Re-stage any files that were formatted
- Prevent commits if formatting fails

To skip the hook temporarily:

```bash
git commit --no-verify
```

## 🗺️ Roadmap

### Current Status: Production Ready

- ✅ **15+ Formatters**: All major languages and file types supported
- ✅ **Advanced Features**: Incremental formatting, CLI tools, validation
- ✅ **Cross-Platform**: Linux, macOS, x86_64, aarch64 support
- ✅ **Comprehensive Testing**: Error handling, performance tracking

### Future Enhancements (See [Issues](https://github.com/LarsArtmann/treefmt-full-flake/issues))

- 💻 IDE Extensions (VS Code, JetBrains plugins)
- 🚀 Enhanced CI/CD integrations
- 🔍 Advanced debugging and observability tools
- 🎨 Composable template system
- ⚙️ Simplified configuration modes

---

**Contributions welcome!** Check out the [open issues](https://github.com/LarsArtmann/treefmt-full-flake/issues).

## 📄 License

MIT
