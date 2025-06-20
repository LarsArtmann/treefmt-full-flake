#!/usr/bin/env bash
# smart-treefmt-v2.sh - Next-generation intelligent treefmt wrapper
# Inspired by smart-config principles: https://github.com/LarsArtmann/mono/issues/208
# Version: 2.0.0

set -euo pipefail

# Script version
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_URL="https://raw.githubusercontent.com/LarsArtmann/treefmt-full-flake/master/smart-treefmt-v2.sh"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color
readonly BOLD='\033[1m'
readonly DIM='\033[2m'

# Unicode characters
readonly CHECK_MARK="✓"
readonly CROSS_MARK="✗"
readonly ARROW="→"
readonly INFO="ℹ"
readonly WARNING="⚠"
readonly GEAR="⚙"
readonly ROCKET="🚀"
readonly MAGIC="✨"
readonly ROBOT="🤖"

# Cache configuration
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/smart-treefmt"
readonly CACHE_TTL=3600 # 1 hour in seconds

# Configuration variables
TREEFMT_COMMAND=""
TREEFMT_CONFIG=""
TREEFMT_ARGS=()
VERBOSE=false
DRY_RUN=false
AUTO_FIX=false
INTERACTIVE=false
NO_CACHE=false
GENERATE_CONFIG=false

# Progress animation frames
readonly SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
SPINNER_PID=""

# Function to print colored output
print_color() {
  local color=$1
  shift
  echo -e "${color}$*${NC}"
}

# Function to print verbose messages
verbose() {
  if [[ $VERBOSE == true ]]; then
    print_color "$DIM" "[VERBOSE] $*" >&2
  fi
}

# Function to print error with formatting
error() {
  echo -e "${RED}${BOLD}Error: $*${NC}" >&2
}

# Function to print success with formatting
success() {
  echo -e "${GREEN}${CHECK_MARK} $*${NC}"
}

# Function to print failure with formatting
failure() {
  echo -e "${RED}${CROSS_MARK} $*${NC}"
}

# Function to print info
info() {
  echo -e "${CYAN}${INFO} $*${NC}"
}

# Function to print warning
warning() {
  echo -e "${YELLOW}${WARNING} $*${NC}"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to start spinner
start_spinner() {
  local message=$1
  (
    local i=0
    while true; do
      printf "\r${CYAN}%s${NC} %s" "${SPINNER_FRAMES[$i]}" "$message"
      i=$(((i + 1) % ${#SPINNER_FRAMES[@]}))
      sleep 0.1
    done
  ) &
  SPINNER_PID=$!
}

# Function to stop spinner
stop_spinner() {
  if [[ -n $SPINNER_PID ]]; then
    kill "$SPINNER_PID" 2>/dev/null || true
    SPINNER_PID=""
    printf "\r%*s\r" "${COLUMNS:-80}" "" # Clear the line
  fi
}

# Function to ensure cache directory exists
ensure_cache_dir() {
  mkdir -p "$CACHE_DIR"
}

# Function to get cache file path
get_cache_file() {
  local key=$1
  echo "$CACHE_DIR/${key}.cache"
}

# Function to read from cache
read_cache() {
  local key=$1
  local cache_file
  cache_file=$(get_cache_file "$key")

  if [[ $NO_CACHE == true ]]; then
    verbose "Cache disabled, skipping read for $key"
    return 1
  fi

  if [[ -f $cache_file ]]; then
    local age
    age=$(($(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0)))
    if [[ $age -lt $CACHE_TTL ]]; then
      verbose "Cache hit for $key (age: ${age}s)"
      cat "$cache_file"
      return 0
    else
      verbose "Cache expired for $key (age: ${age}s)"
    fi
  else
    verbose "Cache miss for $key"
  fi
  return 1
}

# Function to write to cache
write_cache() {
  local key=$1
  local value=$2
  ensure_cache_dir
  local cache_file
  cache_file=$(get_cache_file "$key")
  echo "$value" >"$cache_file"
  verbose "Cached $key"
}

# Function to prompt user for yes/no
prompt_yes_no() {
  local prompt=$1
  local default=${2:-n}
  local response

  if [[ $default == "y" ]]; then
    prompt="$prompt [Y/n]: "
  else
    prompt="$prompt [y/N]: "
  fi

  if [[ $INTERACTIVE == false ]] && [[ $AUTO_FIX == false ]]; then
    return 1
  fi

  read -r -p "$prompt" response
  response=${response:-$default}

  case "$response" in
  [yY][eE][sS] | [yY])
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

# Function to select from menu
select_option() {
  local prompt=$1
  shift
  local options=("$@")
  local selected=0
  local key

  # Print menu
  echo "$prompt"
  for i in "${!options[@]}"; do
    if [[ $i -eq $selected ]]; then
      echo -e "${GREEN}${ARROW}${NC} ${options[$i]}"
    else
      echo "  ${options[$i]}"
    fi
  done

  # Read user input
  while true; do
    read -r -s -n1 key
    case "$key" in
    A) # Up arrow
      selected=$(((selected - 1 + ${#options[@]}) % ${#options[@]}))
      ;;
    B) # Down arrow
      selected=$(((selected + 1) % ${#options[@]}))
      ;;
    "") # Enter
      return $selected
      ;;
    esac

    # Redraw menu
    printf "\033[${#options[@]}A" # Move cursor up
    for i in "${!options[@]}"; do
      if [[ $i -eq $selected ]]; then
        echo -e "\r${GREEN}${ARROW}${NC} ${options[$i]}"
      else
        echo -e "\r  ${options[$i]}"
      fi
    done
  done
}

# Function to find treefmt command with caching
find_treefmt_command() {
  local cache_key="treefmt_command_$(pwd | md5sum | cut -d' ' -f1)"
  local cached_command

  # Try to read from cache first
  if cached_command=$(read_cache "$cache_key"); then
    TREEFMT_COMMAND="$cached_command"
    success "Found treefmt (cached): $TREEFMT_COMMAND"
    return 0
  fi

  local attempts=()

  start_spinner "Searching for treefmt..."

  # 1. Check if running in Nix environment with treefmt
  if [[ -n ${IN_NIX_SHELL:-} ]] && command_exists treefmt; then
    TREEFMT_COMMAND="treefmt"
    stop_spinner
    success "Found treefmt in Nix shell environment"
    write_cache "$cache_key" "$TREEFMT_COMMAND"
    return 0
  else
    attempts+=("Nix shell environment: not in Nix shell or treefmt not available")
  fi

  # 2. Check for direnv/mise environments
  if [[ -f .envrc ]] && command_exists direnv; then
    verbose "Found .envrc, checking direnv environment"
    if eval "$(direnv export bash 2>/dev/null)" && command_exists treefmt; then
      TREEFMT_COMMAND="treefmt"
      stop_spinner
      success "Found treefmt via direnv"
      write_cache "$cache_key" "$TREEFMT_COMMAND"
      return 0
    else
      attempts+=("direnv environment: .envrc found but treefmt not available")
    fi
  fi

  if [[ -f .tool-versions ]] && command_exists mise; then
    verbose "Found .tool-versions, checking mise environment"
    if eval "$(mise env 2>/dev/null)" && command_exists treefmt; then
      TREEFMT_COMMAND="treefmt"
      stop_spinner
      success "Found treefmt via mise"
      write_cache "$cache_key" "$TREEFMT_COMMAND"
      return 0
    else
      attempts+=("mise environment: .tool-versions found but treefmt not available")
    fi
  fi

  # 3. Check for nix fmt command (preferred for flake-based projects)
  if command_exists nix && [[ -f "flake.nix" ]]; then
    if nix eval --impure --expr 'builtins.pathExists ./flake.nix' &>/dev/null; then
      # Test if nix fmt works
      if nix fmt -- --version &>/dev/null; then
        TREEFMT_COMMAND="nix fmt --"
        stop_spinner
        success "Found 'nix fmt' command (flake-based treefmt)"
        write_cache "$cache_key" "$TREEFMT_COMMAND"
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

  # 4. Check for ./result/bin/treefmt (nix build output)
  if [[ -x "./result/bin/treefmt" ]]; then
    TREEFMT_COMMAND="./result/bin/treefmt"
    stop_spinner
    success "Found treefmt at ./result/bin/treefmt"
    write_cache "$cache_key" "$TREEFMT_COMMAND"
    return 0
  else
    attempts+=("Nix build result: ./result/bin/treefmt not found or not executable")
  fi

  # 5. Check if treefmt is in PATH
  if command_exists treefmt; then
    TREEFMT_COMMAND="treefmt"
    stop_spinner
    success "Found treefmt in PATH at $(command -v treefmt)"
    write_cache "$cache_key" "$TREEFMT_COMMAND"
    return 0
  else
    attempts+=("System PATH: treefmt command not found")
  fi

  # 6. Check common installation locations
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
      stop_spinner
      success "Found treefmt at $path"
      write_cache "$cache_key" "$TREEFMT_COMMAND"
      return 0
    else
      attempts+=("Common location $path: not found or not executable")
    fi
  done

  stop_spinner

  # If we get here, treefmt was not found
  echo
  error "treefmt not found"
  echo
  echo "Attempted to find treefmt in the following locations:"
  for attempt in "${attempts[@]}"; do
    failure "$attempt"
  done

  # Auto-fix options
  if [[ $AUTO_FIX == true ]] || [[ $INTERACTIVE == true ]]; then
    echo
    print_color "$YELLOW" "${MAGIC} Auto-fix available!"
    echo

    local fix_options=()
    local fix_commands=()

    if [[ -f "flake.nix" ]] && command_exists nix; then
      fix_options+=("Enter Nix development shell (nix develop)")
      fix_commands+=("nix develop")

      fix_options+=("Build treefmt with Nix (nix build)")
      fix_commands+=("nix build")
    fi

    if command_exists nix; then
      fix_options+=("Install treefmt globally with Nix")
      fix_commands+=("nix-env -iA nixpkgs.treefmt")
    fi

    if command_exists brew; then
      fix_options+=("Install treefmt with Homebrew")
      fix_commands+=("brew install treefmt")
    fi

    fix_options+=("Skip auto-fix and exit")
    fix_commands+=("exit")

    if [[ $INTERACTIVE == true ]]; then
      select_option "Select an auto-fix option:" "${fix_options[@]}"
      local selected=$?
    else
      # In auto-fix mode, try the first available option
      local selected=0
    fi

    if [[ $selected -lt ${#fix_commands[@]} ]]; then
      local cmd="${fix_commands[$selected]}"
      if [[ $cmd == "exit" ]]; then
        return 1
      fi

      info "Running: $cmd"
      if [[ $DRY_RUN == true ]]; then
        print_color "$YELLOW" "🏃 Would run: $cmd"
      else
        if eval "$cmd"; then
          success "Auto-fix completed! Please run the script again."
          exit 0
        else
          error "Auto-fix failed"
          return 1
        fi
      fi
    fi
  else
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
    echo "5. Run with auto-fix to resolve automatically:"
    echo "   ${BOLD}$0 --auto-fix${NC}"
    echo
    echo "For more information, see:"
    echo "  • https://github.com/numtide/treefmt"
    echo "  • https://github.com/LarsArtmann/treefmt-full-flake"
  fi

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
  warning "No treefmt configuration found"
  echo
  echo "Attempted to find configuration in:"
  failure "treefmt.toml or .treefmt.toml in current directory"
  failure "treefmt.toml or .treefmt.toml in parent directories"
  failure "treefmt configuration in flake.nix"

  # Offer to generate configuration
  if [[ $GENERATE_CONFIG == true ]] || ([[ $INTERACTIVE == true ]] && prompt_yes_no "Would you like to generate a treefmt configuration?"); then
    generate_treefmt_config
    return 0
  else
    echo
    echo "To create a configuration:"
    echo "1. For Nix flake projects:"
    echo "   See: https://github.com/LarsArtmann/treefmt-full-flake"
    echo
    echo "2. For traditional projects, create treefmt.toml:"
    echo "   ${BOLD}treefmt --init${NC}"
    echo
    echo "3. Generate optimized config for your project:"
    echo "   ${BOLD}$0 --generate-config${NC}"
    echo
  fi

  return 1
}

# Function to detect project languages
detect_languages() {
  local languages=()

  # Detect by file extensions
  find . -type f -name "*.nix" -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("nix")
  find . -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" \) -not -path "*/node_modules/*" -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("javascript")
  find . -type f -name "*.py" -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("python")
  find . -type f -name "*.rs" -not -path "*/target/*" -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("rust")
  find . -type f -name "*.go" -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("go")
  find . -type f \( -name "*.sh" -o -name "*.bash" \) -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("shell")
  find . -type f \( -name "*.yml" -o -name "*.yaml" \) -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("yaml")
  find . -type f -name "*.md" -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("markdown")
  find . -type f -name "*.json" -not -path "*/node_modules/*" -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("json")
  find . -type f -name "*.toml" -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("toml")
  find . -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.cc" -o -name "*.h" -o -name "*.hpp" \) -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("c/c++")
  find . -type f -name "*.java" -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("java")
  find . -type f \( -name "*.html" -o -name "*.css" -o -name "*.scss" -o -name "*.less" \) -not -path "*/.*" | head -1 >/dev/null 2>&1 && languages+=("web")

  echo "${languages[@]}"
}

# Function to generate treefmt configuration
generate_treefmt_config() {
  print_color "$MAGENTA" "${MAGIC} Configuration Generation Wizard"
  echo

  start_spinner "Analyzing project structure..."
  local languages=($(detect_languages))
  stop_spinner

  if [[ ${#languages[@]} -eq 0 ]]; then
    warning "No supported languages detected in the project"
    return 1
  fi

  success "Detected languages: ${languages[*]}"
  echo

  # Generate configuration
  cat >treefmt.toml <<EOF
# Generated by smart-treefmt
# https://github.com/LarsArtmann/treefmt-full-flake

[global]
excludes = [
  ".git/**/*",
  "node_modules/**/*",
  "target/**/*",
  "dist/**/*",
  ".cache/**/*",
  "*.min.js",
  "*.min.css"
]

EOF

  # Add formatters based on detected languages
  for lang in "${languages[@]}"; do
    case "$lang" in
    nix)
      cat >>treefmt.toml <<EOF
[formatter.alejandra]
command = "alejandra"
includes = ["*.nix"]

[formatter.deadnix]
command = "deadnix"
includes = ["*.nix"]
options = ["--edit"]

[formatter.statix]
command = "statix"
includes = ["*.nix"]
options = ["fix"]

EOF
      ;;
    javascript)
      cat >>treefmt.toml <<EOF
[formatter.prettier]
command = "prettier"
includes = ["*.js", "*.jsx", "*.ts", "*.tsx", "*.mjs", "*.cjs"]
options = ["--write"]

[formatter.eslint]
command = "eslint"
includes = ["*.js", "*.jsx", "*.ts", "*.tsx", "*.mjs", "*.cjs"]
options = ["--fix"]

EOF
      ;;
    python)
      cat >>treefmt.toml <<EOF
[formatter.black]
command = "black"
includes = ["*.py"]

[formatter.isort]
command = "isort"
includes = ["*.py"]

[formatter.ruff]
command = "ruff"
includes = ["*.py"]
options = ["check", "--fix"]

EOF
      ;;
    rust)
      cat >>treefmt.toml <<EOF
[formatter.rustfmt]
command = "rustfmt"
includes = ["*.rs"]

EOF
      ;;
    go)
      cat >>treefmt.toml <<EOF
[formatter.gofmt]
command = "gofmt"
includes = ["*.go"]
options = ["-w"]

[formatter.goimports]
command = "goimports"
includes = ["*.go"]
options = ["-w"]

EOF
      ;;
    shell)
      cat >>treefmt.toml <<EOF
[formatter.shfmt]
command = "shfmt"
includes = ["*.sh", "*.bash"]
options = ["-i", "2", "-s", "-w"]

[formatter.shellcheck]
command = "shellcheck"
includes = ["*.sh", "*.bash"]

EOF
      ;;
    yaml)
      cat >>treefmt.toml <<EOF
[formatter.yamlfmt]
command = "yamlfmt"
includes = ["*.yml", "*.yaml"]

EOF
      ;;
    markdown)
      cat >>treefmt.toml <<EOF
[formatter.mdformat]
command = "mdformat"
includes = ["*.md"]
options = ["--number"]

EOF
      ;;
    json)
      cat >>treefmt.toml <<EOF
[formatter.jsonfmt]
command = "jsonfmt"
includes = ["*.json"]

EOF
      ;;
    toml)
      cat >>treefmt.toml <<EOF
[formatter.tomlfmt]
command = "tomlfmt"
includes = ["*.toml"]

EOF
      ;;
    esac
  done

  success "Generated treefmt.toml with formatters for: ${languages[*]}"
  echo
  info "Note: You'll need to install the formatters used in this configuration."
  echo "For Nix users, consider using https://github.com/LarsArtmann/treefmt-full-flake"

  TREEFMT_CONFIG="treefmt.toml"
  return 0
}

# Function to check for common issues
check_common_issues() {
  verbose "Checking for common issues..."

  # Check if in git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    warning "Not in a git repository"
    echo "   Some treefmt features may not work correctly outside of a git repository."
    echo
  fi

  # Check for .gitignore
  if [[ ! -f ".gitignore" ]]; then
    warning "No .gitignore file found"
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
  [[ -f ".envrc" ]] && project_types+=("direnv")
  [[ -f ".tool-versions" ]] && project_types+=("asdf/mise")

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

# Function to check for updates
check_for_updates() {
  if [[ $NO_CACHE == true ]]; then
    return
  fi

  local cache_key="update_check"
  local last_check

  # Only check once per day
  if last_check=$(read_cache "$cache_key"); then
    return
  fi

  verbose "Checking for script updates..."

  # Check GitHub for latest version
  local latest_version
  if latest_version=$(curl -s "$SCRIPT_URL" | grep -oP '(?<=readonly SCRIPT_VERSION=")[^"]+' 2>/dev/null); then
    if [[ $latest_version != "$SCRIPT_VERSION" ]]; then
      info "Update available: v$SCRIPT_VERSION → v$latest_version"
      echo "   Run with --update to update the script"
      echo
    fi
  fi

  # Cache the check
  write_cache "$cache_key" "$(date +%s)"
}

# Function to update the script
update_script() {
  info "Updating smart-treefmt..."

  local temp_file
  temp_file=$(mktemp)

  if curl -s -o "$temp_file" "$SCRIPT_URL"; then
    if chmod +x "$temp_file" && mv "$temp_file" "$0"; then
      success "Updated to latest version!"
      exec "$0" "$@"
    else
      error "Failed to install update"
      rm -f "$temp_file"
      return 1
    fi
  else
    error "Failed to download update"
    rm -f "$temp_file"
    return 1
  fi
}

# Function to log formatting history
log_history() {
  local action=$1
  local details=$2
  local history_dir="$CACHE_DIR/history"

  mkdir -p "$history_dir"

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local history_file="$history_dir/$(date '+%Y-%m').log"

  echo "[$timestamp] $action - $details" >>"$history_file"
  verbose "Logged to history: $action"
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

  # Log to history
  log_history "format" "command: ${cmd[*]}"

  # Run the command
  if [[ $DRY_RUN == true ]]; then
    print_color "$YELLOW" "🏃 Would run: ${cmd[*]}"
    return 0
  else
    # Show progress for long operations
    if [[ ! " ${TREEFMT_ARGS[*]} " =~ " --fail-on-change " ]]; then
      start_spinner "Formatting files..."
    fi

    # Execute the command, preserving the exit code
    set +e
    local output
    output=$("${cmd[@]}" 2>&1)
    local exit_code=$?
    set -e

    stop_spinner

    # Display output
    echo "$output"

    # Handle specific exit codes
    case $exit_code in
    0)
      success "Formatting completed successfully"
      log_history "format_success" "exit_code: 0"
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
        log_history "format_fail" "exit_code: 1, reason: fail-on-change"
      else
        info "Formatting changes were applied"
        log_history "format_changes" "exit_code: 1"
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
      log_history "format_error" "exit_code: $exit_code"
      ;;
    esac

    return $exit_code
  fi
}

# Function to show usage
usage() {
  cat <<EOF
${BOLD}smart-treefmt v${SCRIPT_VERSION}${NC} - Next-generation intelligent treefmt wrapper

${BOLD}USAGE:${NC}
    $0 [OPTIONS] [TREEFMT_ARGS...]

${BOLD}OPTIONS:${NC}
    -h, --help           Show this help message
    -v, --verbose        Enable verbose output
    -n, --dry-run        Show what would be executed without running it
    -a, --auto-fix       Automatically fix common issues
    -i, --interactive    Interactive mode with prompts
    --no-cache           Disable caching
    --generate-config    Generate optimal treefmt.toml for your project
    --update             Update this script to the latest version
    --version            Show version information

${BOLD}TREEFMT_ARGS:${NC}
    All additional arguments are passed directly to treefmt.
    Common treefmt arguments:
    
    --fail-on-change    Exit with error if formatting changes files
    --no-cache          Disable treefmt's cache
    --clear-cache       Clear the cache before running
    -c, --config-file   Specify configuration file
    
${BOLD}EXAMPLES:${NC}
    # Format all files
    $0
    
    # Auto-fix issues and format
    $0 --auto-fix
    
    # Interactive mode
    $0 --interactive
    
    # Generate config for project
    $0 --generate-config
    
    # Check formatting without making changes
    $0 --fail-on-change
    
    # Format specific files
    $0 src/main.rs README.md
    
    # Verbose mode with dry run
    $0 -v -n

${BOLD}NEW FEATURES:${NC}
    ${CHECK_MARK} Command discovery caching for instant startup
    ${CHECK_MARK} Auto-fix capabilities with --auto-fix
    ${CHECK_MARK} Interactive mode for guided experience
    ${CHECK_MARK} Configuration generation wizard
    ${CHECK_MARK} Integration with direnv and mise
    ${CHECK_MARK} Format history tracking
    ${CHECK_MARK} Progress indicators
    ${CHECK_MARK} Self-update mechanism

For more information, see:
    https://github.com/numtide/treefmt
    https://github.com/LarsArtmann/treefmt-full-flake
EOF
}

# Function to show version
show_version() {
  echo "smart-treefmt v${SCRIPT_VERSION}"
  echo "https://github.com/LarsArtmann/treefmt-full-flake"
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
  -a | --auto-fix)
    AUTO_FIX=true
    shift
    ;;
  -i | --interactive)
    INTERACTIVE=true
    shift
    ;;
  --no-cache)
    NO_CACHE=true
    shift
    ;;
  --generate-config)
    GENERATE_CONFIG=true
    shift
    ;;
  --update)
    update_script "$@"
    exit $?
    ;;
  --version)
    show_version
    exit 0
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
  print_color "$BOLD" "${ROBOT} Smart treefmt v${SCRIPT_VERSION} - Next-Gen Intelligent Code Formatter"
  echo

  # Check for updates in background
  check_for_updates

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
