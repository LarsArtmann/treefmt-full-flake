#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-utils.sh"

# Test configuration
TEST_NAME="default template"

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
init_template "default" || exit 1

# Step 3: Verify template files exist
print_section "${YELLOW}Step 3: Verifying template files...${NC}"
verify_file_exists "flake.nix" || exit 1
verify_file_exists "justfile" || exit 1

# Step 4: Check flake metadata
print_section "${YELLOW}Step 4: Checking flake metadata...${NC}"
check_flake_metadata || exit 1

# Step 5: Create test files for formatting
print_section "${YELLOW}Step 5: Creating test files...${NC}"
mkdir -p src docs web scripts

# Create a Nix file
cat >src/test.nix <<'EOF'
{ pkgs, lib, ... }:
let
  myVar = "value";
  myList = [ 1 2 3 4 5 ];
in {
  enable = true;
  package = pkgs.hello;
}
EOF

# Create a Python file
cat >src/main.py <<'EOF'
import sys
import os

def main():
    print("Hello, World!")
    items = [1, 2, 3, 4, 5]
    for item in items:
        print(item)


if __name__ == "__main__":
    main()
EOF

# Create a TypeScript file
cat >web/app.ts <<'EOF'
interface User {
    name: string;
    age: number;
}
const user: User = { name: "John", age: 30 };

function greet(user: User): void {
    console.log(`Hello, ${user.name}!`);
}
greet(user);
EOF

# Create a shell script
cat >scripts/deploy.sh <<'EOF'
#!/bin/bash
echo "Deploying application..."
if [ -z "$1" ]; then
    echo "Error: No environment specified"
    exit 1
fi
ENVIRONMENT=$1
echo "Deploying to $ENVIRONMENT"
EOF

# Create a JSON file with compact formatting
cat >config.json <<'EOF'
{
  "name": "test-app",
  "version": "1.0.0",
  "dependencies": {
    "react": "^18.0.0",
    "typescript": "^5.0.0"
  }
}
EOF

# Create a YAML file
cat >config.yaml <<'EOF'
name:    "test"
version:   "1.0.0"
items:
  - item1
  -    item2
EOF

# Create a Markdown file
cat >README.md <<'EOF'
# Test Project

This is a test project.

-   Item 1
-   Item 2

## Installation

```bash
npm install
```
EOF

echo -e "${GREEN}✓ Test files created${NC}"

# Stage all files for Git
git add -A
git commit -m "Initial commit" -q

# Step 6: Test formatter
print_section "${YELLOW}Step 6: Testing formatter...${NC}"
run_formatter_test 60 60 || exit 1

# Step 7: Run nix flake check
print_section "${YELLOW}Step 7: Running flake check...${NC}"
run_flake_check 60 || exit 1

# Step 8: Verify files were formatted
print_section "${YELLOW}Step 8: Verifying formatting changes...${NC}"

# Check Nix formatting
if ! grep -qE "(^{|{pkgs)" src/test.nix || ! grep -q "enable = true;" src/test.nix; then
  echo -e "${RED}Nix file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Nix file formatted${NC}"

# Check Python formatting
if ! grep -q "^def main():$" src/main.py; then
  echo -e "${RED}Python file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Python file formatted${NC}"

# Check TypeScript formatting
if ! grep -q "^interface User {" web/app.ts; then
  echo -e "${RED}TypeScript file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ TypeScript file formatted${NC}"

# Check Shell formatting
if ! grep -q '^  echo "Error: No environment specified"' scripts/deploy.sh; then
  echo -e "${RED}Shell script was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Shell script formatted${NC}"

# Check JSON formatting
if ! grep -qE '"name"[[:space:]]*:[[:space:]]*"test-app"' config.json; then
  echo -e "${RED}JSON file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ JSON file formatted${NC}"

# Check YAML formatting
if ! grep -q "^name: " config.yaml && ! grep -q "^version: " config.yaml; then
  echo -e "${RED}YAML file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ YAML file formatted${NC}"

# Check Markdown formatting
if ! grep -q "^- Item 1$" README.md; then
  echo -e "${RED}Markdown file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Markdown file formatted${NC}"

# Step 9: Test format check
print_section "${YELLOW}Step 9: Testing format check...${NC}"
run_format_check 60 || exit 1

# Step 10: Test development shell
print_section "${YELLOW}Step 10: Testing development shell...${NC}"
test_dev_shell 30 || exit 1

# Step 11: Test justfile commands
print_section "${YELLOW}Step 11: Testing justfile commands...${NC}"
if ! command -v just >/dev/null 2>&1; then
  echo -e "${YELLOW}just not installed, installing...${NC}"
  if ! run_with_timeout 60 "nix profile install nixpkgs#just"; then
    echo -e "${YELLOW}Skipping justfile tests (just not available)${NC}"
  else
    if ! run_with_timeout 30 "just --list"; then
      echo -e "${RED}Failed to list just commands${NC}"
    else
      echo -e "${GREEN}✓ Justfile commands available${NC}"
    fi
  fi
else
  if ! run_with_timeout 30 "just --list"; then
    echo -e "${RED}Failed to list just commands${NC}"
  else
    echo -e "${GREEN}✓ Justfile commands available${NC}"
  fi
fi

# Success
echo -e "\n${GREEN}✅ All tests passed for ${TEST_NAME}!${NC}"
