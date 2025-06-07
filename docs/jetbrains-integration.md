# JetBrains IDE Integration for Format-on-Save

This guide shows how to integrate treefmt with JetBrains IDEs (IntelliJ IDEA, WebStorm, PyCharm, GoLand, etc.) for automatic formatting on save.

## Prerequisites

- JetBrains IDE (any variant)
- treefmt-full-flake configured in your project
- Nix installed

## Method 1: File Watcher (Recommended)

File Watchers automatically run treefmt when you save files.

### Step 1: Install File Watchers Plugin

1. Open **Settings/Preferences** (⌘, on macOS, Ctrl+Alt+S on Windows/Linux)
2. Go to **Plugins**
3. Search for "File Watchers"
4. Install the plugin and restart IDE

### Step 2: Create File Watcher for treefmt

1. Open **Settings/Preferences**
2. Go to **Tools → File Watchers**
3. Click **+** to add a new watcher
4. Configure as follows:

```
Name: treefmt
File type: <custom> (or select specific types)
Scope: Project Files
Program: $ProjectFileDir$/result/bin/treefmt
Arguments: $FilePath$
Output paths to refresh: $FilePath$
Working directory: $ProjectFileDir$
```

### Advanced File Watcher Configuration

For better performance with incremental formatting:

```
Name: treefmt (incremental)
File type: <custom>
Scope: Project Files
Program: /usr/bin/env
Arguments: bash -c "cd $ProjectFileDir$ && nix run .#treefmt-fast -- $FilePath$"
Output paths to refresh: $FilePath$
Working directory: $ProjectFileDir$
Environment variables: PATH=/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin
```

### Step 3: Configure File Types

For specific file types, create separate watchers:

#### Nix Files

```
Name: treefmt - Nix
File type: Nix
Scope: Project Files
Program: $ProjectFileDir$/result/bin/treefmt
Arguments: $FilePath$
```

#### JavaScript/TypeScript

```
Name: treefmt - JS/TS
File type: JavaScript files
Scope: Project Files
Program: $ProjectFileDir$/result/bin/treefmt
Arguments: $FilePath$
```

## Method 2: External Tools

External Tools provide more control and can be bound to keyboard shortcuts.

### Step 1: Create External Tool

1. Open **Settings/Preferences**
2. Go to **Tools → External Tools**
3. Click **+** to add a new tool
4. Configure as follows:

```
Name: Format with treefmt
Group: Code Formatting
Description: Format current file with treefmt
Program: $ProjectFileDir$/result/bin/treefmt
Arguments: $FilePath$
Working directory: $ProjectFileDir$
```

### Step 2: Create Keyboard Shortcut

1. Go to **Settings → Keymap**
2. Search for "Format with treefmt"
3. Right-click and choose **Add Keyboard Shortcut**
4. Press your desired key combination (e.g., ⌥⌘L or Ctrl+Alt+L)

### Step 3: Format on Save Macro

Create a macro to format on every save:

1. **Edit → Macros → Start Macro Recording**
2. Press your format shortcut (from Step 2)
3. Press ⌘S (Ctrl+S) to save
4. **Edit → Macros → Stop Macro Recording**
5. Name it "Format and Save"
6. In **Settings → Keymap**, bind ⌘S to "Format and Save"

## Method 3: Save Actions Plugin

For automatic formatting without manual configuration:

### Step 1: Install Save Actions Plugin

1. Go to **Settings → Plugins**
2. Search for "Save Actions"
3. Install the plugin

### Step 2: Configure Save Actions

1. Go to **Settings → Save Actions**
2. Enable "Activate save actions on save"
3. Add custom command:

```
Command: $ProjectFileDir$/result/bin/treefmt $FilePath$
File path regex: .*\.(nix|js|ts|json|md|sh)$
```

## Method 4: Nix Shell Integration

For projects using nix develop:

### Step 1: Configure Shell Path

1. Go to **Settings → Build, Execution, Deployment → Build Tools**
2. Set shell path to: `/usr/bin/env nix develop -c $SHELL`

### Step 2: Create Nix-Aware External Tool

```
Name: treefmt (nix develop)
Program: /usr/bin/env
Arguments: nix develop -c treefmt $FilePath$
Working directory: $ProjectFileDir$
```

## Optimizations for Large Projects

### Use Incremental Formatting

Configure your project with incremental formatting:

```nix
# flake.nix
treefmtFlake = {
  incremental = {
    enable = true;
    mode = "git";
    cache = "./.cache/treefmt";
  };
  performance = "fast";
};
```

### File Watcher Exclusions

Exclude directories to improve performance:

1. In File Watcher settings, click **Advanced Options**
2. Add to "Do not watch" field:
   ```
   node_modules/**
   .git/**
   target/**
   dist/**
   .cache/**
   ```

### Batch Processing

For multiple file saves, create a debounced watcher:

```
Program: /usr/bin/env
Arguments: bash -c "sleep 0.5 && nix run .#treefmt-staged"
Trigger: On file save
Auto-save edited files: false
```

## Troubleshooting

### Watcher Not Triggering

1. Check File Watcher is enabled (checkbox in File Watchers list)
2. Verify file type matches your configuration
3. Check console output: **View → Tool Windows → Event Log**

### Permission Errors

```bash
# Make treefmt executable
chmod +x ./result/bin/treefmt
```

### Path Issues

Use absolute paths or nix commands:

```
Program: /usr/bin/env
Arguments: nix fmt -- $FilePath$
```

### Performance Issues

1. Enable incremental formatting
2. Use `treefmt-fast` command
3. Limit file types in watcher scope
4. Increase IDE memory: **Help → Change Memory Settings**

## Project-Specific Configuration

Add to your project's `.idea/watcherTasks.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="ProjectTasksOptions">
    <TaskOptions isEnabled="true">
      <option name="arguments" value="$FilePath$" />
      <option name="checkSyntaxErrors" value="true" />
      <option name="description" />
      <option name="exitCodeBehavior" value="ERROR" />
      <option name="fileExtension" value="*" />
      <option name="immediateSync" value="false" />
      <option name="name" value="treefmt" />
      <option name="output" value="$FilePath$" />
      <option name="outputFilters">
        <array />
      </option>
      <option name="outputFromStdout" value="false" />
      <option name="program" value="$ProjectFileDir$/result/bin/treefmt" />
      <option name="runOnExternalChanges" value="false" />
      <option name="scopeName" value="Project Files" />
      <option name="trackOnlyRoot" value="false" />
      <option name="workingDir" value="$ProjectFileDir$" />
      <envs />
    </TaskOptions>
  </component>
</project>
```

## Tips and Best Practices

1. **Build treefmt first**: Run `nix build` to create the `result` symlink
2. **Use incremental mode**: Much faster for large projects
3. **Exclude generated files**: Don't watch build outputs
4. **Test with single file**: Verify configuration before enabling globally
5. **Monitor performance**: Use IDE's Activity Monitor

## Alternative: Command Line Integration

For terminal users within JetBrains:

1. Open integrated terminal
2. Use shell aliases:
   ```bash
   alias fmt='nix fmt'
   alias fmts='nix run .#treefmt-staged'
   alias fmtf='nix run .#treefmt-fast'
   ```

## Related Resources

- [File Watchers Documentation](https://www.jetbrains.com/help/idea/using-file-watchers.html)
- [External Tools Documentation](https://www.jetbrains.com/help/idea/external-tools.html)
- [treefmt Documentation](https://github.com/numtide/treefmt)
