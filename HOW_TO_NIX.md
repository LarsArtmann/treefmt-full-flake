# HOW_TO_NIX

> A pragmatic guide to Nix/Flakes development based on refined architectural principles and battle-tested patterns.

Version: 1.0
Last Updated: March 26, 2026

---

## 1. Core Philosophy

### Principles

- **Dogfooding First** — Use your own tools. If you build a treefmt flake, lint your own code. If you build a formatter validator, follow your own policies. Add a `just dogfood` command to automate self-validation.
- **Pareto Architecture** — 1% effort → 51% impact. Fix infrastructure first (it blocks everything). Target highest-impact violations. Systematic cleanup of remaining items follows naturally.
- **Types as Contracts** — No implicit any. Use strict typing, well-defined schemas, and comprehensive validation. Make impossible states unrepresentable.
- **Generated over Handwritten** — Use code generators (sqlc, templ, NixOS modules) for boilerplate.
- **Plugin Architecture** — Core + hot-reloadable formatter modules for extensibility.
- **Observability Built-In** — Performance tracking, error reporting, and validation diagnostics from day one.
- **Composability First** — Small, focused modules that compose well. Avoid monolithic configurations.
- **Fail Fast, Fail Clear** — Validate early with helpful error messages. Never let cryptic errors reach users.

### The Non-Negotiables

- Files should not exceed 500 lines (split when approaching limit)
- Functions should be focused (< 30 lines, single responsibility)
- No magic strings — extract to named constants or types
- No nested conditionals >3 levels — use early returns or helper functions
- No duplicated code >3 instances — extract to shared library module
- All public functions must have documentation
- All configuration options must have descriptions
- All errors must include actionable messages

### Self-Reflection Checklist

Before completing any work, ask yourself:

| Question                         | Why It Matters                                 |
| -------------------------------- | ---------------------------------------------- |
| What did you forget?             | Incomplete solutions create technical debt     |
| What's stupid that we do anyway? | Legacy patterns often persist without scrutiny |
| What could you have done better? | Continuous improvement requires honesty        |
| Are we building ghost systems?   | Code without integration is waste              |
| Did we create split brains?      | Duplicate type definitions cause drift         |
| Are we in scope creep?           | Focus delivers value                           |
| Did we remove something useful?  | Pruning too aggressively loses value           |
| How are tests doing?             | Untested code is broken code                   |
| Did we reinvent the wheel?       | Established patterns > custom solutions        |
| Is there legacy code to reduce?  | Target for legacy is ZERO                      |

---

## 2. Project Structure

### Recommended Layout

```
project/
├── flake.nix                    # Entry point with all imports
├── flake-module.nix             # Flake module definition
├── lib/
│   ├── default.nix              # Central exports
│   ├── types.nix                # Centralized type definitions
│   ├── config-schema.nix        # Configuration schema
│   ├── config-validation.nix    # Validation utilities
│   ├── security-validation.nix  # Security checks
│   ├── formatter-registry.nix   # Formatter registration
│   ├── error-formatting.nix     # Error formatting utilities
│   └── performance-tracking.nix  # Performance metrics
├── formatters/
│   ├── nix.nix                  # Nix formatter module
│   ├── web.nix                  # Web formatter module
│   └── ...
├── templates/
│   ├── default/
│   └── minimal/
├── tests/
│   ├── integration/
│   └── unit/
├── scripts/
│   └── setup-hooks.sh
└── justfile                     # Developer commands
```

### Module Organization Principles

1. **Single Responsibility** — Each module does one thing well
2. **Circular Dependencies Forbidden** — Use a central `lib/default.nix` to re-export
3. **Public API via Exports** — Only export what's needed; hide internals
4. **Composability** — Small modules that compose into larger configurations

---

## 3. Type Safety

### Centralized Types (`lib/types.nix`)

All types should be defined centrally and imported where needed:

```nix
# lib/types.nix
{lib}: {
  types = {
    # Enum with description
    performanceProfile = lib.types.enum ["fast" "balanced" "thorough"] // {
      description = "Performance optimization profile";
    };

    # Validated string
    fileName = lib.types.str // {
      check = x: !lib.hasInfix "/" x && x != "";
      description = "Must be a filename without directory paths";
    };

    # Composite type
    formatterConfig = lib.types.submodule {
      options = {
        enable = lib.mkOption { ... };
        priority = lib.mkOption { ... };
      };
    };
  };

  # Re-export validation helpers
  validators = { ... };
}
```

### Validation Patterns

```nix
# ❌ BAD: No validation
projectRootFile = lib.types.str;

# ✅ GOOD: Validated type with error message
projectRootFile = lib.types.str // {
  check = x: x != "" && !lib.hasInfix "/" x;
  description = "Must be a non-empty filename without paths";
};

# ✅ BETTER: Custom validator with helpful error
validatedString = validator: description:
  lib.types.str // {
    check = x:
      if lib.isString x && validator x
      then true
      else throw "❌ Invalid value: ${toString x}. ${description}";
  };
```

### Schema Definition (`lib/config-schema.nix`)

```nix
{lib}: let
  types = import ./types.nix {inherit lib;};
in {
  # Project configuration schema
  projectConfigSchema = lib.types.submodule {
    options = {
      projectRootFile = lib.mkOption {
        type = types.types.fileName;
        default = "flake.nix";
        description = "File that marks the project root";
      };
      # ... more options
    };
  };
}
```

---

## 4. Error Handling

### Error Reporting Patterns

```nix
# lib/error-formatting.nix
{lib}:

rec {
  # Format validation errors with context
  formatValidationErrors = errors:
    lib.concatMapStringsSep "\n" (e: "  - ${e}") errors;

  # Create a structured error report
  createErrorReport = { errors, warnings, recommendations }: ''
    ╔══════════════════════════════════════════════════════════════╗
    ║                    VALIDATION REPORT                        ║
    ╚══════════════════════════════════════════════════════════════╝

    ${lib.optionalString (errors != []) ''
      ERRORS (${toString (lib.length errors)}):
      ${formatValidationErrors errors}
    ''}

    ${lib.optionalString (warnings != []) ''
      WARNINGS (${toString (lib.length warnings)}):
      ${formatValidationErrors warnings}
    ''}
  '';

  # Throw with context
  throwWithContext = context: msg:
    throw "❌ ${context}: ${msg}";
}
```

### Validation Functions

```nix
# lib/config-validation.nix
{lib}:

{
  # Validate configuration
  validateConfiguration = cfg: let
    errors = [];
    warnings = [];

    # Check formatters enabled
    formattersEnabled =
      cfg.nix || cfg.web || cfg.python || cfg.shell
      || cfg.rust || cfg.yaml || cfg.markdown || cfg.json;

    errors = errors ++ lib.optionals (!formattersEnabled) [
      "No formatters enabled. Enable at least one formatter."
    ];
  in {
    valid = errors == [];
    inherit errors warnings;
  };
}
```

---

## 5. Security Validation

### Path Security

```nix
# lib/security-validation.nix
{lib}:

{
  # Validate paths are safe (no traversal, no absolute unless allowed)
  securePath = lib.types.str // {
    check = x:
      lib.hasPrefix "./" x
      || lib.hasPrefix "../" x
      || (x != "" && !lib.hasPrefix "/" x);
    description = "Must be a relative path or ./ prefixed";
  };

  # Validate shell arguments (no injection)
  secureShellArg = lib.types.str // {
    check = x: !lib.hasInfix "'" x && !lib.hasInfix ";" x;
    description = "Must not contain shell injection characters";
  };

  # Validate all paths in a config
  validateSecurity = config: {
    errors = [];
    warnings = [];

    # Check for path traversal
    checkPathTraversal = path:
      if lib.hasInfix "../" path
      then ["Path traversal detected: ${path}"]
      else [];

    errors = errors ++ checkPathTraversal config.projectRootFile;
  };
}
```

---

## 6. Performance Optimization

### Performance Profiles

```nix
# lib/performance-tracking.nix
{lib}:

{
  # Performance profile configurations
  profiles = {
    fast = {
      description = "Skip caching for maximum speed";
      incremental.enable = false;
      parallel.maxJobs = 8;
    };

    balanced = {
      description = "Balance speed and thoroughness (recommended)";
      incremental.enable = true;
      parallel.maxJobs = 4;
    };

    thorough = {
      description = "Maximum checking, may be slower";
      incremental.enable = true;
      parallel.maxJobs = 2;
    };
  };

  # Track performance metrics
  trackOperation = name: thunk: let
    startTime = builtins.currentTime;
    result = thunk;
    endTime = builtins.currentTime;
    duration = endTime - startTime;
  in {
    inherit result;
    metrics.duration = duration;
    metrics.operation = name;
  };
}
```

---

## 7. Formatter Registry

### Module Registration

```nix
# lib/formatter-registry.nix
{lib}:

{
  # Registry of all formatter modules
  registry = {
    nix = ./formatters/nix.nix;
    web = ./formatters/web.nix;
    python = ./formatters/python.nix;
    shell = ./formatters/shell.nix;
    rust = ./formatters/rust.nix;
    yaml = ./formatters/yaml.nix;
    markdown = ./formatters/markdown.nix;
    json = ./formatters/json.nix;
    misc = ./formatters/misc.nix;
  };

  # Load formatter by name
  getFormatterModule = name:
    if lib.hasAttr name registry
    then import registry.${name}
    else throw "Unknown formatter: ${name}";

  # Load all enabled formatters
  loadFormatterModules = enabledFormatters:
    lib.filterAttrs (_: v: v != null)
    (lib.mapAttrs (name: _: getFormatterModule name) enabledFormatters);
}
```

---

## 8. Testing Patterns

### Integration Tests

```nix
# tests/integration/validation-tests.nix
{lib, pkgs, treefmt-flake}:

let
  testCase = name: expected: actual: {
    name = name;
    passed = expected == actual;
    message =
      if expected == actual
      then "✓ ${name}"
      else "✗ ${name}: expected ${expected}, got ${actual}";
  };

  runTests = testCases:
    lib.concatMap (t: [t.message]) testCases;
in {
  testRunner = pkgs.writeScriptBin "run-tests" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Running integration tests..."
    ${lib.concatMapStringsSep "\n" (t: t.script) tests}
    echo "All tests passed!"
  '';

  tests = [
    (testCase "nix-formatter" "alejandra" config.nix.formatter)
    # ... more tests
  ];
}
```

---

## 9. Developer Experience

### Justfile Commands

The project uses a comprehensive justfile for developer workflows:

```justfile
# justfile

# List available commands
default:
    @just --list

# Dogfood: Run all self-validation
# This ensures the project follows its own policies
dogfood:
    @echo "═══════════════════════════════════════════════════════════════"
    @echo "  RUNNING SELF-VALIDATION (Dogfood)"
    @echo "═══════════════════════════════════════════════════════════════"
    @echo ""
    @echo "Step 1/4: Checking formatting..."
    @nix fmt -- --fail-on-change
    @echo ""
    @echo "Step 2/4: Running flake checks..."
    @nix flake check
    @echo ""
    @echo "Step 3/4: Running integration tests..."
    @./tests/integration/test-nix-fmt.sh
    @echo ""
    @echo "Step 4/4: Running branching-flow linters on Go code..."
    @branching-flow all ./cmd
    @echo ""
    @echo "═══════════════════════════════════════════════════════════════"
    @echo "  ✓ SELF-VALIDATION PASSED"
    @echo "═══════════════════════════════════════════════════════════════"

# Format all files
format:
    @echo "Formatting all files..."
    @nix fmt

# Check formatting
format-check:
    @nix fmt -- --fail-on-change

# Run flake checks
check: format-check
    @nix flake check

# Run tests
test:
    @./tests/integration/test-nix-fmt.sh

# Run performance benchmarks
benchmark:
    @./tests/performance/measure-performance.sh

# Setup git hooks
setup-hooks:
    @./scripts/setup-hooks.sh
```

### Branching-Flow Integration

This project uses [branching-flow](https://github.com/LarsArtmann/branching-flow) for Go code quality analysis:

- **CONTEXT**: Detects semantic context loss in error handling
- **DUPE**: Finds duplicate struct definitions
- **PHANTOM**: Identifies primitive types that should be phantom types
- **PANIC**: Detects potential panic conditions
- **STRONG-ID**: Finds parameters that should use strong ID types
- **BOOLBLIND**: Analyzes structs with multiple bools that should be bit flags
- **ANTI-PATTERNS**: Detects O(n) structural anti-patterns
- **MIXINS**: Identifies O(n²) mixin composition opportunities

The Go test helpers in `cmd/treefmt-test-helper/` demonstrate these patterns.

### Pre-commit Hook

The pre-commit hook should:

1. Run `nix fmt` on staged files
2. Re-stage any modified files
3. Fail on formatting errors
4. Provide clear error messages

---

## 10. Anti-Patterns to Avoid

### Bad Patterns

```nix
# ❌ BAD: Magic string without explanation
includes = ["*.nix" "*.md"];

# ✅ GOOD: Named constant
let
  nixFiles = "*.nix";
  markdownFiles = "*.md";
in {
  includes = [nixFiles markdownFiles];
}

# ❌ BAD: Deeply nested conditionals
if x then
  if y then
    if z then a else b
  else c
else d;

# ✅ GOOD: Early returns / helper functions
validate = x: y: z:
  if !x then false
  else if !y then false
  else z;

# ❌ BAD: No error context
throw "Invalid value";

# ✅ GOOD: Contextual error
throw "❌ projectRootFile: Must be a filename, got '${value}'";

# ❌ BAD: Monolithic file
# (File with 1000+ lines doing everything)

# ✅ GOOD: Split modules
# lib/types.nix, lib/validation.nix, lib/formatting.nix, etc.
```

---

## 11. Documentation Requirements

### Module Documentation

Every module should have:

```nix
# lib/example.nix
# Module description: What this module does
# Why it exists: The problem it solves
{lib}: let
  # Internal documentation
  internalNote = "Explain complex internals here";
in {
  # Public API with documentation
  publicFunction = ...;  # What it does

  inherit internalNote;  # Export internal docs if needed
}
```

### Option Documentation

```nix
lib.mkOption {
  type = lib.types.str;
  default = "default-value";
  description = "What this option controls and why you might change it";
  example = "example-value";
}
```

---

## 12. Versioning and API Stability

### Semantic Versioning

- **Major** (X.0.0): Breaking changes to public API
- **Minor** (0.X.0): New features, backward compatible
- **Patch** (0.0.X): Bug fixes, backward compatible

### Export Stability

```nix
# lib/default.nix
{lib}: {
  # Stable API - documented and tested
  stable = {
    types = import ./types.nix {inherit lib;};
    validateConfig = import ./config-validation.nix {inherit lib;};
  };

  # Experimental - may change
  experimental = {
    newFeature = ...;
  };

  # Internal - not for external use
  _internal = {
    internals = ...;
  };
}
```

---

## 13. Contributing

### Pull Request Checklist

- [ ] Code follows project structure
- [ ] Types are centralized in `lib/types.nix`
- [ ] All public functions documented
- [ ] All options have descriptions
- [ ] Errors include actionable messages
- [ ] Tests pass: `just dogfood`
- [ ] No magic strings (use constants)
- [ ] No deep nesting (use early returns)
- [ ] No duplicate code (extract to lib/)

---

## 14. Resources

- [NixOS Manual](https://nixos.org/manual/nixpkgs/stable/)
- [Flakes](https://nixos.org/manual/nixos/release-23-05/解释/nix/flakes.html)
- [treefmt-nix](https://github.com/numtide/treefmt-nix)
- [lib/cli](https://github.com/NixOS/nixpkgs/blob/master/lib/cli.nix)

---

_Arte in Aeternum_
