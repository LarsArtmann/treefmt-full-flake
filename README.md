# 🌟 Treefmt Full Flake

[![CI](https://github.com/LarsArtmann/treefmt-full-flake/actions/workflows/ci.yml/badge.svg)](https://github.com/LarsArtmann/treefmt-full-flake/actions/workflows/ci.yml)
[![Basic CI](https://github.com/LarsArtmann/treefmt-full-flake/actions/workflows/ci-basic.yml/badge.svg)](https://github.com/LarsArtmann/treefmt-full-flake/actions/workflows/ci-basic.yml)
![Status: Private Beta](https://img.shields.io/badge/Status-Private%20Beta-orange)

**A comprehensive, production-ready [treefmt](https://github.com/numtide/treefmt) configuration for multiple projects, packaged as a Nix flake.**

> **🚨 CURRENT STATUS: PRIVATE REPOSITORY**  
> This project is currently in private beta. See [Access Methods](#-access-methods) below for how to use it.

> **⚡ [Quick Start Guide](./QUICKSTART.md) - Multiple access methods explained!**

## 🚀 Access Methods

**Choose the method that works for your situation:**

### 🔑 Method 1: SSH Access (If you have repository access)
```bash
# Use templates directly
nix flake init -t git+ssh://git@github.com/LarsArtmann/treefmt-full-flake

# Or add to your flake.nix inputs
inputs.treefmt-flake.url = "git+ssh://git@github.com/LarsArtmann/treefmt-full-flake.git";
```

### 📁 Method 2: Local Development (Clone first)
```bash
# Clone the repository
git clone git@github.com:LarsArtmann/treefmt-full-flake.git

# Use local template (RECOMMENDED - works immediately!)
nix flake init -t ./treefmt-full-flake#local-development

# Or reference local path in your flake
inputs.treefmt-flake.url = "path:./path/to/treefmt-full-flake";
```

### 🌍 Method 3: Future Public Access
```bash
# When repository becomes public (roadmap item)
nix flake init -t github:LarsArtmann/treefmt-full-flake#local-development
```

### 🎯 Recommended: Self-Contained Template
The `local-development` template works immediately without external dependencies:
```bash
git clone git@github.com:LarsArtmann/treefmt-full-flake.git
nix flake init -t ./treefmt-full-flake#local-development
nix fmt  # Works immediately!
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
    # CURRENTLY PRIVATE REPO - Replace with appropriate access method:
    # For private repo access: url = "git+ssh://git@github.com/LarsArtmann/treefmt-full-flake.git";
    # For local development: url = "path:./path/to/treefmt-full-flake";
    # For future public release: url = "github:LarsArtmann/treefmt-full-flake";
    treefmt-flake = {
      url = "git+ssh://git@github.com/LarsArtmann/treefmt-full-flake.git";
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
# RECOMMENDED: Self-contained template (works immediately!)
git clone git@github.com:LarsArtmann/treefmt-full-flake.git
nix flake init -t ./treefmt-full-flake#local-development

# SSH access (if you have repository access)
nix flake init -t git+ssh://git@github.com/LarsArtmann/treefmt-full-flake

# Other templates available:
nix flake init -t ./treefmt-full-flake#minimal
nix flake init -t ./treefmt-full-flake#complete
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

### Current Status: Private Beta
- ✅ **Production-Ready**: Comprehensive testing, error handling, performance tracking
- ✅ **15+ Formatters**: All major languages and file types supported
- ✅ **Multiple Access Methods**: SSH, local clone, self-contained templates
- ✅ **Advanced Features**: Incremental formatting, CLI tools, validation
- ✅ **Cross-Platform**: Linux, macOS, x86_64, aarch64 support

### Planned: Public Release
**Target**: Q3 2025

**Prerequisites for Public Release:**
- [ ] Security audit and sensitive data review
- [ ] Public CI/CD infrastructure setup
- [ ] Comprehensive end-to-end testing with external users
- [ ] Performance optimization based on usage data
- [ ] Documentation review and user experience testing

**Benefits of Public Release:**
- 🌍 **Universal Access**: `nix flake init -t github:LarsArtmann/treefmt-full-flake`
- 📦 **Flake Registry**: Listed in official Nix flake registry
- 🔄 **Community Contributions**: Open source collaboration
- 📈 **Wider Adoption**: Available to the entire Nix community

### Future Enhancements (See [Issues](https://github.com/LarsArtmann/treefmt-full-flake/issues))
- 💻 IDE Extensions (VS Code, JetBrains plugins)
- 🚀 Enhanced CI/CD integrations
- 🔍 Advanced debugging and observability tools
- 🎨 Composable template system
- ⚙️ Simplified configuration modes

---

**Want to help with the public release?** 
- Try the current access methods and report issues
- Test the self-contained template in your projects  
- Provide feedback on the user experience
- Contribute to the [open issues](https://github.com/LarsArtmann/treefmt-full-flake/issues)

## 📄 License

MIT
