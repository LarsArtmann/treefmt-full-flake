# Alejandra Non-Determinism Analysis and nixfmt-rfc-style Evaluation

## Executive Summary

Research confirms that Alejandra has a known non-determinism issue where formatting the same file multiple times can produce different results. This is documented in [GitHub Issue #250](https://github.com/kamadorueda/alejandra/issues/250). The formatter typically converges to a stable state after the second pass, but this behavior is problematic for CI/CD pipelines and automated formatting workflows.

## The Alejandra Non-Determinism Issue

### Problem Description

Alejandra can produce different formatting results when run multiple times on the same file. The issue manifests as follows:

1. **First run**: Applies initial formatting based on the input structure
2. **Second run**: May apply slightly different formatting, particularly around function arguments and indentation
3. **Subsequent runs**: Usually stabilizes after the second pass

### Example Case

```nix
# Original input
rec {
  flakeApps =
    lib.mapAttrs (appName: app:
      {
        type = "app";
        program = b.toString app.program;
      }
    ) apps;
}

# After first format
rec {
  flakeApps = lib.mapAttrs (
    appName: app: {
      type = "app";
      program = b.toString app.program;
    }
  )
  apps;
}

# After second format (final stable state)
rec {
  flakeApps =
    lib.mapAttrs (
      appName: app: {
        type = "app";
        program = b.toString app.program;
      }
    )
    apps;
}
```

### Root Cause

The non-determinism stems from Alejandra allowing the input formatting to influence the output formatting. This is a design choice that enables more flexible formatting but introduces this stability issue.

### Current Status

- The issue is labeled as "ready" and "help wanted" in the Alejandra repository
- The maintainer acknowledges this is a known issue
- No fix has been implemented as of the latest available information

## nixfmt-rfc-style as an Alternative

### Overview

`nixfmt-rfc-style` is the official Nix formatter implementing RFC 166, which establishes the standardized formatting for Nix code. It's designed to be the future standard formatter for Nixpkgs and the broader Nix ecosystem.

### Key Advantages

1. **Official Standard**: Implements RFC 166, making it the community-approved formatting standard
2. **Active Development**: Actively maintained by the NixOS team
3. **Deterministic Output**: Designed to produce consistent output on repeated runs
4. **Future-proof**: Will become the default formatter for Nixpkgs

### Comparison with Alejandra

| Feature              | Alejandra                       | nixfmt-rfc-style            |
| -------------------- | ------------------------------- | --------------------------- |
| Determinism          | Known issues with multiple runs | Designed for consistency    |
| Configuration        | Not configurable (opinionated)  | Follows RFC 166 standard    |
| Speed                | Claims to be fastest            | Reasonable performance      |
| Semantic Correctness | Claims semantic correctness     | RFC-compliant               |
| Community Standard   | Popular but unofficial          | Official RFC implementation |
| Maintenance          | Individual maintainer           | NixOS team                  |

## Implementation in treefmt-full-flake

### Option 1: Replace Alejandra with nixfmt-rfc-style

Create a new version of `formatters/nix.nix`:

```nix
{
  # Official Nix formatter following RFC 166
  nixfmt = {
    enable = true;
    package = pkgs.nixfmt-rfc-style;
    includes = ["**/*.nix"];
    priority = 1; # Run first
  };

  # Nix dead code eliminator
  deadnix = {
    enable = true;
    includes = ["**/*.nix"];
    priority = 2; # Run after nixfmt
  };

  # Nix linter
  statix = {
    enable = true;
    includes = ["**/*.nix"];
    priority = 3; # Run after nixfmt and deadnix
  };
}
```

### Option 2: Provide Both Formatters as Options

Modify `flake-module.nix` to allow users to choose between formatters:

```nix
{
  options.treefmtFlake = {
    nixFormatter = mkOption {
      type = types.enum ["alejandra" "nixfmt-rfc-style"];
      default = "nixfmt-rfc-style";
      description = "Which Nix formatter to use";
    };

    # ... existing options ...
  };

  config = {
    treefmt.programs = mkMerge [
      (mkIf (cfg.nixFormatter == "alejandra" && cfg.nix) {
        alejandra = import ./formatters/nix-alejandra.nix;
      })
      (mkIf (cfg.nixFormatter == "nixfmt-rfc-style" && cfg.nix) {
        nixfmt = {
          enable = true;
          package = pkgs.nixfmt-rfc-style;
          includes = ["**/*.nix"];
        };
      })
      # ... rest of configuration ...
    ];
  };
}
```

### Option 3: Workaround for Alejandra

If you must use Alejandra, implement a double-format workaround:

```bash
#!/usr/bin/env bash
# alejandra-deterministic.sh
# Run alejandra twice to ensure deterministic output

alejandra "$@"
alejandra "$@"
```

Then configure treefmt to use this wrapper script.

## Recommendations

1. **Primary Recommendation**: Switch to `nixfmt-rfc-style` as the default Nix formatter

   - It's the official standard
   - Avoids non-determinism issues
   - Future-proof for Nixpkgs contributions

2. **Migration Path**:

   - Update `formatters/nix.nix` to use nixfmt-rfc-style
   - Update documentation to explain the change
   - Consider providing both options during a transition period

3. **For Existing Alejandra Users**:
   - Document the non-determinism issue
   - Provide the double-format workaround
   - Encourage migration to nixfmt-rfc-style

## Conclusion

While Alejandra has been a popular choice for Nix formatting, its non-determinism issue makes it unsuitable for reliable, automated formatting workflows. The nixfmt-rfc-style formatter, being the official RFC 166 implementation, provides a more stable and future-proof solution. The treefmt-full-flake project should transition to nixfmt-rfc-style as the default Nix formatter while potentially offering Alejandra as an alternative for users who specifically need it.
