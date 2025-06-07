# Alternative Solutions Analysis

## Problem Statement
Two branches (main and master) with no common history:
- Main: Better formatter defaults, simpler API
- Master: Advanced features, cleaner naming, active development

## Solution Options

### Option 1: Full Merge (Current Plan)
**Approach**: Create unified branch combining both
**Pros**:
- Preserves full history and attribution
- Most comprehensive solution
- Clear migration path for both user bases
**Cons**:
- Complex implementation (~5 hours)
- Risk of introducing bugs
- Requires careful testing

### Option 2: Cherry-Pick Formatter Options
**Approach**: Simply add main's formatter options to master
**Pros**:
- Quick implementation (~30 minutes)
- Minimal risk
- Maintains current master momentum
**Cons**:
- Loses main branch history
- No acknowledgment of main's contributions

### Option 3: Configuration Module
**Approach**: Create a separate `formatter-defaults.nix` module
**Pros**:
- Clean separation of concerns
- Easy to maintain and update
- Can be optional/toggleable
**Cons**:
- Adds complexity to module structure
- May confuse users about where to configure

### Option 4: Documentation-Only
**Approach**: Document recommended formatter options in README
**Pros**:
- Zero code changes
- Users can copy-paste what they need
- Maximum flexibility
**Cons**:
- Not DRY (Don't Repeat Yourself)
- Users might miss important defaults
- Goes against "smart defaults" philosophy

## Recommendation: Modified Option 2

Instead of a complex merge, take the pragmatic approach:

1. **Add formatter options to master** (30 mins):
   ```nix
   # formatters/shell.nix
   options = ["-i" "2" "-s" "-w"];
   
   # formatters/markdown.nix  
   extraOptions = ["--number"];
   ```

2. **Create CREDITS.md** (10 mins):
   ```markdown
   # Credits
   
   ## Formatter Defaults
   The thoughtful formatter configurations were originally 
   developed in the main branch by Lars Artmann.
   ```

3. **Update README.md** (20 mins):
   - Add section explaining the formatter defaults
   - Show how to override them if needed

4. **Archive main branch** (5 mins):
   ```bash
   git tag archive/main origin/main
   git push origin :main  # Delete remote main
   ```

**Total time**: ~1 hour vs 5 hours for full merge

## Why This Is Better

1. **Pragmatic**: Gets the value without the complexity
2. **Fast**: Can be done immediately
3. **Safe**: Minimal risk of breaking existing users
4. **Clean**: No complex git history to maintain
5. **Forward-looking**: Focus on future development

## Implementation Commands

```bash
# 1. Ensure we're on master
git checkout master

# 2. Add formatter options (edit files)
# ... implement changes ...

# 3. Commit with attribution
git commit -m "feat: Add smart formatter defaults from main branch

These thoughtful defaults were originally developed in the main branch:
- Shell: 2-space indent, simplify code  
- Markdown: Numbered headings
- CSS: 100-char width for Tailwind
- YAML: Preserve formatting
- Python: mypy integration

Co-authored-by: Lars Artmann <git@lars.software>"

# 4. Tag and archive main
git tag -a archive/main origin/main -m "Archive: Original main branch with formatter defaults"
git push origin archive/main

# 5. Update default branch on GitHub
# (via GitHub UI: Settings → Branches → Default branch → master)
```

## Conclusion

The full merge is technically elegant but practically overkill. The simple approach achieves 95% of the value with 20% of the effort.