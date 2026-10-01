#!/usr/bin/env bash
# Setup script for JetBrains IDE integration with treefmt

set -euo pipefail

echo "🚀 Setting up JetBrains IDE integration for treefmt..."

# Check if we're in a project with treefmt
if [ ! -f "flake.nix" ]; then
  echo "❌ Error: No flake.nix found. Run this from your project root."
  exit 1
fi

# Build treefmt to ensure result symlink exists
echo "📦 Building treefmt..."
nix build

# Create .idea directory if it doesn't exist
mkdir -p .idea

# Create File Watcher configuration
echo "⚙️ Creating File Watcher configuration..."
cat >.idea/watcherTasks.xml <<'EOF'
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
      <option name="name" value="treefmt - All Files" />
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
    <TaskOptions isEnabled="false">
      <option name="arguments" value="bash -c &quot;cd $ProjectFileDir$ &amp;&amp; nix run .#treefmt-fast -- $FilePath$&quot;" />
      <option name="checkSyntaxErrors" value="true" />
      <option name="description" />
      <option name="exitCodeBehavior" value="ERROR" />
      <option name="fileExtension" value="*" />
      <option name="immediateSync" value="false" />
      <option name="name" value="treefmt - Fast Mode" />
      <option name="output" value="$FilePath$" />
      <option name="outputFilters">
        <array />
      </option>
      <option name="outputFromStdout" value="false" />
      <option name="program" value="/usr/bin/env" />
      <option name="runOnExternalChanges" value="false" />
      <option name="scopeName" value="Project Files" />
      <option name="trackOnlyRoot" value="false" />
      <option name="workingDir" value="$ProjectFileDir$" />
      <envs>
        <env name="PATH" value="/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin" />
      </envs>
    </TaskOptions>
  </component>
</project>
EOF

# Create External Tools configuration
echo "🔧 Creating External Tools configuration..."
mkdir -p .idea/tools
cat >.idea/tools/External_Tools.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="ExternalToolsStorage">
    <tools>
      <tool name="Format with treefmt" description="Format current file with treefmt" showInMainMenu="true" showInEditor="true" showInProject="true" showInSearchPopup="true" disabled="false" useConsole="true" showConsoleOnStdOut="false" showConsoleOnStdErr="false" synchronizeAfterRun="true">
        <exec>
          <option name="COMMAND" value="$ProjectFileDir$/result/bin/treefmt" />
          <option name="PARAMETERS" value="$FilePath$" />
          <option name="WORKING_DIRECTORY" value="$ProjectFileDir$" />
        </exec>
      </tool>
      <tool name="Format staged files" description="Format only git staged files" showInMainMenu="true" showInEditor="false" showInProject="true" showInSearchPopup="true" disabled="false" useConsole="true" showConsoleOnStdOut="false" showConsoleOnStdErr="false" synchronizeAfterRun="true">
        <exec>
          <option name="COMMAND" value="nix" />
          <option name="PARAMETERS" value="run .#treefmt-staged" />
          <option name="WORKING_DIRECTORY" value="$ProjectFileDir$" />
        </exec>
      </tool>
      <tool name="Format changed files (fast)" description="Format changed files in fast mode" showInMainMenu="true" showInEditor="false" showInProject="true" showInSearchPopup="true" disabled="false" useConsole="true" showConsoleOnStdOut="false" showConsoleOnStdErr="false" synchronizeAfterRun="true">
        <exec>
          <option name="COMMAND" value="nix" />
          <option name="PARAMETERS" value="run .#treefmt-fast" />
          <option name="WORKING_DIRECTORY" value="$ProjectFileDir$" />
        </exec>
      </tool>
    </tools>
  </component>
</project>
EOF

# Add to .gitignore if needed
if [ -f .gitignore ]; then
  if ! grep -q "^.idea/workspace.xml" .gitignore; then
    echo "" >>.gitignore
    echo "# JetBrains IDE - User-specific files" >>.gitignore
    echo ".idea/workspace.xml" >>.gitignore
    echo ".idea/tasks.xml" >>.gitignore
    echo ".idea/usage.statistics.xml" >>.gitignore
    echo ".idea/dictionaries" >>.gitignore
    echo ".idea/shelf" >>.gitignore
  fi
fi

echo "✅ JetBrains IDE integration setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open/restart your JetBrains IDE"
echo "2. Install 'File Watchers' plugin if not already installed"
echo "3. Go to Settings → Tools → File Watchers"
echo "4. The 'treefmt - All Files' watcher should be visible and enabled"
echo ""
echo "⚡ Quick tips:"
echo "- File Watcher will auto-format on save"
echo "- Use Tools → External Tools for manual formatting"
echo "- Enable 'treefmt - Fast Mode' watcher for better performance"
echo "- Check Event Log (View → Tool Windows → Event Log) for any issues"
echo ""
echo "📖 Full documentation: docs/jetbrains-integration.md"
