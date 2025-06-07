# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **treefmt-full-flake**, a comprehensive Nix flake that provides modular, reusable code formatting configurations using treefmt. The project serves as a centralized formatter hub that other Nix-based projects can import to standardize code formatting across multiple languages.

## Architecture

### Core Components

1. **Main Flake** (`flake.nix`): Exports the flakeModule, individual formatterModules, and project templates
2. **Flake Module** (`flake-module.nix`): Provides boolean options to enable/disable formatter groups with configuration settings
3. **Formatter Modules** (`formatters/`): Language-specific formatter configurations organized by domain
4. **Templates** (`templates/`): Three pre-configured project templates (minimal, default, complete)

### Formatter Organization

Formatters are grouped by language/domain in the `formatters/` directory:

- `nix.nix`: alejandra, deadnix, statix
- `web.nix`: biome for JS/TS/CSS
- `python.nix`: black, isort, ruff-format
- `shell.nix`: shfmt, shellcheck
- `rust.nix`: rustfmt
- `yaml.nix`: yamlfmt
- `markdown.nix`: mdformat
- `json.nix`: jsonfmt
- `misc.nix`: buf, taplo, actionlint, just

Each formatter module follows priority-based execution to prevent conflicts.

## Common Development Commands

### Primary Commands

```bash
# Format all files in the project
nix fmt

# Check formatting without making changes (CI-friendly)
nix fmt -- --check

# Enter development shell with formatters available
nix develop
```

### Template Usage

```bash
# Initialize new project with default template
nix flake init -t github:user/treefmt-full-flake

# Use minimal template (nix, markdown, yaml only)
nix flake init -t github:user/treefmt-full-flake#minimal

# Use complete template (all formatters enabled)
nix flake init -t github:user/treefmt-full-flake#complete
```

### Integration Testing

```bash
# Test the flake module locally
nix flake check

# Build and test specific formatter modules
nix build .#formatterModules.nix
nix build .#formatterModules.web
```

## Configuration Pattern

Projects integrate this flake by:

1. Adding to flake inputs with nixpkgs following
2. Importing the flakeModule
3. Configuring `treefmtFlake.*` boolean options to enable desired formatter groups
4. Optionally setting `projectRootFile`, `enableDefaultExcludes`, and `allowMissingFormatter`

## Key Design Principles

- **Modular**: Each formatter group is optional and self-contained
- **Reusable**: Single source of truth for formatting rules across projects
- **Flexible**: Template-based quick starts with selective enablement
- **Maintainable**: Centralized updates benefit all consuming projects

## Development Notes

When adding new formatters:

1. Create or extend appropriate file in `formatters/`
2. Follow priority-based execution pattern
3. Add option to `flake-module.nix`
4. Test with `nix flake check`
5. Update templates if formatter is commonly needed

When updating templates:

- `minimal`: Essential formatters only (nix, markdown, yaml)
- `default`: Common multi-language setup with justfile
- `complete`: All formatter groups enabled
