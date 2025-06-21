# Flake Lock Management Strategy

This document outlines the consistent strategy for managing `flake.lock` files in the treefmt-full-flake project.

## Overview

Flake locks ensure reproducible builds by pinning exact versions of dependencies. However, they require careful management to balance reproducibility with the need for updates.

## Strategy

### 1. Main Repository Lock File

The main `flake.lock` in the repository root should:

- Be committed to version control
- Be updated regularly (weekly or bi-weekly)
- Be tested thoroughly before committing updates
- Use `nix flake update` for comprehensive updates
- Use `nix flake lock --update-input <input>` for targeted updates

### 2. Test Environment Lock Files

Test environments should handle locks differently:

#### For Template Tests

```bash
# Always start fresh - templates should work with latest dependencies
rm -f flake.lock

# Let Nix create a new lock file
nix flake metadata

# Use --no-update-lock-file to prevent unintended updates
nix fmt --no-update-lock-file
```

#### For Integration Tests

```bash
# Use the repository's lock file as base
cp "$REPO_ROOT/flake.lock" .

# Update only if testing update scenarios
nix flake update --no-registries
```

### 3. CI/CD Lock Management

In CI environments:

```yaml
- name: Use consistent dependencies
  run: |
    # Copy repository lock for consistency
    cp flake.lock tests/

    # Run tests with --no-update-lock-file
    nix fmt --no-update-lock-file
```

### 4. Common Patterns

#### Avoiding "Git tree dirty" warnings

```bash
# Option 1: Commit before operations
git add . && git commit -m "temp" || true

# Option 2: Use --no-update-lock-file
nix flake check --no-update-lock-file

# Option 3: Accept the warning (it's harmless in tests)
nix fmt 2>&1 | grep -v "Git tree.*dirty" || true
```

#### Refreshing stale cache

```bash
# When hitting cache issues
nix flake metadata --refresh

# Force fresh evaluation
nix fmt --recreate-lock-file
```

#### Testing with specific nixpkgs

```bash
# Update to specific nixpkgs revision
nix flake lock --update-input nixpkgs --override-input nixpkgs github:NixOS/nixpkgs/nixos-unstable

# Test with specific commit
nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/abc123def
```

## Best Practices

### DO:

1. **Commit lock file changes separately**

   ```bash
   nix flake update
   git add flake.lock
   git commit -m "chore: Update flake.lock"
   ```

1. **Document why updates were needed**

   ```bash
   git commit -m "chore: Update nixpkgs for nixfmt-rfc-style support

   Required for deterministic Nix formatting"
   ```

1. **Test after updates**

   ```bash
   nix flake update
   ./tests/run-all-tests.sh
   git add flake.lock
   git commit -m "chore: Update dependencies (all tests pass)"
   ```

### DON'T:

1. **Don't mix lock updates with code changes**

   - Keep lock updates in separate commits

1. **Don't update in CI unless testing updates**

   - CI should use committed lock files

1. **Don't ignore lock file conflicts**

   - Resolve conflicts carefully, test thoroughly

## Troubleshooting

### Issue: Old cached version being used

```bash
# Solution 1: Refresh metadata
nix flake metadata --refresh

# Solution 2: Clear and recreate
rm flake.lock
nix flake update

# Solution 3: Garbage collect and retry
nix-collect-garbage -d
nix flake update
```

### Issue: Lock file conflicts in PR

```bash
# Rebase on main and regenerate
git fetch origin main
git rebase origin/main
nix flake update
git add flake.lock
git rebase --continue
```

### Issue: Different behavior locally vs CI

```bash
# Ensure using same lock file
diff flake.lock .github/workflows/flake.lock

# Check nixpkgs revision
nix flake metadata --json | jq '.locks.nodes.nixpkgs.locked.rev'
```

## Update Schedule

1. **Weekly**: Automated PR with dependency updates
1. **Before Release**: Manual update and full test
1. **Security**: Immediate update for security fixes
1. **On-demand**: When new features are needed

## Implementation in Tests

### Template Test Pattern

```bash
#!/usr/bin/env bash
# ... test setup ...

# Initialize template
nix flake init -t "$TEMPLATE"

# Create lock file without updating registry
nix flake metadata --no-registries

# Run formatter without updating
nix fmt --no-update-lock-file
```

### Formatter Test Pattern

```bash
#!/usr/bin/env bash
# ... test setup ...

# Copy consistent lock file
cp "$REPO_ROOT/tests/reference-flake.lock" flake.lock

# Run tests with lock file
nix fmt --no-update-lock-file
```

## Summary

The key to flake lock management is consistency:

1. Main repo: Keep updated, commit changes
1. Tests: Start fresh or copy from main
1. CI: Use committed locks, no updates
1. Always use `--no-update-lock-file` in automated contexts
