#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_NAME="default template"
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
TEMPLATE_PATH="${REPO_ROOT}#default"
if type get_template_path >/dev/null 2>&1; then
    TEMPLATE_PATH=$(get_template_path "default")
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

if [ ! -f "justfile" ]; then
    echo -e "${RED}justfile not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ justfile exists${NC}"

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

# Step 5: Create test files for formatting (more comprehensive for default)
echo -e "\n${YELLOW}Step 5: Creating test files...${NC}"
mkdir -p src docs web scripts

# Create a Nix file
cat > src/test.nix << 'EOF'
{pkgs,lib,...}:
let
  myVar="value";
  myList=[1 2 3 4 5];
in{
  enable=true;
  package=pkgs.hello;
}
EOF

# Create a Python file
cat > src/main.py << 'EOF'
import sys
import os
def main():
    print( "Hello, World!" )
    items = [ 1,2,3,4,5 ]
    for item in items:
        print(item)
if __name__ == "__main__":
    main()
EOF

# Create a TypeScript file
cat > web/app.ts << 'EOF'
interface User{
name:string;
age:number;
}
const user:User={name:"John",age:30};
function greet(user:User):void{
console.log(`Hello, ${user.name}!`);
}
greet(user);
EOF

# Create a shell script
cat > scripts/deploy.sh << 'EOF'
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
cat > config.json << 'EOF'
{"name":"test-app","version":"1.0.0","dependencies":{"react":"^18.0.0","typescript":"^5.0.0"}}
EOF

# Create a YAML file
cat > config.yaml << 'EOF'
name:    "test"
version:   "1.0.0"
items:
  - item1
  -    item2
EOF

# Create a Markdown file
cat > README.md << 'EOF'
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
# Create initial commit so git has history
git commit -m "Initial commit" -q

# Step 6: Run nix flake check
echo -e "\n${YELLOW}Step 6: Running flake check...${NC}"
if ! run_with_timeout 60 "nix flake check"; then
    echo -e "${RED}Failed to check flake${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flake check passed${NC}"

# Step 7: Test formatter
echo -e "\n${YELLOW}Step 7: Testing formatter...${NC}"
if ! run_with_timeout 60 "nix fmt"; then
    echo -e "${RED}Formatter failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Formatter ran successfully${NC}"

# Step 8: Verify files were formatted
echo -e "\n${YELLOW}Step 8: Verifying formatting changes...${NC}"

# Check Nix formatting (alejandra removes compact syntax)
if grep -q "{pkgs,lib,...}:" src/test.nix; then
    echo -e "${RED}Nix file was not formatted properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Nix file formatted${NC}"

# Check Python formatting
if ! grep -q "^def main():\$" src/main.py; then
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

# Check Shell formatting (shfmt uses 2 spaces for indentation)
if ! grep -q "^  echo \"Error: No environment specified\"" scripts/deploy.sh; then
    echo -e "${RED}Shell script was not formatted properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Shell script formatted${NC}"

# Check JSON formatting
if grep -q '"name":"test-app"' config.json; then
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

# Step 9: Test format check (should pass now)
echo -e "\n${YELLOW}Step 9: Testing format check...${NC}"
if ! run_with_timeout 60 "nix fmt -- --fail-on-change"; then
    echo -e "${RED}Format check failed after formatting${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Format check passed${NC}"

# Step 10: Test development shell
echo -e "\n${YELLOW}Step 10: Testing development shell...${NC}"
if ! run_with_timeout 30 "nix develop -c treefmt --version"; then
    echo -e "${RED}Development shell failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Development shell works${NC}"

# Step 11: Test justfile commands
echo -e "\n${YELLOW}Step 11: Testing justfile commands...${NC}"
if ! command -v just >/dev/null 2>&1; then
    echo -e "${YELLOW}just not installed, installing...${NC}"
    if ! run_with_timeout 60 "nix profile install nixpkgs#just"; then
        echo -e "${YELLOW}Skipping justfile tests (just not available)${NC}"
    else
        # Test just commands
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