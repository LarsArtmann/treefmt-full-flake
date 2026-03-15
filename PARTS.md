# PARTS.md

**Analysis Date:** 2026-02-26
**Project:** treefmt-full-flake
**Purpose:** Identify reusable components suitable for extraction as standalone libraries/SDKs

---

## Executive Summary

After comprehensive analysis of the treefmt-full-flake codebase, **5 components** have been identified as candidates for extraction. Unlike the previous `PROJECT_SPLIT_EXECUTIVE_REPORT.md` which focused on splitting the main flake, this analysis focuses on **extracting reusable utilities** from `lib/` that could benefit the broader Nix ecosystem.

### Quick Recommendations

| Component                        | Extraction Value | Recommendation         |
| -------------------------------- | ---------------- | ---------------------- |
| Security Validation Library      | **HIGH**         | Extract                |
| Error Formatting Library         | **HIGH**         | Extract                |
| Configuration Validation Library | **MEDIUM**       | Extract                |
| Performance Tracking Library     | **MEDIUM**       | Keep (niche)           |
| Formatter Registry Pattern       | **LOW**          | Keep (domain-specific) |

---

## Identified Reusable Components

### 1. Security Validation Library

**Source:** `lib/security-validation.nix` (362 lines)

**Purpose:** Comprehensive security validation for Nix configurations including:

- Path traversal prevention
- Shell injection protection
- Secure type definitions
- Allowlist-based validation

**Key Features:**

```nix
# Path traversal prevention
securePath = secureTypes.securePath {
  allowedPrefixes = [ "/project" "/nix/store" ];
  allowAbsolute = false;
};

# Shell injection protection
secureShellArg = secureTypes.secureShellArg {
  allowedPattern = "^[a-zA-Z0-9_\\-\\.]+$";
  maxLength = 256;
};

# Secure file patterns
secureFilePattern = secureTypes.secureFilePattern {
  allowedExtensions = [ ".nix" ".json" ];
  disallowedPatterns = [ ".." "~" ];
};
```

**Dependencies:** None (pure Nix)

**Alternatives:**
| Project | What It Offers | Gap |
|---------|---------------|-----|
| nixpkgs `lib.types.path` | Basic path type | No security validation, no traversal prevention |
| nixpkgs `lib.strings.escapeShellArg` | Shell escaping | Reactive, not proactive type-level protection |
| Community security flakes | Ad-hoc validations | No unified type system |

**Our Value:**

- **Type-level security**: Problems caught at evaluation time, not runtime
- **Comprehensive**: Covers paths, shell args, file patterns in one system
- **Composable**: Can be combined with other types
- **Well-documented errors**: Security violations produce actionable messages

**Extraction Effort:** Low (minimal dependencies, clean interface)

**Recommendation:** **EXTRACT** - High value, fills a genuine gap in the Nix ecosystem. Security validation is universally needed but rarely implemented properly.

---

### 2. Error Formatting Library

**Source:** `lib/error-formatting.nix` (433 lines)

**Purpose:** Rich terminal output formatting for Nix error messages including:

- ANSI color theming
- Box drawing for structured output
- Error context formatting
- Terminal UX helpers

**Key Features:**

```nix
# ANSI color system with theme support
colors = {
  error = "\x1b[31m";
  warning = "\x1b[33m";
  success = "\x1b[32m";
  # ... full palette with semantic naming
};

# Box drawing for structured errors
renderBox = title: content: ''
  ╔══ ${title} ══╗
  ${boxContent content}
  ╚════════════╝
'';

# Contextual error formatting
formatError = error: ''
  ${colors.error}Error:${colors.reset} ${error.message}

  ${formatContext error.context}
  ${formatHint error.hint}
'';
```

**Dependencies:** None (pure Nix)

**Alternatives:**
| Project | What It Offers | Gap |
|---------|---------------|-----|
| nixpkgs `lib.trivial.showOptions` | Basic option display | No colors, no box drawing, no context |
| nix builtins `throw`/`abort` | Raw error throwing | No formatting, no UX consideration |
| External tools (rich, termcolor) | Terminal formatting | Not available in pure Nix evaluation |

**Our Value:**

- **Pure Nix implementation**: Works during evaluation, no external dependencies
- **Semantic colors**: Named by purpose (error, warning, hint) not by color
- **Structured output**: Box drawing creates visual hierarchy
- **Context preservation**: Shows where errors came from, not just what failed
- **Accessibility**: Respects NO_COLOR environment variable

**Extraction Effort:** Low (self-contained, well-documented)

**Recommendation:** **EXTRACT** - Nix error messages are notoriously terse. This library significantly improves developer experience.

---

### 3. Configuration Validation Library

**Source:**

- `lib/config-validation.nix` (384 lines)
- `lib/types.nix` (323 lines, relevant portions)

**Purpose:** Enhanced type system for Nix configurations including:

- `betterEnum`: Enums with helpful error messages and closest-match suggestions
- `validatedString`: Strings with custom validators
- Validation pipelines with structured error collection
- Migration helpers for deprecated options

**Key Features:**

```nix
# betterEnum - suggests closest match on typo
nixFormatter = betterEnum "nixFormatter" {
  values = [ "alejandra" "nixpkgs-fmt" "deadnix" ];
  caseInsensitive = true;
  suggestOnTypo = true;
};
# Typo "alehandra" → "Did you mean 'alejandra'?"

# validatedString - structured validation
gitBranchName = validatedString "gitBranchName" {
  validators = [
    (s: !(lib.hasPrefix "-") || "Cannot start with hyphen")
    (s: !(lib.hasPrefix ".") || "Cannot start with dot")
    (s: lib.stringLength s <= 200 || "Max 200 characters")
  ];
  transform = lib.toLower;
};

# Validation pipeline with error collection
validateConfig = pipeline [
  (checkRequiredFields [ "name" "version" ])
  (checkDeprecatedFields { oldName = "enable"; newName = "enabled"; })
  (checkConstraints { version = isSemver; })
];
```

**Dependencies:** Minimal (uses nixpkgs `lib` for basic operations)

**Alternatives:**
| Project | What It Offers | Gap |
|---------|---------------|-----|
| nixpkgs `lib.types.enum` | Basic enum type | No suggestions on typos, terse errors |
| nixpkgs `lib.types.str` | String type | No validation, no constraints |
| flake-parts options | Module system | No enhanced validation, no error UX |

**Our Value:**

- **Developer-friendly errors**: Suggests corrections, shows context
- **Composable validators**: Chain multiple checks, collect all errors
- **Migration support**: Helps users move from deprecated to new options
- **Type safety at evaluation**: Catches configuration errors early

**Extraction Effort:** Medium (some integration with treefmt-specific types)

**Recommendation:** **EXTRACT** - The `betterEnum` pattern alone is valuable enough. Every Nix flake would benefit from typo suggestions.

---

### 4. Performance Tracking Library

**Source:** `lib/performance-tracking.nix` (408 lines)

**Purpose:** Performance monitoring and benchmarking for Nix operations:

- Timing and benchmarking utilities
- Metrics collection
- Shell helper integration
- Performance profiles

**Key Features:**

```nix
# Performance profiles
profiles = {
  fast = { parallel = true; cacheResults = true; };
  balanced = { parallel = true; cacheResults = false; };
  thorough = { parallel = false; cacheResults = false; };
};

# Timing helpers
timeOperation = name: operation: let
  start = builtins.currentTime;
  result = operation;
  elapsed = builtins.currentTime - start;
in { inherit result elapsed; };

# Metrics collection
collectMetrics = operations: foldl' (acc: op:
  acc // { ${op.name} = measure op; }
) {} operations;
```

**Dependencies:** Minimal

**Alternatives:**
| Project | What It Offers | Gap |
|---------|---------------|-----|
| nix `--show-trace` | Timing info | Not programmatic, no metrics |
| nix `builtins.currentTime` | Basic timing | No aggregation, no profiling |
| External benchmarking tools | Comprehensive | Not integrated with Nix evaluation |

**Our Value:**

- **Programmatic access**: Can use timing data in Nix expressions
- **Profile-based tuning**: Pre-configured performance profiles
- **Shell integration**: Works with treefmt's shell wrapper
- **Metrics aggregation**: Collect and compare performance data

**Extraction Effort:** Medium (some treefmt-specific integration)

**Recommendation:** **KEEP** - Niche use case. Most projects don't need performance tracking at the Nix evaluation level. Better suited as internal utility.

---

### 5. Formatter Registry Pattern

**Source:** `lib/formatter-registry.nix` (224 lines)

**Purpose:** Dynamic formatter module loading and registry management:

- Registry pattern for formatters
- Dynamic module loading
- Formatter priority management
- Dependency resolution

**Key Features:**

```nix
# Registry definition
formatters = {
  alejandra = { priority = 100; includes = [ "*.nix" ]; };
  deadnix = { priority = 50; includes = [ "*.nix" ]; };
  statix = { priority = 25; includes = [ "*.nix" ]; };
};

# Dynamic loading
loadFormatters = enabled:
  map (name: import ./formatters/${name}.nix)
    (attrNames (filterAttrs (_: v: v.enabled) enabled));

# Priority-based execution
sortFormatters = formatters:
  sort (a: b: a.priority > b.priority) formatters;
```

**Dependencies:** High (treefmt-nix integration, formatter-specific logic)

**Alternatives:**
| Project | What It Offers | Gap |
|---------|---------------|-----|
| flake-parts modules | Module system | No priority ordering, no formatter-specific logic |
| treefmt-nix | Formatter config | No dynamic registry, fixed set of formatters |

**Our Value:**

- **Dynamic loading**: Add formatters without modifying core
- **Priority system**: Ensures correct execution order
- **Conflict detection**: Warns about overlapping formatters

**Extraction Effort:** High (deeply integrated with treefmt-nix)

**Recommendation:** **KEEP** - Too domain-specific. The registry pattern is useful but the implementation is tightly coupled to treefmt. Document the pattern instead of extracting.

---

## Additional Considerations

### Components NOT Recommended for Extraction

| Component                   | Reason                                     |
| --------------------------- | ------------------------------------------ |
| `lib/config-schema.nix`     | Treefmt-specific schema, not generalizable |
| `lib/project-detection.nix` | Tied to formatter ecosystem                |
| `lib/default.nix`           | Just an export hub, not a library          |
| All formatters              | Domain-specific, already in treefmt-nix    |
| Templates                   | Project-specific boilerplates              |

### Patterns Worth Documenting

Even if not extracted as libraries, these patterns are worth documenting for community reuse:

1. **betterEnum Pattern** - Enhanced enum with typo suggestions
2. **Secure Type Pattern** - Security at the type level
3. **Error Box Pattern** - Structured error formatting
4. **Validation Pipeline Pattern** - Composable validation chains

---

## Recommended Extraction Path

### Phase 1: Extract High-Value Libraries

Create two new repositories:

```
nix-security-types/
├── flake.nix
├── lib/
│   ├── default.nix      # Export hub
│   ├── paths.nix        # Path traversal prevention
│   ├── shell.nix        # Shell injection protection
│   ├── patterns.nix     # File pattern validation
│   └── types.nix        # secureTypes composition
└── tests/
    └── ...

nix-better-errors/
├── flake.nix
├── lib/
│   ├── default.nix      # Export hub
│   ├── colors.nix       # ANSI color system
│   ├── boxes.nix        # Box drawing
│   ├── format.nix       # Error formatting
│   └── context.nix      # Context helpers
└── tests/
    └── ...
```

### Phase 2: Extract Medium-Value Library

```
nix-better-types/
├── flake.nix
├── lib/
│   ├── default.nix
│   ├── enum.nix         # betterEnum
│   ├── string.nix       # validatedString
│   ├── pipeline.nix     # Validation pipelines
│   └── migration.nix    # Deprecation helpers
└── tests/
    └── ...
```

### Phase 3: Update treefmt-full-flake

After extraction:

1. Add extracted libraries as flake inputs
2. Replace internal implementations with library imports
3. Maintain backwards compatibility via re-exports

---

## Open Questions

1. **Naming conventions**: Should we follow `nix-*` prefix pattern or use distinct names?
2. **Versioning**: How to version libraries independently while maintaining compatibility?
3. **Documentation**: Where to host docs? (GitHub README, mdbook, etc.)
4. **Testing**: How to share test infrastructure between libraries?
5. **Community feedback**: Should we gauge interest before investing in extraction?

---

## Conclusion

The treefmt-full-flake project contains **genuinely reusable components** that would benefit the broader Nix ecosystem. The **Security Validation Library** and **Error Formatting Library** are particularly valuable because:

1. They fill genuine gaps in nixpkgs
2. They have zero external dependencies
3. They provide immediate, tangible UX improvements
4. They're self-contained and easy to extract

The **Configuration Validation Library** (especially `betterEnum`) would be a quality-of-life improvement for any flake author tired of cryptic enum errors.

**Primary Recommendation:** Extract `nix-security-types` and `nix-better-errors` as standalone libraries. These provide the highest value with the lowest extraction effort.

---

_Analysis completed following HOW_TO_GOLANG.md principles: composition over inheritance, explicit over implicit, type safety at boundaries._
