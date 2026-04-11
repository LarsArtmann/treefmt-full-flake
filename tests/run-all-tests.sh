#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"

# Script configuration
declare -a FAILED_TESTS=()
declare -a PASSED_TESTS=()
TOTAL_TIME=0

print_banner "Template Test Suite Runner"

# Function to run a single test
run_test() {
  local test_script=$1
  local test_name=$(basename "$test_script" .sh)
  
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}Running: ${test_name}${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  run_and_track_test "$test_script" "$test_name"
  
  echo ""
}

# Check if specific test is requested
if [ $# -gt 0 ]; then
  # Run specific tests
  for test_name in "$@"; do
    # Check multiple locations
    found=false
    for dir in templates edge-cases formatters; do
      test_path="${SCRIPT_DIR}/${dir}/test-${test_name}.sh"
      if [ -f "$test_path" ]; then
        run_test "$test_path"
        found=true
        break
      fi
    done
    
    if [ "$found" = false ]; then
      echo -e "${RED}Error: Test '${test_name}' not found${NC}"
      echo "Available tests:"
      for dir in templates edge-cases formatters; do
        if [ -d "${SCRIPT_DIR}/${dir}" ]; then
          echo "  From ${dir}:"
          for test in "${SCRIPT_DIR}"/${dir}/test-*.sh; do
            if [ -f "$test" ]; then
              basename "$test" .sh | sed 's/test-/    - /'
            fi
          done
        fi
      done
      exit 1
    fi
  done
else
  # Run all tests from all directories
  echo -e "${YELLOW}Running template tests...${NC}\n"
  for test_script in "${SCRIPT_DIR}"/templates/test-*.sh; do
    if [ -f "$test_script" ]; then
      run_test "$test_script"
    fi
  done
  
  echo -e "${YELLOW}Running edge case tests...${NC}\n"
  for test_script in "${SCRIPT_DIR}"/edge-cases/test-*.sh; do
    if [ -f "$test_script" ]; then
      run_test "$test_script"
    fi
  done
  
  echo -e "${YELLOW}Running formatter tests...${NC}\n"
  for test_script in "${SCRIPT_DIR}"/formatters/test-*.sh; do
    if [ -f "$test_script" ]; then
      run_test "$test_script"
    fi
  done
fi

# Print summary
print_test_summary
