# Execution Plan - Priority Sorted

## Priority 1: ASAP (High Impact, Low Effort)

### 1.1 Fix Immediate Test Failures ⚡

**Impact**: Tests currently broken
**Effort**: 15 minutes
**Actions**:

- [ ] Fix timeout command for macOS in all test scripts
- [ ] Apply --no-update-lock-file consistently
- [ ] Verify at least one test passes end-to-end

### 1.2 Push Current Work 🚀

**Impact**: Work not saved remotely
**Effort**: 5 minutes
**Actions**:

- [ ] Run full test suite once
- [ ] Commit any remaining changes
- [ ] Push to remote branch
- [ ] Update PR #29

### 1.3 Switch Default to nixfmt-rfc-style 🔄

**Impact**: Solve determinism issues
**Effort**: 10 minutes
**Actions**:

- [ ] Change default in flake-module.nix
- [ ] Update templates
- [ ] Test the change

### 1.4 Create Nix Shell for Test Dependencies 🛠️

**Impact**: Consistent test environment
**Effort**: 20 minutes
**Actions**:

- [ ] Create tests/shell.nix with all test dependencies
- [ ] Include timeout, bc, jq, parallel
- [ ] Update test scripts to use nix-shell

## Priority 2: Soon (High Impact, Medium Effort)

### 2.1 Refactor Test Library 📚

**Impact**: Reduce duplication, improve maintainability
**Effort**: 1 hour
**Actions**:

- [ ] Create tests/lib/common.sh with shared functions
- [ ] Extract timeout wrapper to library
- [ ] Standardize error handling patterns
- [ ] Update all tests to use library

### 2.2 Fix Parallel Test Runner 🏃

**Impact**: 8x faster test runs
**Effort**: 30 minutes
**Actions**:

- [ ] Use Nix-provided GNU parallel
- [ ] Fix array passing in xargs fallback
- [ ] Add proper progress reporting
- [ ] Test on both Linux and macOS

### 2.3 Implement Cachix Push ☁️

**Impact**: 5-10x faster CI
**Effort**: 30 minutes
**Actions**:

- [ ] Add cachix push to successful CI runs
- [ ] Configure proper auth token
- [ ] Test with a small package first

## Priority 3: Can Be Done Later

### 3.1 Type-Safe Test Framework 🦾

**Impact**: Better reliability
**Effort**: 2-3 hours
**Why Later**: Current bash works, this is improvement
**GitHub Issue**: Create issue for "Implement type-safe test framework using Deno/Bun"

### 3.2 Automated Dependency Updates 🔄

**Impact**: Keep dependencies fresh
**Effort**: 1 hour
**Why Later**: Manual updates work fine for now
**GitHub Issue**: Create issue for "Weekly automated flake.lock updates"

### 3.3 Performance Dashboard 📊

**Impact**: Track performance over time
**Effort**: 2 hours
**Why Later**: Basic benchmarking exists
**GitHub Issue**: Create issue for "Create performance tracking dashboard"

### 3.4 Windows Support 🪟

**Impact**: Broader compatibility
**Effort**: 4+ hours
**Why Later**: Not critical for current users
**GitHub Issue**: Create issue for "Add Windows support for templates"

### 3.5 Format Preview Mode 👁️

**Impact**: See changes before applying
**Effort**: 2 hours
**Why Later**: Nice to have, not essential
**GitHub Issue**: Create issue for "Add dry-run/preview mode to formatter"

## Implementation Order

1. **Immediate**: Fix test failures (1.1)
1. **Next**: Push work (1.2)
1. **Then**: Switch formatter default (1.3)
1. **Then**: Create Nix shell (1.4)
1. **After**: Refactor test library (2.1)
1. **Finally**: Fix parallel runner (2.2)
1. **Bonus**: Implement Cachix (2.3)

## Success Metrics

- [ ] All tests pass on both Linux and macOS
- [ ] Test suite runs in < 2 minutes with parallel execution
- [ ] No non-deterministic formatter behavior
- [ ] Changes pushed and PR updated
- [ ] GitHub issues created for future work
