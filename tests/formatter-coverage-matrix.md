# Formatter Coverage Matrix

This document shows which file types are handled by which formatters to identify potential conflicts or gaps.

## Coverage by File Extension

| Extension | Formatter   | Module       | Priority | Notes                  |
| --------- | ----------- | ------------ | -------- | ---------------------- |
| .nix      | alejandra   | nix.nix      | 1        | Primary Nix formatter  |
| .nix      | deadnix     | nix.nix      | 2        | Dead code detection    |
| .nix      | statix      | nix.nix      | 3        | Linting                |
| .js       | biome       | web.nix      | 1        | JavaScript formatting  |
| .jsx      | biome       | web.nix      | 1        | React JSX              |
| .ts       | biome       | web.nix      | 1        | TypeScript             |
| .tsx      | biome       | web.nix      | 1        | React TSX              |
| .css      | biome       | web.nix      | 1        | Stylesheets            |
| .scss     | biome       | web.nix      | 1        | Sass                   |
| .sass     | biome       | web.nix      | 1        | Sass (indented)        |
| .less     | biome       | web.nix      | 1        | Less                   |
| .json     | biome       | web.nix      | 1        | JSON files             |
| .jsonc    | biome       | web.nix      | 1        | JSON with comments     |
| .py       | black       | python.nix   | 1        | Python formatting      |
| .py       | isort       | python.nix   | 2        | Import sorting         |
| .py       | ruff-format | python.nix   | 3        | Fast Python formatter  |
| .sh       | shfmt       | shell.nix    | 1        | Shell formatting       |
| .bash     | shfmt       | shell.nix    | 1        | Bash scripts           |
| .sh       | shellcheck  | shell.nix    | 2        | Shell linting          |
| .bash     | shellcheck  | shell.nix    | 2        | Bash linting           |
| .rs       | rustfmt     | rust.nix     | 1        | Rust formatting        |
| .yaml     | yamlfmt     | yaml.nix     | 1        | YAML formatting        |
| .yml      | yamlfmt     | yaml.nix     | 1        | YAML formatting        |
| .md       | mdformat    | markdown.nix | 1        | Markdown formatting    |
| .proto    | buf         | misc.nix     | 1        | Protocol buffers       |
| .toml     | taplo       | misc.nix     | 2        | TOML formatting        |
| .yml      | actionlint  | misc.nix     | 3        | GitHub Actions linting |
| justfile  | just        | misc.nix     | 4        | Justfile formatting    |

## Potential Issues Identified

1. **JSON Conflict (RESOLVED)**: Previously jsonfmt and biome could both handle JSON files. Now only biome handles JSON.
2. **No conflicts**: All file types have clear formatter ownership with proper priority ordering.

## File Types Without Coverage

The following common file types don't have formatters configured:

- .html (HTML files)
- .xml (XML files)
- .svg (SVG files)
- .sql (SQL files)
- .go (Go files)
- .java (Java files)
- .c/.cpp/.h (C/C++ files)
- .rb (Ruby files)
- .php (PHP files)

This is expected as the flake focuses on the most common languages used in Nix ecosystems.

## Template Coverage

- **minimal**: nix, yaml, markdown
- **default**: nix, web, python, shell, yaml, markdown
- **complete**: nix, web, python, shell, rust, yaml, markdown, misc

## Testing Strategy

1. Each formatter should be tested in isolation to ensure it works correctly
2. Templates should be tested with realistic file examples
3. Formatter conflicts should be prevented by careful priority ordering
4. All formatters should handle empty files gracefully
