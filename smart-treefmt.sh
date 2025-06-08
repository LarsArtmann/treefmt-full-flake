#!/usr/bin/env bash
# smart-treefmt.sh - Intelligent treefmt wrapper with smart configuration resolution
# Inspired by smart-config principles: https://github.com/LarsArtmann/mono/issues/208

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration variables
TREEFMT_COMMAND=""
TREEFMT_CONFIG=""
TREEFMT_ARGS=()
VERBOSE=false
DRY_RUN=false

# Function to print colored output
print_color() {
  local color=$1
  shift
  echo -e "${color}$*${NC}"
}

# Function to print verbose messages
verbose() {
  if [[ $VERBOSE == true ]]; then
    print_color "$BLUE" "[VERBOSE] $*" >&2
  fi
}

# Function to print error with formatting
error() {
  echo -e "${RED}${BOLD}Error: $*${NC}" >&2
}

# Function to print success with formatting
success() {
  echo -e "${GREEN}✓ $*${NC}"
}

# Function to print failure with formatting
failure() {
  echo -e "${RED}✗ $*${NC}"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to find treefmt command
find_treefmt_command() {
  local attempts=()

  print_color "$BOLD" "🔍 Searching for treefmt..."
  echo

  # 1. Check if running in Nix environment with treefmt
  if [[ -n ${IN_NIX_SHELL:-} ]] && command_exists treefmt; then
    TREEFMT_COMMAND="treefmt"
    success "Found treefmt in Nix shell environment"
    return 0
  else
    attempts+=("Nix shell environment: not in Nix shell or treefmt not available")
  fi

  # 2. Check for nix fmt command (preferred for flake-based projects)
  if command_exists nix && [[ -f "flake.nix" ]]; then
    if nix eval --impure --expr 'builtins.pathExists ./flake.nix' &>/dev/null; then
      # Test if nix fmt works
      if nix fmt -- --version &>/dev/null; then
        TREEFMT_COMMAND="nix fmt --"
        success "Found 'nix fmt' command (flake-based treefmt)"
        return 0
      else
        attempts+=("'nix fmt' command: found flake.nix but formatter not configured")
      fi
    fi
  else
    if ! command_exists nix; then
      attempts+=("'nix fmt' command: nix not installed")
    else
      attempts+=("'nix fmt' command: no flake.nix found")
    fi
  fi

  # 3. Check for ./result/bin/treefmt (nix build output)
  if [[ -x "./result/bin/treefmt" ]]; then
    TREEFMT_COMMAND="./result/bin/treefmt"
    success "Found treefmt at ./result/bin/treefmt"
    return 0
  else
    attempts+=("Nix build result: ./result/bin/treefmt not found or not executable")
  fi

  # 4. Check if treefmt is in PATH
  if command_exists treefmt; then
    TREEFMT_COMMAND="treefmt"
    success "Found treefmt in PATH at $(command -v treefmt)"
    return 0
  else
    attempts+=("System PATH: treefmt command not found")
  fi

  # 5. Check common installation locations
  local common_paths=(
    "/usr/local/bin/treefmt"
    "/opt/homebrew/bin/treefmt"
    "$HOME/.local/bin/treefmt"
    "$HOME/.nix-profile/bin/treefmt"
    "/run/current-system/sw/bin/treefmt"
  )

  for path in "${common_paths[@]}"; do
    if [[ -x $path ]]; then
      TREEFMT_COMMAND="$path"
      success "Found treefmt at $path"
      return 0
    else
      attempts+=("Common location $path: not found or not executable")
    fi
  done

  # If we get here, treefmt was not found
  echo
  error "treefmt not found"
  echo
  echo "Attempted to find treefmt in the following locations:"
  for attempt in "${attempts[@]}"; do
    failure "$attempt"
  done

  echo
  print_color "$YELLOW" "To resolve this issue, you can:"
  echo
  echo "1. If this is a Nix flake project with treefmt-full-flake:"
  echo "   ${BOLD}nix develop${NC}  # Enter development shell with treefmt"
  echo
  echo "2. Build treefmt using Nix:"
  echo "   ${BOLD}nix build${NC}  # Creates ./result/bin/treefmt"
  echo
  echo "3. Install treefmt globally:"
  echo "   ${BOLD}nix-env -iA nixpkgs.treefmt${NC}  # Using Nix"
  echo "   ${BOLD}brew install treefmt${NC}          # Using Homebrew (macOS)"
  echo
  echo "4. Use nix run for one-time execution:"
  echo "   ${BOLD}nix run nixpkgs#treefmt${NC}"
  echo
  echo "For more information, see:"
  echo "  • https://github.com/numtide/treefmt"
  echo "  • https://github.com/LarsArtmann/treefmt-full-flake"

  return 1
}

# Function to find treefmt configuration
find_treefmt_config() {
  local attempts=()

  verbose "Searching for treefmt configuration..."

  # 1. Check for explicit config file argument
  for ((i = 0; i < ${#TREEFMT_ARGS[@]}; i++)); do
    if [[ ${TREEFMT_ARGS[i]} == "--config-file" ]] && [[ $((i + 1)) -lt ${#TREEFMT_ARGS[@]} ]]; then
      local config_file="${TREEFMT_ARGS[$((i + 1))]}"
      if [[ -f $config_file ]]; then
        TREEFMT_CONFIG="$config_file"
        verbose "Using explicit config file: $config_file"
        return 0
      else
        attempts+=("Explicit config file '$config_file': file not found")
      fi
    fi
  done

  # 2. Check for flake.nix (indicates Nix-based configuration)
  if [[ -f "flake.nix" ]] && grep -q "treefmt" "flake.nix" 2>/dev/null; then
    verbose "Found treefmt configuration in flake.nix"
    # Nix-based projects don't need explicit config file
    return 0
  fi

  # 3. Check for treefmt.toml in current directory
  if [[ -f "treefmt.toml" ]]; then
    TREEFMT_CONFIG="treefmt.toml"
    verbose "Found treefmt.toml in current directory"
    return 0
  fi

  # 4. Check for .treefmt.toml in current directory
  if [[ -f ".treefmt.toml" ]]; then
    TREEFMT_CONFIG=".treefmt.toml"
    verbose "Found .treefmt.toml in current directory"
    return 0
  fi

  # 5. Search up the directory tree
  local dir="$PWD"
  while [[ $dir != "/" ]]; do
    if [[ -f "$dir/treefmt.toml" ]]; then
      TREEFMT_CONFIG="$dir/treefmt.toml"
      verbose "Found treefmt.toml at $dir"
      return 0
    fi
    if [[ -f "$dir/.treefmt.toml" ]]; then
      TREEFMT_CONFIG="$dir/.treefmt.toml"
      verbose "Found .treefmt.toml at $dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done

  # Configuration not found, but that might be OK for Nix-based projects
  if [[ -f "flake.nix" ]]; then
    verbose "No explicit treefmt config file found, but flake.nix exists (may use Nix-based config)"
    return 0
  fi

  # Warn about missing configuration
  print_color "$YELLOW" "⚠️  Warning: No treefmt configuration found"
  echo
  echo "Attempted to find configuration in:"
  failure "treefmt.toml or .treefmt.toml in current directory"
  failure "treefmt.toml or .treefmt.toml in parent directories"
  failure "treefmt configuration in flake.nix"

  echo
  echo "To create a configuration:"
  echo "1. For Nix flake projects:"
  echo "   See: https://github.com/LarsArtmann/treefmt-full-flake"
  echo
  echo "2. For traditional projects, create treefmt.toml:"
  echo "   ${BOLD}treefmt --init${NC}"
  echo

  return 1
}

# Function to check for common issues
check_common_issues() {
  verbose "Checking for common issues..."

  # Check if in git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    print_color "$YELLOW" "⚠️  Warning: Not in a git repository"
    echo "   Some treefmt features may not work correctly outside of a git repository."
    echo
  fi

  # Check for .gitignore
  if [[ ! -f ".gitignore" ]]; then
    print_color "$YELLOW" "⚠️  Warning: No .gitignore file found"
    echo "   Consider adding a .gitignore to exclude files from formatting."
    echo
  fi
}

# Function to detect project type and provide specific guidance
detect_project_type() {
  verbose "Detecting project type..."

  local project_types=()

  # Detect various project types
  [[ -f "package.json" ]] && project_types+=("Node.js/npm")
  [[ -f "Cargo.toml" ]] && project_types+=("Rust/Cargo")
  [[ -f "go.mod" ]] && project_types+=("Go")
  [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] && project_types+=("Python")
  [[ -f "flake.nix" ]] && project_types+=("Nix Flake")
  [[ -f "shell.nix" ]] || [[ -f "default.nix" ]] && project_types+=("Nix")

  if [[ ${#project_types[@]} -gt 0 ]]; then
    verbose "Detected project types: ${project_types[*]}"

    # Provide project-specific tips
    if [[ " ${project_types[*]} " =~ " Nix Flake " ]] && [[ ! -f "flake.nix" ]]; then
      echo
      print_color "$BLUE" "💡 Tip: This looks like it could be a Nix flake project."
      echo "   Consider using treefmt-full-flake for comprehensive formatting:"
      echo "   ${BOLD}nix flake init -t github:LarsArtmann/treefmt-full-flake${NC}"
    fi
  fi
}

# Function to run treefmt with smart features
run_treefmt() {
  # Build the command
  local cmd=()

  # Handle "nix fmt --" as a special case
  if [[ $TREEFMT_COMMAND == "nix fmt --" ]]; then
    cmd=("nix" "fmt" "--")
  else
    cmd=("$TREEFMT_COMMAND")
  fi

  # Add config file if found and not using nix fmt
  if [[ -n $TREEFMT_CONFIG ]] && [[ $TREEFMT_COMMAND != "nix fmt --" ]]; then
    cmd+=("--config-file" "$TREEFMT_CONFIG")
  fi

  # Add all arguments
  if [[ ${#TREEFMT_ARGS[@]} -gt 0 ]]; then
    cmd+=("${TREEFMT_ARGS[@]}")
  fi

  # Show what we're running in verbose mode
  verbose "Executing: ${cmd[*]}"

  # Run the command
  if [[ $DRY_RUN == true ]]; then
    print_color "$YELLOW" "🏃 Would run: ${cmd[*]}"
    return 0
  else
    # Execute the command, preserving the exit code
    set +e
    "${cmd[@]}"
    local exit_code=$?
    set -e

    # Handle specific exit codes
    case $exit_code in
    0)
      success "Formatting completed successfully"
      ;;
    1)
      # Common exit code for formatting changes made
      if [[ " ${TREEFMT_ARGS[*]} " =~ " --fail-on-change " ]]; then
        error "Formatting changes detected (--fail-on-change is enabled)"
        echo
        echo "To fix this:"
        echo "1. Run without --fail-on-change to apply formatting:"
        echo "   ${BOLD}$0${NC}"
        echo
        echo "2. Or review the changes that would be made:"
        echo "   ${BOLD}$0 --dry-run${NC}"
      else
        print_color "$YELLOW" "ℹ️  Formatting changes were applied"
      fi
      ;;
    *)
      error "treefmt exited with code $exit_code"
      echo
      echo "Common causes:"
      echo "• Missing formatter executables (install required formatters)"
      echo "• Invalid configuration file"
      echo "• File permission issues"
      echo
      echo "Run with -v for more details:"
      echo "   ${BOLD}$0 -v${NC}"
      ;;
    esac

    return $exit_code
  fi
}

# Function to show usage
usage() {
  cat <<EOF
${BOLD}smart-treefmt${NC} - Intelligent treefmt wrapper with smart configuration resolution

${BOLD}USAGE:${NC}
    $0 [OPTIONS] [TREEFMT_ARGS...]

${BOLD}OPTIONS:${NC}
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -n, --dry-run   Show what would be executed without running it

${BOLD}TREEFMT_ARGS:${NC}
    All additional arguments are passed directly to treefmt.
    Common treefmt arguments:
    
    --fail-on-change    Exit with error if formatting changes files
    --no-cache          Disable caching
    --clear-cache       Clear the cache before running
    -c, --config-file   Specify configuration file
    
${BOLD}EXAMPLES:${NC}
    # Format all files
    $0
    
    # Check formatting without making changes
    $0 --fail-on-change
    
    # Format specific files
    $0 src/main.rs README.md
    
    # Verbose mode with dry run
    $0 -v -n
    
    # Clear cache and format
    $0 --clear-cache

${BOLD}SMART FEATURES:${NC}
    • Automatically finds treefmt in multiple locations
    • Detects Nix flake projects and uses 'nix fmt'
    • Searches for configuration files intelligently
    • Provides detailed error messages with solutions
    • Detects project type and offers specific guidance

For more information, see:
    https://github.com/numtide/treefmt
    https://github.com/LarsArtmann/treefmt-full-flake
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    usage
    exit 0
    ;;
  -v | --verbose)
    VERBOSE=true
    shift
    ;;
  -n | --dry-run)
    DRY_RUN=true
    shift
    ;;
  *)
    # Everything else is passed to treefmt
    TREEFMT_ARGS+=("$1")
    shift
    ;;
  esac
done

# Main execution flow
main() {
  print_color "$BOLD" "🤖 Smart treefmt - Intelligent Code Formatter"
  echo

  # Find treefmt command
  if ! find_treefmt_command; then
    exit 1
  fi

  echo

  # Find configuration (optional)
  find_treefmt_config

  # Check for common issues
  check_common_issues

  # Detect project type for better guidance
  detect_project_type

  echo

  # Run treefmt
  run_treefmt
}

# Run main function
main
