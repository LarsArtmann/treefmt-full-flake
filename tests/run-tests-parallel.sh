#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source timing utilities
source lib/timing.sh
source lib/timeout.sh

# Maximum parallel jobs (default to number of CPU cores)
MAX_JOBS=${MAX_JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)}

# Test results directory
RESULTS_DIR="$SCRIPT_DIR/.test-results"
rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

# Track overall status
FAILED_TESTS=0
PASSED_TESTS=0

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Parallel Test Runner               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo -e "${YELLOW}Running tests with $MAX_JOBS parallel jobs${NC}\n"

# Function to run a test and capture results
run_test() {
  local test_name=$1
  local test_script=$2
  local result_file="$RESULTS_DIR/${test_name}.result"
  local log_file="$RESULTS_DIR/${test_name}.log"
  local start_time=$(date +%s)

  echo -e "${YELLOW}[STARTED]${NC} $test_name"

  # Run test and capture output with universal timeout wrapper
  if run_with_timeout 300 "bash \"$test_script\"" >"$log_file" 2>&1; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "PASS $duration" >"$result_file"
    echo -e "${GREEN}[PASSED]${NC} $test_name ($(format_duration $duration))"
    return 0
  else
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "FAIL $exit_code $duration" >"$result_file"
    echo -e "${RED}[FAILED]${NC} $test_name ($(format_duration $duration))"

    # Show last 10 lines of error output
    echo -e "${RED}Last 10 lines of output:${NC}"
    tail -10 "$log_file" | sed 's/^/  /'
    echo
    return 1
  fi
}

# Export functions for parallel execution
export -f run_test format_duration
export RESULTS_DIR RED GREEN YELLOW BLUE NC

# Collect all test scripts
declare -a TEST_SCRIPTS=()
declare -a TEST_NAMES=()

# Template tests
for template in minimal default complete; do
  if [ -f "templates/test-${template}.sh" ]; then
    TEST_SCRIPTS+=("templates/test-${template}.sh")
    TEST_NAMES+=("template-${template}")
  fi
done

# Formatter tests
if [ -f "formatters/test-formatter-isolation.sh" ]; then
  TEST_SCRIPTS+=("formatters/test-formatter-isolation.sh")
  TEST_NAMES+=("formatter-isolation")
fi

if [ -f "formatters/test-nixfmt-determinism.sh" ]; then
  TEST_SCRIPTS+=("formatters/test-nixfmt-determinism.sh")
  TEST_NAMES+=("nixfmt-determinism")
fi

# Edge case tests
if [ -f "edge-cases/test-edge-cases.sh" ]; then
  TEST_SCRIPTS+=("edge-cases/test-edge-cases.sh")
  TEST_NAMES+=("edge-cases")
fi

# Local template test
if [ -f "test-local-template.sh" ]; then
  TEST_SCRIPTS+=("test-local-template.sh")
  TEST_NAMES+=("local-template")
fi

# Create jobs file for both parallel and xargs paths
JOBS_FILE="$RESULTS_DIR/jobs.txt"
for i in "${!TEST_NAMES[@]}"; do
  echo "${TEST_NAMES[$i]} ${TEST_SCRIPTS[$i]}" >>"$JOBS_FILE"
done

# Start timing
start_timer

# Run tests in parallel using GNU parallel or xargs
if command -v parallel >/dev/null 2>&1; then
  echo -e "${BLUE}Using GNU parallel${NC}\n"

  # Run parallel with progress bar
  parallel --jobs "$MAX_JOBS" --colsep ' ' --bar run_test {1} {2} :::: "$JOBS_FILE"
else
  echo -e "${BLUE}Using xargs (install GNU parallel for better output)${NC}\n"

  # Use xargs for parallel execution
  # Create temporary script for xargs that reads from the same jobs file
  cat >"$RESULTS_DIR/run_single_test.sh" <<'SCRIPT_EOF'
#!/usr/bin/env bash
source "$(dirname "$0")/../lib/timing.sh"
source "$(dirname "$0")/../lib/timeout.sh"
line_num=$1
test_line=$(sed -n "${line_num}p" "$(dirname "$0")/jobs.txt")
test_name=$(echo "$test_line" | cut -d' ' -f1)
test_script=$(echo "$test_line" | cut -d' ' -f2)

# Re-define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Re-define run_test function
run_test() {
  local test_name=$1
  local test_script=$2
  local result_file="$RESULTS_DIR/${test_name}.result"
  local log_file="$RESULTS_DIR/${test_name}.log"
  local start_time=$(date +%s)

  echo -e "${YELLOW}[STARTED]${NC} $test_name"

  # Run test and capture output with universal timeout wrapper
  if run_with_timeout 300 "bash \"$test_script\"" >"$log_file" 2>&1; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "PASS $duration" >"$result_file"
    echo -e "${GREEN}[PASSED]${NC} $test_name ($(format_duration $duration))"
    return 0
  else
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "FAIL $exit_code $duration" >"$result_file"
    echo -e "${RED}[FAILED]${NC} $test_name ($(format_duration $duration))"
    echo -e "${RED}Last 10 lines of output:${NC}"
    tail -10 "$log_file" | sed 's/^/  /'
    echo
    return 1
  fi
}

run_test "$test_name" "$test_script"
SCRIPT_EOF

  chmod +x "$RESULTS_DIR/run_single_test.sh"

  # Run tests in parallel
  seq 1 ${#TEST_NAMES[@]} | xargs -P "$MAX_JOBS" -I {} "$RESULTS_DIR/run_single_test.sh" {}
fi

# Wait for all jobs to complete
wait

# Collect results
echo -e "\n${BLUE}Collecting results...${NC}"

for test_name in "${TEST_NAMES[@]}"; do
  result_file="$RESULTS_DIR/${test_name}.result"
  if [ -f "$result_file" ]; then
    result=$(cat "$result_file")
    status=$(echo "$result" | awk '{print $1}')
    if [ "$status" = "PASS" ]; then
      ((PASSED_TESTS++))
    else
      ((FAILED_TESTS++))
    fi
  else
    echo -e "${RED}Missing result for $test_name${NC}"
    ((FAILED_TESTS++))
  fi
done

# End timing
end_timer "All tests"

# Generate summary report
SUMMARY_FILE="$RESULTS_DIR/summary.md"
cat >"$SUMMARY_FILE" <<EOF
# Test Results Summary

**Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Total Tests**: $((PASSED_TESTS + FAILED_TESTS))
**Passed**: $PASSED_TESTS
**Failed**: $FAILED_TESTS
**Parallel Jobs**: $MAX_JOBS

## Individual Test Results

| Test Name | Status | Duration | Exit Code |
|-----------|--------|----------|-----------|
EOF

# Add test results to summary
for test_name in "${TEST_NAMES[@]}"; do
  result_file="$RESULTS_DIR/${test_name}.result"
  if [ -f "$result_file" ]; then
    result=$(cat "$result_file")
    status=$(echo "$result" | awk '{print $1}')
    if [ "$status" = "PASS" ]; then
      duration=$(echo "$result" | awk '{print $2}')
      echo "| $test_name | ✅ PASS | $(format_duration $duration) | 0 |" >>"$SUMMARY_FILE"
    else
      exit_code=$(echo "$result" | awk '{print $2}')
      duration=$(echo "$result" | awk '{print $3}')
      echo "| $test_name | ❌ FAIL | $(format_duration $duration) | $exit_code |" >>"$SUMMARY_FILE"
    fi
  else
    echo "| $test_name | ⚠️ MISSING | - | - |" >>"$SUMMARY_FILE"
  fi
done

# Print summary
echo
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Test Summary                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
echo -e "  ${BLUE}Total:  $((PASSED_TESTS + FAILED_TESTS))${NC}"
echo
echo -e "${YELLOW}Detailed results saved to: $RESULTS_DIR${NC}"
echo -e "${YELLOW}Summary report: $SUMMARY_FILE${NC}"

# Exit with appropriate code
if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "\n${GREEN}All tests passed! 🎉${NC}"
  exit 0
else
  echo -e "\n${RED}Some tests failed! See logs in $RESULTS_DIR${NC}"

  # Show failed test logs
  echo -e "\n${RED}Failed test details:${NC}"
  for test_name in "${TEST_NAMES[@]}"; do
    result_file="$RESULTS_DIR/${test_name}.result"
    if [ -f "$result_file" ]; then
      result=$(cat "$result_file")
      status=$(echo "$result" | awk '{print $1}')
      if [ "$status" = "FAIL" ]; then
        echo -e "\n${RED}━━━ $test_name ━━━${NC}"
        tail -20 "$RESULTS_DIR/${test_name}.log"
      fi
    fi
  done

  exit 1
fi
