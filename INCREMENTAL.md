# Incremental Formatting

This flake now includes **incremental formatting** capabilities that provide **10-100x faster formatting** on large codebases by only formatting changed files.

## Features

### 🚀 Performance Profiles

- **fast**: Ultra-fast mode, skips cache (`--no-cache`)
- **balanced**: Default mode with smart caching
- **thorough**: Comprehensive mode with full directory walk (`--walk`)

### 🔧 Git-Based Change Detection

- Format only files changed since main branch
- Format only staged files
- Format files changed since specific commit
- Automatic fallback to full formatting if git detection fails

### 📦 Cache Management

- Configurable cache directory (default: `~/.cache/treefmt`)
- Project-local cache support
- Automatic cache directory creation

## Configuration

```nix
treefmtFlake = {
  # Enable incremental formatting
  incremental = {
    enable = true;
    mode = "git";           # git | cache | auto
    gitBased = true;
    cache = "./.cache/treefmt";
  };

  # Performance profile
  performance = "balanced";  # fast | balanced | thorough

  # Git options
  gitOptions = {
    branch = "main";
    stagedOnly = false;
  };
};
```

## Commands

### Basic Commands

```bash
nix fmt                    # Format all files (incremental when enabled)
nix fmt -- --check        # Check formatting without changes
```

### Incremental Commands

```bash
nix run .#treefmt-fast     # Ultra-fast formatting (no cache)
nix run .#treefmt-staged   # Format only staged files
nix run .#treefmt-since HEAD~5  # Format files changed since 5 commits ago
```

## How It Works

1. **Git Detection**: Uses `git diff` to identify changed files
2. **File Filtering**: Only processes files that exist and match formatter patterns
3. **Smart Fallback**: Falls back to full formatting if git detection fails
4. **Performance Reporting**: Shows execution time, file count, and profile used

## Example Output

```
Formatting 3 changed files...
Files: src/main.rs lib/utils.js docs/README.md
Formatting completed in 0.234s (3 files, balanced profile)
```

## Benefits

- ⚡ **10-100x faster** on large codebases
- 🎯 **Smart change detection** using git
- 🔄 **Automatic fallback** for reliability
- 📊 **Performance reporting** for insights
- 🛠️ **Configurable profiles** for different use cases
- 💾 **Persistent caching** for even better performance
