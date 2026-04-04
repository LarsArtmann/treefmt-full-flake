# Contributing to treefmt-full-flake

Thank you for your interest in contributing to treefmt-full-flake! This document provides guidelines and information for contributors.

## Quick Start

1. **Fork the repository** on GitHub
1. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/treefmt-full-flake.git
   cd treefmt-full-flake
   ```
1. **Enter the development environment**:
   ```bash
   nix develop
   ```
1. **Make your changes** and test them
1. **Submit a pull request**

## Development Environment

This project uses Nix flakes for reproducible development environments.

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [Git](https://git-scm.com/)

### Setup

```bash
# Enter development shell with all tools available
nix develop

# Format all files (test that formatting works)
nix fmt

# Check formatting without making changes
nix fmt -- --check

# Validate flake configuration
nix flake check
```

## Project Structure

```
treefmt-full-flake/
├── flake.nix              # Main flake configuration
├── flake-module.nix       # Flake-parts module implementation
├── modules/
│   └── options.nix       # Module option definitions
├── lib/                   # Library functions
│   ├── default.nix       # Library exports
│   └── project-detection.nix  # Auto-detection utilities
├── formatters/            # Language-specific formatter modules
│   ├── nix.nix           # Nix formatters (alejandra, deadnix, statix)
│   ├── nix-nixfmt.nix    # Nix formatters using nixfmt-rfc-style
│   ├── web.nix           # Web formatters (biome for JS/TS/CSS)
│   ├── python.nix        # Python formatters (black, isort, ruff)
│   └── ...               # Other language formatters
├── templates/             # Project templates
│   ├── minimal/          # Essential formatters only
│   ├── default/          # Common multi-language setup
│   ├── complete/         # All formatter groups enabled
│   └── local-development/# Self-contained template
└── docs/                 # Documentation and guides
```

## Making Changes

### Adding New Formatters

1. **Create or extend** the appropriate file in `formatters/`
1. **Follow the priority-based execution pattern** to prevent conflicts
1. **Add configuration options** to `modules/options.nix` (if user-facing)
1. **Wire up in** `flake-module.nix` (if new formatter category)
1. **Test with** `nix flake check`
1. **Update templates** if the formatter is commonly needed

Example formatter module structure:

```nix
# formatters/my-language.nix
{
  programs = {
    myformatter = {
      enable = true;
      # configuration here
    };
  };
}
```

### Updating Templates

- **minimal**: Essential formatters only (nix)
- **default**: Common multi-language setup with devShell
- **complete**: All formatter groups enabled with full configuration
- **local-development**: Self-contained template that works offline

### Code Style

- Follow existing patterns in the codebase
- Use descriptive variable names
- Comment complex logic
- Keep functions focused and small
- Test your changes with `nix flake check`

## Testing

### Basic Testing

```bash
# Validate flake structure
nix flake check

# Test formatting on sample files
nix fmt

# Test specific formatter modules
nix build .#formatterModules.nix
nix build .#formatterModules.web
```

### Testing Templates

```bash
# Test template creation
cd /tmp
nix flake init -t /path/to/treefmt-full-flake
nix flake check
nix fmt
```

### Integration Testing

Test your changes with a real project:

1. Create a test directory with sample files
1. Initialize with your modified template
1. Run formatting and verify results
1. Check that all enabled formatters work correctly

## Submitting Changes

### Pull Request Process

1. **Create a feature branch** from main:

   ```bash
   git checkout -b feature/my-improvement
   ```

1. **Make your changes** following the guidelines above

1. **Test thoroughly**:

   ```bash
   nix flake check
   nix fmt
   # Test with sample projects
   ```

1. **Commit with clear messages**:

   ```bash
   git add .
   git commit -m "feat: add support for new language formatter"
   ```

1. **Push to your fork**:

   ```bash
   git push origin feature/my-improvement
   ```

1. **Create a pull request** on GitHub

### Pull Request Guidelines

- **Clear title** describing the change
- **Detailed description** explaining what and why
- **Reference any related issues**
- **Include test results** if applicable
- **Keep changes focused** - one feature per PR

### Commit Message Format

Use conventional commits format:

- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `refactor:` for code refactoring
- `test:` for test additions/changes
- `chore:` for maintenance tasks

## Getting Help

- **Questions**: Open a GitHub issue with the "question" label
- **Bugs**: Open a GitHub issue with the "bug" label
- **Feature requests**: Open a GitHub issue with the "enhancement" label
- **Discussions**: Use GitHub Discussions for general topics

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## License

By contributing to treefmt-full-flake, you agree that your contributions will be licensed under the MIT License.
