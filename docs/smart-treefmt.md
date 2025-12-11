# Smart Treefmt - Intelligent Configuration Resolution

`smart-treefmt.sh` is an intelligent wrapper for treefmt that follows the [smart-config principles](https://github.com/LarsArtmann/mono/issues/208) to provide excellent error handling and user guidance.

## Features

### 🔍 Multi-Source Resolution

The script intelligently searches for treefmt in multiple locations:

1. **Nix shell environment** - Checks if you're in a nix develop shell
1. **Nix fmt command** - Preferred for flake-based projects
1. **Nix build result** - `./result/bin/treefmt`
1. **System PATH** - Standard installation
1. **Common locations** - `/usr/local/bin`, Homebrew, Nix profile, etc.

### 🎯 Smart Configuration Detection

Automatically finds treefmt configuration files:

- Explicit `--config-file` argument
- `flake.nix` with treefmt configuration
- `treefmt.toml` or `.treefmt.toml` in current directory
- Searches up the directory tree for config files

### 💡 Intelligent Error Messages

When something goes wrong, you get:

- Clear explanation of what was attempted
- Specific reasons for each failure
- Actionable steps to resolve the issue
- Context-aware suggestions based on your project

### 🚀 Project Type Detection

Automatically detects your project type and provides specific guidance:

- Node.js/npm projects
- Rust/Cargo projects
- Go projects
- Python projects
- Nix/Nix Flake projects

## Usage

```bash
./smart-treefmt.sh [OPTIONS] [TREEFMT_ARGS...]
```

### Options

- `-h, --help` - Show help message
- `-v, --verbose` - Enable verbose output for debugging
- `-n, --dry-run` - Show what would be executed without running it

### Examples

```bash
# Format all files
./smart-treefmt.sh

# Check formatting without making changes
./smart-treefmt.sh --fail-on-change

# Format specific files
./smart-treefmt.sh src/main.rs README.md

# Verbose mode to see what's happening
./smart-treefmt.sh -v

# Dry run to preview the command
./smart-treefmt.sh -n
```

## Error Resolution Examples

### Treefmt Not Found

```
Error: treefmt not found

Attempted to find treefmt in the following locations:
✗ Nix shell environment: not in Nix shell or treefmt not available
✗ 'nix fmt' command: no flake.nix found
✗ Nix build result: ./result/bin/treefmt not found or not executable
✗ System PATH: treefmt command not found
✗ Common location /usr/local/bin/treefmt: not found or not executable

To resolve this issue, you can:

1. If this is a Nix flake project with treefmt-full-flake:
   nix develop  # Enter development shell with treefmt

2. Build treefmt using Nix:
   nix build  # Creates ./result/bin/treefmt

3. Install treefmt globally:
   nix-env -iA nixpkgs.treefmt  # Using Nix
   brew install treefmt          # Using Homebrew (macOS)

4. Use nix run for one-time execution:
   nix run nixpkgs#treefmt
```

### Configuration Not Found

```
⚠️  Warning: No treefmt configuration found

Attempted to find configuration in:
✗ treefmt.toml or .treefmt.toml in current directory
✗ treefmt.toml or .treefmt.toml in parent directories
✗ treefmt configuration in flake.nix

To create a configuration:
1. For Nix flake projects:
   See: https://github.com/LarsArtmann/treefmt-full-flake

2. For traditional projects, create treefmt.toml:
   treefmt --init
```

### Formatting Changes Detected

```
Error: Formatting changes detected (--fail-on-change is enabled)

To fix this:
1. Run without --fail-on-change to apply formatting:
   ./smart-treefmt.sh

2. Or review the changes that would be made:
   ./smart-treefmt.sh --dry-run
```

## Installation

1. **Make it executable:**

   ```bash
   chmod +x smart-treefmt.sh
   ```

1. **Optionally, add to your PATH:**

   ```bash
   # Copy to a directory in your PATH
   cp smart-treefmt.sh ~/.local/bin/smart-treefmt

   # Or create an alias
   alias smart-treefmt='./smart-treefmt.sh'
   ```

1. **Use in your projects:**
   - Copy the script to your project
   - Or reference it from a shared location
   - Or include it in your Nix flake

## Integration with CI/CD

The script is perfect for CI/CD pipelines with its clear exit codes and error messages:

```yaml
# GitHub Actions example
- name: Check formatting
  run: ./smart-treefmt.sh --fail-on-change
```

## Smart Config Principles

This script follows the smart-config principles:

1. **Multi-source resolution** - Checks multiple locations in priority order
1. **Intelligent fallbacks** - Automatically tries alternatives
1. **Detailed error messages** - Shows exactly what was attempted
1. **Actionable solutions** - Provides specific steps to fix issues
1. **Auto-discovery** - Detects installed tools and project types
1. **User-friendly** - Clear, helpful output at every step

## Extending

The script is designed to be extensible. You can:

- Add more search locations for treefmt
- Add project type detection for more languages
- Customize error messages and solutions
- Add integration with other tools

## Contributing

Feel free to submit issues or pull requests to improve the smart resolution logic or add support for more scenarios.

## License

MIT - Same as treefmt-full-flake
