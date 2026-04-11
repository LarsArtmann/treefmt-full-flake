#!/usr/bin/env bash
# Shared test utilities library
# This file should be sourced by all test scripts to avoid code duplication

# =============================================================================
# Color definitions
# =============================================================================
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[1;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_NC='\033[0m'

# Backwards compatibility aliases
export RED="$COLOR_RED"
export GREEN="$COLOR_GREEN"
export YELLOW="$COLOR_YELLOW"
export BLUE="$COLOR_BLUE"
export NC="$COLOR_NC"

# =============================================================================
# Source dependencies
# =============================================================================
# Get the directory of this library file
_TEST_UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source timing utilities if available
if [ -f "${_TEST_UTILS_DIR}/timing.sh" ]; then
  source "${_TEST_UTILS_DIR}/timing.sh"
fi

# Source timeout utilities if available
if [ -f "${_TEST_UTILS_DIR}/timeout.sh" ]; then
  source "${_TEST_UTILS_DIR}/timeout.sh"
fi

# Source error reporting utilities if available
if [ -f "${_TEST_UTILS_DIR}/error-report.sh" ]; then
  source "${_TEST_UTILS_DIR}/error-report.sh"
fi

# =============================================================================
# Banner utilities
# =============================================================================

# Print a test suite banner
# Usage: print_banner "Title"
print_banner() {
  local title="$1"
  local width=44
  local padding=$(( (width - ${#title} - 2) / 2 ))
  
  printf "${COLOR_BLUE}%${width}s%${NC}\n" | tr ' ' '═'
  printf "${COLOR_BLUE}║%*s %s %*s║${NC}\n" "$padding" "" "$title" "$(( padding + (${#title} % 2) ))" ""
  printf "${COLOR_BLUE}%${width}s%${NC}\n" | tr ' ' '═'
}

# =============================================================================
# Test environment setup
# =============================================================================

# Initialize test environment
# Usage: init_test_environment "test-name"
# Sets: TEST_NAME, TEST_DIR, REPO_ROOT, SCRIPT_DIR
init_test_environment() {
  TEST_NAME="$1"
  TEST_DIR=$(mktemp -d)
  REPO_ROOT=$(cd "${BASH_SOURCE[0]}/../../.." && pwd)
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  
  echo -e "${YELLOW}Testing ${TEST_NAME}...${NC}"
  echo "Test directory: $TEST_DIR"
}

# Setup git repository in test directory
# Usage: setup_git_repo [email] [name]
setup_git_repo() {
  local email="${1:-test@example.com}"
  local name="${2:-Test User}"
  
  git init -q
  git config user.email "$email"
  git config user.name "$name"
  echo -e "${GREEN}✓ Test directory and git initialized${NC}"
}

# Initialize a nix flake template
# Usage: init_template "template-name" [timeout_seconds]
init_template() {
  local template_name="$1"
  local timeout_secs="${2:-30}"
  local TEMPLATE_PATH="${REPO_ROOT}#${template_name}"
  
  if type get_template_path >/dev/null 2>&1; then
    TEMPLATE_PATH=$(get_template_path "$template_name")
  fi
  
  if ! run_with_timeout "$timeout_secs" "nix flake init -t ${TEMPLATE_PATH}"; then
    echo -e "${RED}Failed to initialize template${NC}"
    return 1
  fi
  
  # Patch flake.nix to use local repository for testing
  if [ -f flake.nix ]; then
    sed -i '' "s|git+ssh://git@github.com/LarsArtmann/treefmt-full-flake.git|path:${REPO_ROOT}|g" flake.nix
    git add flake.nix
  fi
  
  echo -e "${GREEN}✓ Template initialized${NC}"
  return 0
}

# Check flake metadata
# Usage: check_flake_metadata [timeout_seconds]
check_flake_metadata() {
  local timeout_secs="${1:-30}"
  
  if ! run_with_timeout "$timeout_secs" "nix flake metadata --no-registries"; then
    echo -e "${RED}Failed to check flake metadata${NC}"
    return 1
  fi
  echo -e "${GREEN}✓ Flake metadata is valid${NC}"
  
  # Add the generated lock file to git
  if [ -f "flake.lock" ]; then
    git add flake.lock
  fi
  return 0
}

# =============================================================================
# Formatter testing utilities
# =============================================================================

# Run formatter with idempotency check
# Usage: run_formatter_test [timeout_seconds]
run_formatter_test() {
  local timeout_secs="${1:-60}"
  local formatter_timeout="${2:-$(( timeout_secs * 2 ))}"
  
  # First, verify formatter is available
  if ! run_with_timeout "$timeout_secs" "nix fmt -- --version"; then
    echo -e "${RED}Formatter not available${NC}"
    return 1
  fi
  
  # Run formatter first pass
  if ! run_with_timeout "$formatter_timeout" "nix fmt --no-update-lock-file"; then
    echo -e "${RED}Formatter failed${NC}"
    return 1
  fi
  echo -e "${GREEN}✓ Formatter ran successfully (pass 1)${NC}"
  
  # Run formatter again to ensure idempotency
  if ! run_with_timeout "$formatter_timeout" "nix fmt --no-update-lock-file"; then
    echo -e "${RED}Formatter failed on second pass${NC}"
    return 1
  fi
  echo -e "${GREEN}✓ Formatter is idempotent (pass 2)${NC}"
  
  # Commit the formatted changes to stabilize git state
  git add -A
  git commit -m "Format code" -q || true
  
  return 0
}

# Run flake check
# Usage: run_flake_check [timeout_seconds]
run_flake_check() {
  local timeout_secs="${1:-60}"
  
  if ! run_with_timeout "$timeout_secs" "nix flake check --no-update-lock-file"; then
    echo -e "${RED}Failed to check flake${NC}"
    return 1
  fi
  echo -e "${GREEN}✓ Flake check passed${NC}"
  return 0
}

# Test development shell
# Usage: test_dev_shell [timeout_seconds]
test_dev_shell() {
  local timeout_secs="${1:-30}"
  
  if ! run_with_timeout "$timeout_secs" "nix develop --no-update-lock-file -c treefmt --version"; then
    echo -e "${RED}Development shell failed${NC}"
    return 1
  fi
  echo -e "${GREEN}✓ Development shell works${NC}"
  return 0
}

# Run format check (ci mode)
# Usage: run_format_check [timeout_seconds]
run_format_check() {
  local timeout_secs="${1:-60}"
  
  if ! run_with_timeout "$timeout_secs" "nix fmt --no-update-lock-file -- --ci --no-cache"; then
    echo -e "${RED}Format check failed after formatting${NC}"
    return 1
  fi
  echo -e "${GREEN}✓ Format check passed${NC}"
  return 0
}

# =============================================================================
# File verification utilities
# =============================================================================

# Verify a file exists
# Usage: verify_file_exists "filename"
verify_file_exists() {
  local filename="$1"
  if [ ! -f "$filename" ]; then
    echo -e "${RED}${filename} not found${NC}"
    return 1
  fi
  echo -e "${GREEN}✓ ${filename} exists${NC}"
  return 0
}

# Verify Nix file formatting
# Usage: verify_nix_formatting "filename"
verify_nix_formatting() {
  local filename="$1"
  if ! grep -qE "(^{|{pkgs)" "$filename" || ! grep -q "pkgs.hello" "$filename"; then
    echo -e "${RED}Nix file was not formatted properly${NC}"
    echo "Expected proper Nix formatting but got:"
    head -10 "$filename"
    return 1
  fi
  echo -e "${GREEN}✓ Nix file formatted${NC}"
  return 0
}

# =============================================================================
# Cleanup utilities
# =============================================================================

# Create standard cleanup function
# Usage: setup_cleanup [additional_cleanup_func]
setup_cleanup() {
  # Define the cleanup trap if not already defined
  if [ -z "${CLEANUP_DEFINED:-}" ]; then
    CLEANUP_DEFINED=1
    
    cleanup() {
      echo -e "${YELLOW}Cleaning up test directory...${NC}"
      if command -v trash >/dev/null 2>&1; then
        trash "$TEST_DIR" 2>/dev/null || rm -rf "$TEST_DIR"
      else
        rm -rf "$TEST_DIR"
      fi
    }
    trap cleanup EXIT
  fi
}

# =============================================================================
# Test runner utilities (for test runner scripts)
# =============================================================================

# Print test section header
# Usage: print_section "Section Name"
print_section() {
  local name="$1"
  echo -e "\n${YELLOW}${name}...${NC}\n"
}

# Run a single test and track results
# Usage: run_and_track_test "test-script" "test-name"
# Sets: PASSED_TESTS, FAILED_TESTS arrays and TOTAL_TIME
declare -a PASSED_TESTS=()
declare -a FAILED_TESTS=()
TOTAL_TIME=0

run_and_track_test() {
  local test_script="$1"
  local test_name="$2"
  
  local start_time=$(date +%s)
  
  if "$test_script"; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    TOTAL_TIME=$((TOTAL_TIME + duration))
    
    echo -e "${GREEN}✓ ${test_name} passed (${duration}s)${NC}"
    PASSED_TESTS+=("$test_name")
    return 0
  else
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    TOTAL_TIME=$((TOTAL_TIME + duration))
    
    echo -e "${RED}✗ ${test_name} failed (${duration}s)${NC}"
    FAILED_TESTS+=("$test_name")
    return 1
  fi
}

# Print test summary
# Usage: print_test_summary
print_test_summary() {
  local total_tests=$((${#PASSED_TESTS[@]} + ${#FAILED_TESTS[@]}))
  
  print_banner "Test Summary"
  
  if [ ${#PASSED_TESTS[@]} -gt 0 ]; then
    echo -e "${GREEN}Passed tests (${#PASSED_TESTS[@]}/${total_tests}):${NC}"
    for test in "${PASSED_TESTS[@]}"; do
      echo -e "  ${GREEN}✓${NC} $test"
    done
    echo ""
  fi
  
  if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo -e "${RED}Failed tests (${#FAILED_TESTS[@]}/${total_tests}):${NC}"
    for test in "${FAILED_TESTS[@]}"; do
      echo -e "  ${RED}✗${NC} $test"
    done
    echo ""
  fi
  
  echo -e "Total time: ${TOTAL_TIME}s"
  echo ""
  
  # Exit with appropriate code
  if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    return 0
  else
    echo -e "${RED}❌ ${#FAILED_TESTS[@]} test(s) failed${NC}"
    return 1
  fi
}

# =============================================================================
# Source wrapper if available
# =============================================================================

# Source wrapper if available (for CI environments)
if [ -n "${REPO_ROOT:-}" ] && [ -f "${REPO_ROOT}/tests/templates/wrapper.sh" ]; then
  source "${REPO_ROOT}/tests/templates/wrapper.sh"
elif [ -f "${_TEST_UTILS_DIR}/../templates/wrapper.sh" ]; then
  source "${_TEST_UTILS_DIR}/../templates/wrapper.sh"
fi
