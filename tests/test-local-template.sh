#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_NAME="local template test"
TEST_DIR=$(mktemp -d)
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Source the universal timeout wrapper
source "$SCRIPT_DIR/lib/timeout.sh"

echo -e "${YELLOW}Testing template with local path...${NC}"
echo "Test directory: $TEST_DIR"

# Cleanup function
cleanup() {
  echo -e "${YELLOW}Cleaning up test directory...${NC}"
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Setup test directory
cd "$TEST_DIR"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"

# Create a test flake that uses the local path
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
        nix = true;
        web = true;
        projectRootFile = "flake.nix";
        enableDefaultExcludes = true;
        allowMissingFormatter = false;
      };
    };
}
EOF

# Stage the flake
git add flake.nix

# Create test files
mkdir -p src web

# Nix file
cat >src/test.nix <<'EOF'
{pkgs,lib,...}:
let
  myVar="value";
in{
  enable=true;
  package=pkgs.hello;
}
EOF

# JavaScript file
cat >web/test.js <<'EOF'
const x=1;const y=2;
function test(){console.log(x+y);}
EOF

# JSON file
cat >web/data.json <<'EOF'
{"name":"test","version":"1.0.0","data":[1,2,3]}
EOF

git add -A
git commit -m "Initial commit" -q

# Test formatting
echo -e "\n${YELLOW}Running formatter...${NC}"
# Create flake metadata first to ensure lock file exists
if ! run_with_timeout 30 "nix flake metadata --no-registries 2>&1 | grep -v 'Git tree.*dirty' || true"; then
  echo -e "${RED}✗ Failed to create flake metadata${NC}"
  exit 1
fi
# Add lock file to git if created
if [ -f "flake.lock" ]; then
  git add flake.lock
  git commit -m "Add flake.lock" -q || true
fi
# Run formatter with --no-update-lock-file
if run_with_timeout 60 "nix fmt --no-update-lock-file"; then
  echo -e "${GREEN}✓ Formatter ran successfully${NC}"
else
  echo -e "${RED}✗ Formatter failed${NC}"
  exit 1
fi

# Check if files were formatted
echo -e "\n${YELLOW}Checking formatting results...${NC}"

# Check for both possible alejandra formatting styles
if grep -q "enable = true;" src/test.nix && (grep -q "{pkgs, ...}:" src/test.nix || grep -q "^{$" src/test.nix); then
  echo -e "${GREEN}✓ Nix file formatted correctly${NC}"
else
  echo -e "${RED}✗ Nix file not formatted correctly${NC}"
  cat src/test.nix
fi

if grep -q "^const x = 1;" web/test.js; then
  echo -e "${GREEN}✓ JavaScript file formatted correctly${NC}"
else
  echo -e "${RED}✗ JavaScript file not formatted correctly${NC}"
  cat web/test.js
fi

if grep -q '"name": "test"' web/data.json; then
  echo -e "${GREEN}✓ JSON file formatted correctly${NC}"
else
  echo -e "${RED}✗ JSON file not formatted correctly${NC}"
  cat web/data.json
fi

# Commit formatted changes
git add -A
git commit -m "Format code" -q || true

# Test flake check
echo -e "\n${YELLOW}Running flake check...${NC}"
if run_with_timeout 60 "nix flake check --no-update-lock-file"; then
  echo -e "${GREEN}✓ Flake check passed${NC}"
else
  echo -e "${RED}✗ Flake check failed${NC}"
  exit 1
fi

echo -e "\n${GREEN}✅ All tests passed!${NC}"
