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

# Detect system for proper package paths
SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem' 2>/dev/null || echo "aarch64-darwin")

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Nix Fmt Integration Test         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Detected system: $SYSTEM"
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
    echo -e "${GREEN}✓ ${test_name} passed${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}✗ ${test_name} failed${NC}"
    FAILED=$((FAILED + 1))
  fi
  echo ""
}

cd "$PROJECT_ROOT"

# Test 1: nix flake check --no-build (fast check)
run_test "nix flake check --no-build" "nix flake check --no-build"

# Test 2: Build the treefmt-debug package
run_test "Build treefmt-debug package" "nix build ".#${SYSTEM}.treefmt-debug" --no-link"

# Test 3: Build the treefmt-validate package
run_test "Build treefmt-validate package" "nix build ".#${SYSTEM}.treefmt-validate" --no-link"

# Test 4: treefmt-debug runs successfully
run_test "treefmt-debug execution" "nix run ".#${SYSTEM}.treefmt-debug""

# Test 5: treefmt-validate runs successfully
run_test "treefmt-validate execution" "nix run ".#${SYSTEM}.treefmt-validate""

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
  echo -e "${GREEN}✓ All integration tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ ${FAILED} test(s) failed${NC}"
  exit 1
fi
