# Alejandra Non-Determinism Issue and nixfmt-rfc-style Migration Guide

## Summary

Alejandra, while popular, has a documented non-determinism issue where formatting the same file multiple times can produce different results. This document explains the issue and provides guidance on migrating to nixfmt-rfc-style, a deterministic alternative that implements the official Nix formatting standard (RFC 166).

## The Non-Determinism Problem

### Issue Description

Alejandra can produce different outputs when run multiple times on the same input file. This is tracked in [GitHub Issue #250](https://github.com/kamadorueda/alejandra/issues/250).

### Example

First run:

```nix
{
  example = with lib;
    mkOption {
      type = types.str;
      default = "value";
    };
}
```

Second run:

```nix
{
  example = with lib; mkOption {
    type = types.str;
    default = "value";
  };
}
```

The formatter may change its decision about line breaks and indentation between runs, typically stabilizing after 2-3 passes.

### Root Cause

The issue stems from Alejandra allowing the input formatting to influence output decisions, creating a feedback loop that prevents deterministic behavior.

### Impact

- **CI/CD Failures**: Formatting checks may fail unexpectedly
- **Developer Frustration**: Files appear "dirty" after formatting
- **Merge Conflicts**: Unnecessary formatting changes in version control
- **Time Waste**: Multiple formatting passes required

## nixfmt-rfc-style: The Solution

### What is nixfmt-rfc-style?

- **Official Standard**: Implements RFC 166, the community-accepted Nix formatting standard
- **Deterministic**: Produces identical output on every run
- **Future-Proof**: Will become the default formatter for Nixpkgs
- **Well-Maintained**: Actively developed by the NixOS team

### Key Advantages

1. **Deterministic Output**: Same input always produces same output
2. **Community Standard**: Follows RFC 166 guidelines
3. **Better Error Recovery**: More robust parsing and formatting
4. **Active Development**: Regular updates and bug fixes

## Migration Guide

### For treefmt-full-flake Users

#### Option 1: Switch to nixfmt-rfc-style (Recommended)

In your `flake.nix`:

```nix
{
  imports = [
    treefmt-full-flake.flakeModule
  ];

  treefmtFlake = {
    nix = true;
    nixFormatter = "nixfmt-rfc-style"; # Switch from alejandra
    # ... other formatters
  };
}
```

#### Option 2: Use Custom Configuration

For more control, you can override the formatter directly:

```nix
{
  perSystem = { pkgs, ... }: {
    treefmt = {
      programs = {
        # Override the default nix formatter
        nixfmt = {
          enable = true;
          package = pkgs.nixfmt-rfc-style;
        };
        # Keep other formatters
        deadnix.enable = true;
        statix.enable = true;
      };
    };
  };
}
```

### Formatting Differences

Be aware that nixfmt-rfc-style formats differently from Alejandra:

#### Function Arguments

```nix
# Alejandra
{pkgs, lib, config, ...}: {
  # content
}

# nixfmt-rfc-style
{
  pkgs,
  lib,
  config,
  ...
}:
{
  # content
}
```

#### Let Expressions

```nix
# Alejandra
let
  x = 1;
  y = 2;
in
  x + y

# nixfmt-rfc-style
let
  x = 1;
  y = 2;
in
x + y
```

#### Lists

```nix
# Alejandra
[
  item1
  item2
  item3
]

# nixfmt-rfc-style
[
  item1
  item2
  item3
]
```

### Migration Steps

1. **Backup Your Code**: Commit all changes before migrating
2. **Update Configuration**: Set `nixFormatter = "nixfmt-rfc-style"`
3. **Format Once**: Run `nix fmt` to reformat all files
4. **Review Changes**: Check the diff to ensure formatting is acceptable
5. **Commit**: Create a single "formatting migration" commit
6. **Update CI**: Ensure CI uses the same formatter configuration

### Handling Large Codebases

For large projects, consider a phased approach:

```nix
{
  # Temporarily disable formatting for certain directories
  treefmt = {
    settings.excludes = [
      "legacy/**"
      "vendor/**"
    ];
  };
}
```

Then gradually include directories as you migrate them.

## Troubleshooting

### Common Issues

1. **Package Not Found**

   ```
   error: attribute 'nixfmt-rfc-style' missing
   ```

   Solution: Update your nixpkgs input to a recent version

2. **Formatting Conflicts**
   If you have custom formatting rules, they may conflict. Review and adjust as needed.

3. **CI Pipeline Failures**
   Ensure all developers and CI systems use the same formatter version.

### Verifying Determinism

Test determinism with:

```bash
# Format twice and compare
nix fmt
cp result formatted1
nix fmt
diff -r formatted1 result
```

With nixfmt-rfc-style, there should be no differences.

## Recommendations

### Immediate Actions

1. **New Projects**: Use nixfmt-rfc-style from the start
2. **Existing Projects**: Plan migration during a low-activity period
3. **CI/CD**: Add determinism checks to prevent regression

### Long-term Strategy

1. **Monitor RFC 166**: Stay updated with official formatting standards
2. **Community Alignment**: Follow Nixpkgs formatting decisions
3. **Tooling Updates**: Keep formatters and treefmt updated

## Additional Resources

- [RFC 166: Nix Formatting](https://github.com/NixOS/rfcs/pull/166)
- [nixfmt-rfc-style Repository](https://github.com/NixOS/nixfmt)
- [Alejandra Issue #250](https://github.com/kamadorueda/alejandra/issues/250)
- [treefmt Documentation](https://github.com/numtide/treefmt)

## Conclusion

While Alejandra has served the community well, its non-determinism issue makes it unsuitable for projects requiring consistent formatting. nixfmt-rfc-style provides a robust, deterministic alternative that aligns with community standards and ensures reliable formatting across all environments.
