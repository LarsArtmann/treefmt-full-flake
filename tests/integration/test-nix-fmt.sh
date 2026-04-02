#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
CMD_DIR="$PROJECT_ROOT/cmd"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Nix Fmt Integration Test         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

FAILED=0
PASSED=0

# Test function
run_test() {
  local test_name="$1"
  local test_cmd="$2"

  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}Running: ${test_name}${NC}"

  if eval "$test_cmd"; then
    echo -e "${GREEN}✅ ${test_name} passed${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}❌ ${test_name} failed${NC}"
    FAILED=$((FAILED + 1))
  fi
  echo ""
}

cd "$PROJECT_ROOT"

# Test 1: nix fmt --fail-on-change (check mode)
run_test "nix fmt check (--fail-on-change)" "nix fmt -- --fail-on-change"

# Test 2: nix flake check passes
run_test "nix flake check passes" "nix flake check"

# Test 3: Build the test-validation package
run_test "Build test-validation package" "nix build .#test-validation"

# Test 4: Build the treefmt-debug package
run_test "Build treefmt-debug package" "nix build .#treefmt-debug"

# Test 5: Build the treefmt-validate package
run_test "Build treefmt-validate package" "nix build .#treefmt-validate"

# Test 6: Verify Go code compiles (for branching-flow integration)
run_test "Go code compiles" "cd $CMD_DIR/treefmt-test-helper && go build -o /dev/null ."

# Test 7: branching-flow linting on Go code
run_test "branching-flow linting" "branching-flow all $CMD_DIR"

# Summary
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Test Summary               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "Total: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
echo -e "${RED}Failed: ${FAILED}${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ All integration tests passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ ${FAILED} test(s) failed${NC}"
  exit 1
fi
