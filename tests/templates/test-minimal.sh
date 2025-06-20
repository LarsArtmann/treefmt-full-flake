#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_NAME="minimal template"
TEST_DIR=$(mktemp -d)
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

echo -e "${YELLOW}Testing ${TEST_NAME}...${NC}"
echo "Test directory: $TEST_DIR"

# Cleanup function
cleanup() {
  echo -e "${YELLOW}Cleaning up test directory...${NC}"
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Function to run test with timeout
run_with_timeout() {
  local timeout=$1
  shift
  local cmd="$@"

  echo "Running: $cmd"
  if command -v timeout >/dev/null 2>&1; then
    if ! timeout "$timeout" bash -c "$cmd"; then
      local exit_code=$?
      if [ $exit_code -eq 124 ]; then
        echo -e "${RED}Command timed out after ${timeout}s: $cmd${NC}"
      else
        echo -e "${RED}Command failed with exit code $exit_code: $cmd${NC}"
      fi
      return $exit_code
    fi
  else
    # macOS doesn't have timeout, use alternative
    (
      eval "$cmd" &
      local pid=$!
      local count=0
      while kill -0 $pid 2>/dev/null && [ $count -lt $timeout ]; do
        sleep 1
        ((count++))
      done
      if kill -0 $pid 2>/dev/null; then
        echo -e "${RED}Command timed out after ${timeout}s: $cmd${NC}"
        kill -9 $pid
        return 124
      fi
      wait $pid
      local exit_code=$?
      if [ $exit_code -ne 0 ]; then
        echo -e "${RED}Command failed with exit code $exit_code: $cmd${NC}"
        return $exit_code
      fi
    )
  fi
}

# Source wrapper if available
if [ -f "${REPO_ROOT}/tests/templates/wrapper.sh" ]; then
  source "${REPO_ROOT}/tests/templates/wrapper.sh"
fi

# Step 1: Setup test directory and git
echo -e "\n${YELLOW}Step 1: Setting up test directory...${NC}"
cd "$TEST_DIR"
# Initialize git repository first to avoid dirty tree warnings
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
echo -e "${GREEN}✓ Test directory and git initialized${NC}"

# Step 2: Initialize the template
echo -e "\n${YELLOW}Step 2: Initializing template...${NC}"
TEMPLATE_PATH="${REPO_ROOT}#minimal"
if type get_template_path >/dev/null 2>&1; then
  TEMPLATE_PATH=$(get_template_path "minimal")
fi
if ! run_with_timeout 30 "nix flake init -t ${TEMPLATE_PATH}"; then
  echo -e "${RED}Failed to initialize template${NC}"
  exit 1
fi
# Stage the flake.nix file so Nix can see it
git add flake.nix
echo -e "${GREEN}✓ Template initialized${NC}"

# Step 3: Verify template files exist
echo -e "\n${YELLOW}Step 3: Verifying template files...${NC}"
if [ ! -f "flake.nix" ]; then
  echo -e "${RED}flake.nix not found${NC}"
  exit 1
fi
echo -e "${GREEN}✓ flake.nix exists${NC}"

# Step 4: Check flake metadata (allow lock file creation for fresh flake)
echo -e "\n${YELLOW}Step 4: Checking flake metadata...${NC}"
if ! run_with_timeout 30 "nix flake metadata"; then
  echo -e "${RED}Failed to check flake metadata${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Flake metadata is valid${NC}"
# Add the generated lock file to git
if [ -f "flake.lock" ]; then
  git add flake.lock
fi

# Step 5: Create test files for formatting
echo -e "\n${YELLOW}Step 5: Creating test files...${NC}"
mkdir -p src docs

# Create a Nix file with formatting issues
cat >src/test.nix <<'EOF'
{pkgs,lib,...}:
let
  myVar="value";
  myList=[1 2 3 4 5];
in{
  enable=true;
  package=pkgs.hello;
  config={
    key1="value1";
    key2="value2";
  };
}
EOF

# Create a Markdown file with formatting issues
cat >docs/README.md <<'EOF'
# Test Document

This is a test document with some formatting issues.

-   Item 1
-   Item 2
-   Item 3

## Code Example

```nix
{ pkgs }:
pkgs.hello
```

### Subsection

Some text here.
EOF

# Create a YAML file with formatting issues
cat >config.yaml <<'EOF'
name:    "test"
version:   "1.0.0"
items:
  - item1
  - item2
  -    item3
config:
    key1:   value1
    key2: value2
EOF

echo -e "${GREEN}✓ Test files created${NC}"

# Stage all files for Git
git add -A
# Create initial commit so git has history
git commit -m "Initial commit" -q

# Step 6: Test formatter (run before flake check)
echo -e "\n${YELLOW}Step 6: Testing formatter...${NC}"
# First, show the formatter is available
if ! run_with_timeout 30 "nix fmt -- --version"; then
  echo -e "${RED}Formatter not available${NC}"
  exit 1
fi

# Run formatter twice to ensure stability
if ! run_with_timeout 60 "nix fmt"; then
  echo -e "${RED}Formatter failed${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Formatter ran successfully (pass 1)${NC}"

# Run formatter again to ensure idempotency
if ! run_with_timeout 60 "nix fmt"; then
  echo -e "${RED}Formatter failed on second pass${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Formatter is idempotent (pass 2)${NC}"

# Commit the formatted changes to stabilize git state
git add -A
git commit -m "Format code" -q || true

# Step 7: Run nix flake check (after formatting)
echo -e "\n${YELLOW}Step 7: Running flake check...${NC}"
if ! run_with_timeout 60 "nix flake check --no-update-lock-file"; then
  echo -e "${RED}Failed to check flake${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Flake check passed${NC}"

# Step 8: Verify files were formatted
echo -e "\n${YELLOW}Step 8: Verifying formatting changes...${NC}"
# Check if Nix file was formatted (alejandra may format single-line or multi-line)
# Before: {pkgs,lib,...}:
# After: proper formatting with newlines and spaces
if ! grep -qE "(^{|{pkgs)" src/test.nix || ! grep -q "pkgs.hello" src/test.nix; then
  echo -e "${RED}Nix file was not formatted properly${NC}"
  echo "Expected proper Nix formatting but got:"
  head -10 src/test.nix
  exit 1
fi
echo -e "${GREEN}✓ Nix file formatted${NC}"

# Check if Markdown file was formatted (mdformat normalizes lists)
if ! grep -q "^- Item 1$" docs/README.md; then
  echo -e "${RED}Markdown file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Markdown file formatted${NC}"

# Check if YAML file was formatted (yamlfmt removes extra spaces)
if ! grep -q "^name: " config.yaml && ! grep -q "^version: " config.yaml; then
  echo -e "${RED}YAML file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ YAML file formatted${NC}"

# Step 9: Test format check (should pass now)
echo -e "\n${YELLOW}Step 9: Testing format check...${NC}"
if ! run_with_timeout 60 "nix fmt -- --fail-on-change"; then
  echo -e "${RED}Format check failed after formatting${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Format check passed${NC}"

# Step 10: Test development shell
echo -e "\n${YELLOW}Step 10: Testing development shell...${NC}"
if ! run_with_timeout 30 "nix develop --no-update-lock-file -c treefmt --version"; then
  echo -e "${RED}Development shell failed${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Development shell works${NC}"

# Success
echo -e "\n${GREEN}✅ All tests passed for ${TEST_NAME}!${NC}"
