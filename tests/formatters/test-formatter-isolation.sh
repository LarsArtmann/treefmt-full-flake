#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-utils.sh"

# Test configuration
REPO_ROOT=$(cd "${BASH_SOURCE[0]}/../../.." && pwd)
TEST_DIR=$(mktemp -d)
FAILED_TESTS=0
PASSED_TESTS=0

echo -e "${BLUE}Testing formatters in isolation...${NC}"
echo "Repository root: $REPO_ROOT"
echo "Test directory: $TEST_DIR"

# Cleanup function
cleanup() {
  echo -e "\n${YELLOW}Cleaning up test directory...${NC}"
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Function to test a single formatter
test_formatter() {
  local formatter_name=$1
  local formatter_module=$2
  local test_file=$3
  local test_content=$4
  local expected_pattern=$5
  
  echo -ne "Testing ${formatter_name}... "
  
  # Create test directory
  local test_subdir="$TEST_DIR/$formatter_name"
  mkdir -p "$test_subdir"
  cd "$test_subdir"
  
  # Create flake.nix that only enables this formatter
  cat >flake.nix <<EOF
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-flake.url = "path:$REPO_ROOT";
    treefmt-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
      
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.treefmt-flake.flakeModule
      ];
      
      treefmtFlake = {
        $formatter_module = true;
        projectRootFile = "flake.nix";
        enableDefaultExcludes = true;
        allowMissingFormatter = false;
      };
    };
}
EOF
  
  # Initialize git repo (required by treefmt)
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  git add flake.nix
  
  # Create test file
  echo -e "$test_content" >"$test_file"
  git add "$test_file"
  
  # Run formatter with --no-update-lock-file to prevent unintended updates
  if run_with_timeout 30 "nix fmt --no-update-lock-file 2>&1"; then
    # Check if formatting was applied
    if grep -q "$expected_pattern" "$test_file"; then
      echo -e "${GREEN}✓${NC}"
      ((PASSED_TESTS++))
      return 0
    else
      echo -e "${RED}✗ (formatting not applied correctly)${NC}"
      echo "Expected pattern: $expected_pattern"
      echo "File content:"
      cat "$test_file"
      ((FAILED_TESTS++))
      return 1
    fi
  else
    echo -e "${RED}✗ (formatter failed to run)${NC}"
    ((FAILED_TESTS++))
    return 1
  fi
}

# Test individual formatters
echo -e "\n${YELLOW}Testing Nix formatters...${NC}"
test_formatter "alejandra" "nix" "test.nix" '{foo="bar";}' '  foo = "bar";'

echo -e "\n${YELLOW}Testing Web formatters...${NC}"
test_formatter "biome-js" "web" "test.js" 'const x=1;const y=2' 'const x = 1;'
test_formatter "biome-json" "web" "test.json" '{"Name":"test","version":"1.0"}' '"name": "test"'
test_formatter "biome-css" "web" "test.css" 'body{margin:0}' 'body {'

echo -e "\n${YELLOW}Testing Python formatters...${NC}"
test_formatter "black" "python" "test.py" 'x=1\ny=2' 'x = 1'

echo -e "\n${YELLOW}Testing Shell formatters...${NC}"
test_formatter "shfmt" "shell" "test.sh" '#!/bin/bash\nif [ "$1" = "test" ]; then\necho "ok"\nfi' '  echo "ok"'

echo -e "\n${YELLOW}Testing Rust formatter...${NC}"
test_formatter "rustfmt" "rust" "test.rs" 'fn main(){println!("hello");}' 'fn main() {'

echo -e "\n${YELLOW}Testing YAML formatter...${NC}"
test_formatter "yamlfmt" "yaml" "test.yaml" 'name:   test\nversion:    1.0' 'name: test'

echo -e "\n${YELLOW}Testing Markdown formatter...${NC}"
test_formatter "mdformat" "markdown" "test.md" '# Test\n\n\n## Section' '## Section'

echo -e "\n${YELLOW}Testing Misc formatters...${NC}"
test_formatter "taplo" "misc" "Cargo.toml" '[package]\nname="test"\nversion="0.1.0"' 'name = "test"'

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary:${NC}"
echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
echo -e "${BLUE}========================================${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "\n${GREEN}All formatter isolation tests passed!${NC}"
  exit 0
else
  echo -e "\n${RED}Some formatter isolation tests failed!${NC}"
  exit 1
fi
