# Branch Analysis: main vs master

## Summary

The `main` and `master` branches have no common commit history - they were created independently:
- `main`: Single initial commit (1b42cfa) on 2025-05-02 16:33:28
- `master`: Six commits starting from (ec3e965) on 2025-05-02 16:50:47

## Key Differences

### 1. Option Naming Convention
- **main**: Uses `enableNix`, `enableWeb`, `enablePython` etc.
- **master**: Uses `nix`, `web`, `python` etc. (cleaner API)

### 2. Feature Set
- **main**: Basic treefmt configuration
- **master**: Includes:
  - Incremental formatting (10-100x performance improvement)
  - JetBrains IDE integration
  - Performance profiles
  - Git-based change detection
  - Additional documentation (CLAUDE.md, INCREMENTAL.md)
  - Test files

### 3. Configuration Options
- **main**: Uses `enableGlobalExcludes`
- **master**: Uses `enableDefaultExcludes`

### 4. Flake Structure
- **main**: Basic imports
- **master**: Imports both `treefmt-nix.flakeModule` and `./flake-module.nix`

## File Comparison

### Files only in master:
- `.mcp.json` - MCP server configuration
- `CLAUDE.md` - Claude assistant configuration
- `INCREMENTAL.md` - Incremental formatting documentation
- `docs/` directory - JetBrains integration guides
- `flake.lock` - Dependency lock file
- `result` - Nix build symlink
- `test.json`, `test.md` - Test files

### Files in both (but different):
- `README.md` - master has 126 additions, 13 deletions
- `flake-module.nix` - master has 288 additions, 30 deletions (incremental features)
- `flake.nix` - Different imports structure
- Templates - Updated to use new option names

## Merge Strategy Options

### Option 1: Replace main with master (RECOMMENDED)
```bash
# On main branch
git reset --hard origin/master
git push --force-with-lease origin main
```
**Pros:**
- Preserves all development work and features
- Clean option naming convention
- Includes performance improvements and IDE integration
- Active development branch

**Cons:**
- Loses the original main branch history (only 1 commit)
- Requires force push

### Option 2: Cherry-pick commits to main
```bash
# On main branch
git cherry-pick ec3e965 064bb15 7b9ef42 30e652d bb6e663 84eceff
```
**Pros:**
- Preserves main as primary branch
- Selective feature addition

**Cons:**
- Will require resolving conflicts for every commit
- Option naming differences will cause issues
- Complex and error-prone

### Option 3: Create new unified branch
```bash
# Create new branch from master
git checkout -b unified origin/master

# Update option names to match main convention if desired
# Update README and templates
# Commit changes

# Replace both branches
git push --force-with-lease origin unified:main
git push origin unified:master
```
**Pros:**
- Clean start with best of both
- Opportunity to reconcile naming differences

**Cons:**
- Most complex approach
- Requires careful reconciliation

### Option 4: Keep both branches separate
**Pros:**
- No data loss
- Users can choose which to use

**Cons:**
- Confusing for users
- Maintenance burden
- main is significantly outdated

## Recommendation

**Use Option 1: Replace main with master**

Rationale:
1. The master branch contains all features from main plus significant improvements
2. The option naming in master (`nix` vs `enableNix`) is cleaner
3. Only one commit would be lost from main, which is just an initial commit
4. Master has active development with 6 meaningful commits
5. The incremental formatting and IDE integration are valuable features

## Implementation Steps

1. Backup current state:
   ```bash
   git checkout main
   git branch main-backup
   ```

2. Replace main with master:
   ```bash
   git checkout main
   git reset --hard origin/master
   ```

3. Push to remote:
   ```bash
   git push --force-with-lease origin main
   ```

4. Update default branch on GitHub:
   - Go to Settings → Branches
   - Change default branch from main to master (or vice versa)

5. Clean up:
   ```bash
   # After verification, can delete the other branch
   git push origin --delete main  # or master, depending on choice
   ```

## Impact Analysis

### For existing users:
- **main users**: Will need to update option names (enableNix → nix)
- **master users**: No changes needed
- Both benefit from new features if we standardize on master

### For the repository:
- Cleaner history with one active branch
- Clear development path forward
- Eliminates confusion about which branch to use