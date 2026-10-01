#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-utils.sh"

# Test configuration
TEST_NAME="minimal template"

# Initialize test environment
init_test_environment "$TEST_NAME"

# Setup cleanup trap
setup_cleanup

# Step 1: Setup test directory and git
print_section "${YELLOW}Step 1: Setting up test directory...${NC}"
cd "$TEST_DIR"
setup_git_repo

# Step 2: Initialize the template
print_section "${YELLOW}Step 2: Initializing template...${NC}"
init_template "minimal" || exit 1

# Step 3: Verify template files exist
print_section "${YELLOW}Step 3: Verifying template files...${NC}"
verify_file_exists "flake.nix" || exit 1

# Step 4: Check flake metadata
print_section "${YELLOW}Step 4: Checking flake metadata...${NC}"
check_flake_metadata || exit 1

# Step 5: Create test files for formatting
print_section "${YELLOW}Step 5: Creating test files...${NC}"
mkdir -p src docs

# Create a Nix file with formatting issues
cat >src/test.nix <<'EOF'
{ pkgs, lib, ... }:
let
  myVar = "value";
  myList = [ 1 2 3 4 5 ];
in {
  enable = true;
  package = pkgs.hello;
  config = {
    key1 = "value1";
    key2 = "value2";
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
git commit -m "Initial commit" -q

# Step 6: Test formatter
print_section "${YELLOW}Step 6: Testing formatter...${NC}"
run_formatter_test 30 60 || exit 1

# Step 7: Run nix flake check
print_section "${YELLOW}Step 7: Running flake check...${NC}"
run_flake_check 60 || exit 1

# Step 8: Verify files were formatted
print_section "${YELLOW}Step 8: Verifying formatting changes...${NC}"

# Check Nix file
if ! grep -qE "(^{|{pkgs)" src/test.nix || ! grep -q "pkgs.hello" src/test.nix; then
  echo -e "${RED}Nix file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Nix file formatted${NC}"

# Check Markdown file
if ! grep -q "^- Item 1$" docs/README.md; then
  echo -e "${RED}Markdown file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Markdown file formatted${NC}"

# Check YAML file
if ! grep -q "^name: " config.yaml && ! grep -q "^version: " config.yaml; then
  echo -e "${RED}YAML file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ YAML file formatted${NC}"

# Step 9: Test format check
print_section "${YELLOW}Step 9: Testing format check...${NC}"
run_format_check 60 || exit 1

# Step 10: Test development shell
print_section "${YELLOW}Step 10: Testing development shell...${NC}"
test_dev_shell 30 || exit 1

# Success
echo -e "\n${GREEN}✅ All tests passed for ${TEST_NAME}!${NC}"
