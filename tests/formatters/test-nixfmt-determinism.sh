#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-utils.sh"

# Test configuration
REPO_ROOT=$(cd "${BASH_SOURCE[0]}/../../.." && pwd)
TEST_DIR=$(mktemp -d)

echo -e "${BLUE}Testing nixfmt-rfc-style determinism...${NC}"
echo "Repository root: $REPO_ROOT"
echo "Test directory: $TEST_DIR"

# Cleanup function
cleanup() {
  echo -e "\n${YELLOW}Cleaning up test directory...${NC}"
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test nixfmt-rfc-style determinism
test_nixfmt_determinism() {
  echo -e "\n${YELLOW}Setting up test environment...${NC}"
  
  cd "$TEST_DIR"
  
  # Create flake.nix with nixfmt-rfc-style
  cat >flake.nix <<'EOF'
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-flake.url = "path:REPO_ROOT";
    treefmt-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.treefmt-flake.flakeModule
      ];

      treefmtFlake = {
        nix = true;
        nixFormatter = "nixfmt-rfc-style";
        projectRootFile = "flake.nix";
        enableDefaultExcludes = true;
        allowMissingFormatter = false;
      };
    };
}
EOF
  
  # Replace REPO_ROOT placeholder
  sed -i.bak "s|REPO_ROOT|$REPO_ROOT|" flake.nix
  rm -f flake.nix.bak
  
  # Initialize git repo
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  
  # Create test file with potentially problematic formatting
  cat >test.nix <<'EOF'
{
  # This is a test file with various formatting patterns
  foo = {
    bar = "baz";
    nested = {
      deeply = {
        value = 42;
      };
    };
  };

  # Function with arguments
  myFunction = { arg1, arg2, ... }@args:
    let
      helper = x: x + 1;
    in
    helper arg1 + arg2;

  # List with mixed formatting
  list = [
    1
    2
    (3 + 4)
    { key = "value"; }
  ];

  # Attribute set with various patterns
  attrs = {
    "string-key" = true;
    inherit foo;
    passthru = { inherit list; };
  };
}
EOF
  
  git add .
  
  echo -e "\n${YELLOW}Running formatter multiple times to test determinism...${NC}"
  
  # First run
  echo -n "First run: "
  if run_with_timeout 30 "nix fmt --no-update-lock-file 2>&1"; then
    echo -e "${GREEN}✓${NC}"
    cp test.nix test.nix.run1
  else
    echo -e "${RED}✗ Failed${NC}"
    return 1
  fi
  
  # Second run
  echo -n "Second run: "
  if run_with_timeout 30 "nix fmt --no-update-lock-file 2>&1"; then
    echo -e "${GREEN}✓${NC}"
    cp test.nix test.nix.run2
  else
    echo -e "${RED}✗ Failed${NC}"
    return 1
  fi
  
  # Third run
  echo -n "Third run: "
  if run_with_timeout 30 "nix fmt --no-update-lock-file 2>&1"; then
    echo -e "${GREEN}✓${NC}"
    cp test.nix test.nix.run3
  else
    echo -e "${RED}✗ Failed${NC}"
    return 1
  fi
  
  # Compare outputs
  echo -e "\n${YELLOW}Comparing outputs...${NC}"
  
  if diff -q test.nix.run1 test.nix.run2 >/dev/null && diff -q test.nix.run2 test.nix.run3 >/dev/null; then
    echo -e "${GREEN}✓ All runs produced identical output - formatter is deterministic!${NC}"
    return 0
  else
    echo -e "${RED}✗ Outputs differ - formatter is NOT deterministic${NC}"
    echo -e "\n${YELLOW}Differences between runs:${NC}"
    diff -u test.nix.run1 test.nix.run2 || true
    diff -u test.nix.run2 test.nix.run3 || true
    return 1
  fi
}

# Compare alejandra vs nixfmt-rfc-style
compare_formatters() {
  echo -e "\n${BLUE}========================================${NC}"
  echo -e "${BLUE}Comparing formatters side by side${NC}"
  echo -e "${BLUE}========================================${NC}"
  
  local COMPARE_DIR="$TEST_DIR/compare"
  mkdir -p "$COMPARE_DIR"
  
  # Create test file
  cat >"$COMPARE_DIR/test.nix" <<'EOF'
{foo={bar="baz";nested={deeply={value=42;};};};myFunction={arg1,arg2,...}@args:let helper=x:x+1;in helper arg1+arg2;}
EOF
  
  # Test with alejandra
  echo -e "\n${YELLOW}Testing Alejandra...${NC}"
  cd "$COMPARE_DIR"
  cp "$REPO_ROOT/flake.nix" flake-alejandra.nix
  sed -i.bak 's/nixFormatter = "nixfmt-rfc-style"/nixFormatter = "alejandra"/' flake-alejandra.nix 2>/dev/null || true
  rm -f flake-alejandra.nix.bak
  
  # Create temporary flake for alejandra
  mkdir alejandra-test
  cd alejandra-test
  cp ../test.nix .
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

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.treefmt-flake.flakeModule
      ];

      treefmtFlake = {
        nix = true;
        nixFormatter = "alejandra";  # Explicitly use alejandra
        projectRootFile = "flake.nix";
      };
    };
}
EOF
  
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  git add .
  
  echo "Running alejandra formatter..."
  if run_with_timeout 30 "nix fmt --no-update-lock-file 2>&1"; then
    cp test.nix ../alejandra-output.nix
    echo -e "${GREEN}✓ Alejandra completed${NC}"
  else
    echo -e "${RED}✗ Alejandra failed${NC}"
  fi
  
  cd ..
  
  echo -e "\n${YELLOW}Summary:${NC}"
  echo "Original file: $(wc -l <test.nix) lines"
  if [ -f alejandra-output.nix ]; then
    echo "Alejandra output: $(wc -l <alejandra-output.nix) lines"
  fi
  if [ -f "$TEST_DIR/test.nix.run1" ]; then
    echo "nixfmt-rfc-style output: $(wc -l <"$TEST_DIR/test.nix.run1") lines"
  fi
}

# Main test execution
echo -e "${BLUE}Running nixfmt-rfc-style determinism test...${NC}"

if test_nixfmt_determinism; then
  echo -e "\n${GREEN}✅ nixfmt-rfc-style is deterministic!${NC}"
  RESULT=0
else
  echo -e "\n${RED}❌ nixfmt-rfc-style is NOT deterministic${NC}"
  RESULT=1
fi

# Run comparison
compare_formatters

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Test Complete${NC}"
echo -e "${BLUE}========================================${NC}"

exit $RESULT
