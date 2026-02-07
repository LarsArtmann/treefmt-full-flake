# Nix Formatter Recommendations for treefmt-full-flake

## Problem Summary

Alejandra has a confirmed non-determinism issue ([GitHub Issue #250](https://github.com/kamadorueda/alejandra/issues/250)) where formatting the same file multiple times can produce different results. While the formatter typically converges after the second run, this behavior is problematic for:

- CI/CD pipelines that expect deterministic results
- Git pre-commit hooks that may show false positives
- Automated formatting workflows
- Team collaboration where formatting stability is crucial

## Recommended Solution: Adopt nixfmt-rfc-style

### Why nixfmt-rfc-style?

1. **Deterministic**: Designed to produce consistent output on every run
1. **Official Standard**: Implements RFC 166, the community-approved Nix formatting standard
1. **Future-proof**: Will become the default formatter for Nixpkgs
1. **Well-maintained**: Actively developed by the NixOS team
1. **treefmt-nix support**: Native support in treefmt-nix with easy configuration

### Implementation Strategy

#### Phase 1: Add nixfmt-rfc-style as an Alternative (Immediate)

1. Create a new formatter module `formatters/nix-nixfmt.nix` (already created)
1. Update `flake-module.nix` to support formatter selection:

```nix
# In flake-module.nix, add:
options.treefmtFlake = {
  nixFormatter = mkOption {
    type = types.enum ["alejandra" "nixfmt-rfc-style"];
    default = "alejandra"; # Keep alejandra as default initially
    description = "Which Nix formatter to use. Note: alejandra has known non-determinism issues.";
  };
  # ... existing options ...
};

# In the config section, modify the nix formatter loading:
(mkIf cfg.nix (
  if cfg.nixFormatter == "alejandra"
  then import ./formatters/nix.nix
  else import ./formatters/nix-nixfmt.nix
))
```

#### Phase 2: Document and Communicate (Week 1-2)

1. Update README.md with:

   - Warning about Alejandra's non-determinism
   - Instructions for using nixfmt-rfc-style
   - Migration guide for existing users

1. Add to template configurations showing nixfmt-rfc-style usage

#### Phase 3: Change Default (Week 4)

1. Change the default formatter to nixfmt-rfc-style:

   ```nix
   default = "nixfmt-rfc-style";
   ```

1. Update all templates to use nixfmt-rfc-style by default

### For Users Who Must Use Alejandra

If users have specific requirements for Alejandra (e.g., existing large codebases), provide this workaround:

```nix
# In their flake configuration
treefmt.programs.alejandra = {
  enable = true;
  # Custom wrapper that runs alejandra twice for stability
  package = pkgs.writeShellScriptBin "alejandra-stable" ''
    ${pkgs.alejandra}/bin/alejandra "$@" || exit $?
    ${pkgs.alejandra}/bin/alejandra "$@"
  '';
};
```

## Testing the Solution

### Verify Determinism

Create a test script to verify formatter determinism:

```bash
#!/usr/bin/env bash
# test-formatter-determinism.sh

echo "Testing Nix formatter determinism..."

# Create a test file with complex formatting
cat > test.nix << 'EOF'
rec {
  flakeApps =
    lib.mapAttrs (appName: app:
      {
        type = "app";
        program = b.toString app.program;
      }
    ) apps;
}
EOF

# Format multiple times and compare
nix fmt test.nix
cp test.nix test1.nix
nix fmt test.nix
cp test.nix test2.nix
nix fmt test.nix
cp test.nix test3.nix

# Check if all outputs are identical
if diff -q test1.nix test2.nix > /dev/null && diff -q test2.nix test3.nix > /dev/null; then
  echo "✓ Formatter is deterministic"
  exit 0
else
  echo "✗ Formatter produced different outputs!"
  echo "Differences between runs:"
  diff test1.nix test2.nix || true
  diff test2.nix test3.nix || true
  exit 1
fi
```

## Migration Checklist

- [ ] Add nixfmt-rfc-style formatter module
- [ ] Update flake-module.nix to support formatter selection
- [ ] Document Alejandra's non-determinism issue
- [ ] Create migration examples
- [ ] Test nixfmt-rfc-style with all template configurations
- [ ] Update CI/CD configurations if needed
- [ ] Announce deprecation of Alejandra as default
- [ ] Switch default to nixfmt-rfc-style
- [ ] Update all documentation and examples

## Conclusion

While Alejandra has served the Nix community well, its non-determinism issue makes it unsuitable for modern development workflows that require reproducible formatting. nixfmt-rfc-style, as the official RFC 166 implementation, provides the stability and standardization needed for reliable code formatting. The proposed phased migration allows users time to adapt while providing immediate solutions for those experiencing issues.
