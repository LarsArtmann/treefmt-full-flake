#!/usr/bin/env bash
# Enhanced error reporting utilities for tests

# Error context tracking
declare -a ERROR_CONTEXT=()
declare -a ERROR_SUGGESTIONS=()

# Add context for better error messages
add_error_context() {
  local context=$1
  ERROR_CONTEXT+=("$context")
}

# Clear error context
clear_error_context() {
  ERROR_CONTEXT=()
  ERROR_SUGGESTIONS=()
}

# Add suggestion for fixing the error
add_error_suggestion() {
  local suggestion=$1
  ERROR_SUGGESTIONS+=("$suggestion")
}

# Report error with context
report_error() {
  local error_message=$1
  local exit_code=${2:-1}

  echo -e "\n${RED}═══ ERROR ═══${NC}"
  echo -e "${RED}$error_message${NC}"

  if [ ${#ERROR_CONTEXT[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Context:${NC}"
    for context in "${ERROR_CONTEXT[@]}"; do
      echo "  • $context"
    done
  fi

  if [ ${#ERROR_SUGGESTIONS[@]} -gt 0 ]; then
    echo -e "\n${GREEN}Suggestions:${NC}"
    for suggestion in "${ERROR_SUGGESTIONS[@]}"; do
      echo "  → $suggestion"
    done
  fi

  echo -e "${RED}═════════════${NC}\n"

  # Generate detailed error report file
  if [ -n "$RESULTS_DIR" ]; then
    local error_report="$RESULTS_DIR/error-report-$(date +%s).txt"
    {
      echo "Error Report"
      echo "============"
      echo "Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
      echo "Error: $error_message"
      echo "Exit Code: $exit_code"
      echo
      echo "Context:"
      for context in "${ERROR_CONTEXT[@]}"; do
        echo "  - $context"
      done
      echo
      echo "Suggestions:"
      for suggestion in "${ERROR_SUGGESTIONS[@]}"; do
        echo "  - $suggestion"
      done
      echo
      echo "Environment:"
      echo "  PWD: $PWD"
      echo "  USER: $USER"
      echo "  SHELL: $SHELL"
      echo "  NIX_VERSION: $(nix --version 2>/dev/null || echo "Not found")"
      echo
      echo "Recent Commands:"
      history | tail -20 || echo "History not available"
    } >"$error_report"
    echo -e "${YELLOW}Detailed error report saved to: $error_report${NC}"
  fi

  return $exit_code
}

# Common error handlers
handle_nix_error() {
  local error_output=$1

  # Parse common Nix errors and provide suggestions
  if [[ $error_output =~ "attribute .* missing" ]]; then
    add_error_suggestion "Check that all required attributes are defined in your flake"
    add_error_suggestion "Verify the package name matches what's available in nixpkgs"
  elif [[ $error_output =~ "infinite recursion" ]]; then
    add_error_suggestion "Check for circular dependencies in your Nix expressions"
    add_error_suggestion "Use --show-trace to see the full evaluation trace"
  elif [[ $error_output =~ "permission denied" ]]; then
    add_error_suggestion "Ensure you have write permissions in the test directory"
    add_error_suggestion "Check if Nix daemon is running with proper permissions"
  elif [[ $error_output =~ "Git tree .* is dirty" ]]; then
    add_error_suggestion "This is expected in test environments and can usually be ignored"
    add_error_suggestion "If problematic, commit changes before running tests"
  elif [[ $error_output =~ "unexpected end of file" ]]; then
    add_error_suggestion "Check for syntax errors in Nix files"
    add_error_suggestion "Ensure all brackets and quotes are properly closed"
  fi
}

handle_formatter_error() {
  local formatter=$1
  local error_output=$2

  case "$formatter" in
  "alejandra")
    if [[ $error_output =~ "unexpected end of file" ]]; then
      add_error_suggestion "Alejandra doesn't handle empty .nix files well"
      add_error_suggestion "Add minimal content like '{}' to empty .nix files"
    fi
    ;;
  "nixfmt" | "nixfmt-rfc-style")
    add_error_suggestion "Ensure nixfmt-rfc-style is available in your nixpkgs"
    add_error_suggestion "Update nixpkgs input if package is missing"
    ;;
  "biome")
    if [[ $error_output =~ "SyntaxError" ]]; then
      add_error_suggestion "Check JavaScript/TypeScript syntax in the file"
      add_error_suggestion "Biome requires valid syntax before formatting"
    fi
    ;;
  "prettier")
    if [[ $error_output =~ "SyntaxError" ]]; then
      local line=$(echo "$error_output" | grep -oE '\([0-9]+:[0-9]+\)' | head -1)
      add_error_suggestion "Syntax error at $line"
      add_error_suggestion "Fix the syntax error before formatting"
    fi
    ;;
  esac
}

# Test-specific error context builders
build_template_test_context() {
  local template=$1
  local step=$2

  add_error_context "Template: $template"
  add_error_context "Test Step: $step"
  add_error_context "Test Directory: $PWD"

  if [ -f "flake.nix" ]; then
    add_error_context "Flake exists: Yes"
  else
    add_error_context "Flake exists: No"
    add_error_suggestion "Ensure template initialization completed successfully"
  fi

  if [ -f "flake.lock" ]; then
    add_error_context "Flake lock exists: Yes"
  else
    add_error_context "Flake lock exists: No"
  fi
}

build_formatter_test_context() {
  local formatter=$1
  local file=$2

  add_error_context "Formatter: $formatter"
  add_error_context "Test File: $file"

  if [ -f "$file" ]; then
    add_error_context "File size: $(wc -c <"$file") bytes"
    add_error_context "File lines: $(wc -l <"$file")"
  else
    add_error_context "File exists: No"
    add_error_suggestion "Ensure test file was created before formatting"
  fi
}

# Progress indication with error awareness
report_progress() {
  local step=$1
  local total=$2
  local description=$3

  echo -ne "\r${YELLOW}Progress: [$step/$total] $description...${NC}"

  # Clear line on completion
  if [ "$step" -eq "$total" ]; then
    echo -ne "\r\033[K"
  fi
}

# Test assertion with detailed error
assert_equals() {
  local actual=$1
  local expected=$2
  local description=$3

  if [ "$actual" != "$expected" ]; then
    add_error_context "Assertion failed: $description"
    add_error_context "Expected: $expected"
    add_error_context "Actual: $actual"
    report_error "Test assertion failed"
    return 1
  fi
}

assert_file_exists() {
  local file=$1
  local description=${2:-"File should exist"}

  if [ ! -f "$file" ]; then
    add_error_context "File: $file"
    report_error "$description"
    return 1
  fi
}

assert_command_succeeds() {
  local command=$1
  local description=${2:-"Command should succeed"}

  add_error_context "Command: $command"

  local output
  if ! output=$($command 2>&1); then
    local exit_code=$?
    add_error_context "Exit code: $exit_code"
    add_error_context "Output: $(echo "$output" | head -20)"
    report_error "$description"
    return $exit_code
  fi
}
