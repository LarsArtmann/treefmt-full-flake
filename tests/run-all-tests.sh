#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
FAILED_TESTS=()
PASSED_TESTS=()
TOTAL_TIME=0

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Template Test Suite Runner         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Function to run a single test
run_test() {
  local test_script=$1
  local test_name=$(basename "$test_script" .sh)

  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}Running: ${test_name}${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  local start_time=$(date +%s)

  if "$test_script"; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    TOTAL_TIME=$((TOTAL_TIME + duration))

    echo -e "${GREEN}✅ ${test_name} passed (${duration}s)${NC}"
    PASSED_TESTS+=("$test_name")
  else
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    TOTAL_TIME=$((TOTAL_TIME + duration))

    echo -e "${RED}❌ ${test_name} failed (${duration}s)${NC}"
    FAILED_TESTS+=("$test_name")
  fi

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
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Test Summary                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

total_tests=$((${#PASSED_TESTS[@]} + ${#FAILED_TESTS[@]}))

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
  exit 0
else
  echo -e "${RED}❌ ${#FAILED_TESTS[@]} test(s) failed${NC}"
  exit 1
fi
