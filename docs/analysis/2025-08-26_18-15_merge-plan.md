# Merge Plan: Combining the Best of Main and Master

## Executive Summary

Merge master's advanced features with main's thoughtful formatter configurations to create the ultimate treefmt configuration.

## What to Keep from Each Branch

### From Master (Power Features)

- ✅ Incremental formatting system (10-100x performance)
- ✅ JetBrains IDE integration
- ✅ Performance profiles (fast/balanced/thorough)
- ✅ Git-based change detection
- ✅ Cleaner API names (nix vs enableNix)
- ✅ Comprehensive documentation (CLAUDE.md, INCREMENTAL.md)
- ✅ MCP configuration

### From Main (Smart Defaults)

- ✅ All formatter-specific options:
  - Shell: 2-space indent, simplify code
  - Markdown: Numbered headings
  - CSS: Separate config with 100-char width
  - YAML: Respect gitignore, preserve formatting
  - Python: mypy integration
  - TOML: Format command
- ✅ Better module architecture pattern
- ✅ "treefmt-full-flake" name (more descriptive)

## Implementation Steps

### Step 1: Create New Unified Branch

```bash
git checkout -b unified origin/master
```

### Step 2: Cherry-Pick Formatter Configurations

Apply the formatter options from main as configurable defaults:

```nix
# Example for shell formatter
shellOptions = lib.mkOption {
  type = lib.types.listOf lib.types.str;
  default = ["-i" "2" "-s" "-w"];
  description = "Options for shfmt";
};
```

### Step 3: Add Configuration Options

Make formatter options configurable while preserving main's defaults:

```nix
treefmtFlake = {
  # Existing options...

  # Formatter-specific options
  formatterOptions = {
    markdown = {
      numberHeadings = lib.mkEnableOption "Number markdown headings" // { default = true; };
    };
    shell = {
      indentSize = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "Shell script indentation size";
      };
    };
    css = {
      printWidth = lib.mkOption {
        type = lib.types.int;
        default = 100;
        description = "CSS line width (useful for Tailwind)";
      };
    };
    python = {
      enableTypeChecking = lib.mkEnableOption "Enable mypy type checking";
    };
  };
};
```

### Step 4: Update Templates

Include examples of both simple usage and advanced configuration:

```nix
# Simple (uses smart defaults)
treefmtFlake = {
  nix = true;
  web = true;
  python = true;
};

# Advanced (custom configuration)
treefmtFlake = {
  nix = true;
  web = true;
  python = true;

  formatterOptions.shell.indentSize = 4;
  formatterOptions.python.enableTypeChecking = true;

  incremental.enable = true;
  performance = "fast";
};
```

### Step 5: Restore Module Architecture

Adopt main's cleaner import pattern in flake-module.nix:

```nix
{
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  # ...
}
```

### Step 6: Update Documentation

- Add section on formatter defaults and customization
- Explain the philosophy of smart defaults
- Show examples of overriding defaults

## Benefits of This Approach

1. **Best of Both Worlds**: Power features + smart defaults
1. **Beginner Friendly**: Works great out of the box
1. **Power User Ready**: Full customization available
1. **Migration Path**: Easy for both main and master users
1. **Future Proof**: Extensible architecture for new formatters

## Migration Guide

### For Main Users

```nix
# Old (main)
treefmtFlake = {
  enableNix = true;
  enableWeb = true;
};

# New (unified)
treefmtFlake = {
  nix = true;
  web = true;
  # All your formatter options are preserved as defaults!
};
```

### For Master Users

```nix
# No changes needed - just gain new formatter defaults
# Can disable if desired:
treefmtFlake = {
  nix = true;
  formatterOptions.markdown.numberHeadings = false;
};
```

## Timeline

1. Create unified branch (immediate)
1. Port formatter configurations (1 hour)
1. Add configuration options (2 hours)
1. Update templates and docs (1 hour)
1. Test thoroughly (1 hour)
1. Create PR for review (immediate after)

Total estimated time: ~5 hours of focused work
