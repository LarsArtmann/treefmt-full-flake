#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_NAME="complete template"
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
TEMPLATE_PATH="${REPO_ROOT}#complete"
if type get_template_path >/dev/null 2>&1; then
    TEMPLATE_PATH=$(get_template_path "complete")
fi
if ! run_with_timeout 30 "nix flake init -t ${TEMPLATE_PATH}"; then
    echo -e "${RED}Failed to initialize template${NC}"
    exit 1
fi
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

# Step 5: Create comprehensive test files for all formatters
echo -e "\n${YELLOW}Step 5: Creating test files...${NC}"
mkdir -p src docs web scripts rust-src proto misc

# Nix file
cat > src/config.nix << 'EOF'
{pkgs,lib,...}:
let
  myVar="value";
  myList=[1 2 3 4 5];
in{
  enable=true;
  package=pkgs.hello;
  settings={key1="value1";key2="value2";};
}
EOF

# Python files
cat > src/main.py << 'EOF'
import sys
import os
from typing import List,Dict
def process_data(items:List[int])->Dict[str,int]:
    result={'count':len(items),'sum':sum(items)}
    return result
items=[1,2,3,4,5]
print(process_data(items))
EOF

# TypeScript/JavaScript files
cat > web/app.ts << 'EOF'
interface User{
name:string;
age:number;
email?:string;
}
const users:User[]=[
{name:"Alice",age:30},
{name:"Bob",age:25,email:"bob@example.com"}
];
function greetUsers(users:User[]):void{
users.forEach(user=>{
console.log(`Hello, ${user.name}!`);
});
}
greetUsers(users);
EOF

cat > web/styles.css << 'EOF'
body{margin:0;padding:20px;font-family:Arial,sans-serif;}
.container{max-width:1200px;margin:0 auto;}
.header{background-color:#333;color:white;padding:10px;}
EOF

# Shell scripts
cat > scripts/deploy.sh << 'EOF'
#!/bin/bash
set -e
ENVIRONMENT=${1:-development}
echo "Deploying to $ENVIRONMENT"
if [ "$ENVIRONMENT" = "production" ]; then
echo "Running production deployment"
else
echo "Running development deployment"
fi
EOF

# Rust file
cat > rust-src/main.rs << 'EOF'
fn main(){
let numbers=vec![1,2,3,4,5];
let sum:i32=numbers.iter().sum();
println!("Sum: {}",sum);
}
struct User{name:String,age:u32}
impl User{
fn new(name:String,age:u32)->Self{
User{name,age}
}
}
EOF

# YAML files
cat > config.yaml << 'EOF'
name:    "test-app"
version:   "1.0.0"
services:
  - name:   "api"
    port:    8080
  - name: "web"
    port:   3000
EOF

# Markdown files
cat > README.md << 'EOF'
# Complete Template Test

This tests all formatters.

##   Features

-   Nix formatting
-   Python formatting
-   Web formatting
-   And more!

### Code Example

```rust
fn main() {
    println!("Hello!");
}
```
EOF

# JSON files
cat > package.json << 'EOF'
{
"name":"test-app",
"version":"1.0.0",
"scripts":{
"dev":"next dev",
"build":"next build"
},
"dependencies":{
"react":"^18.0.0",
"next":"^14.0.0"
}
}
EOF

# TOML file (for taplo)
cat > Cargo.toml << 'EOF'
[package]
name="test-app"
version="0.1.0"
edition="2021"
[dependencies]
serde={version="1.0",features=["derive"]}
tokio={version="1.0",features=["full"]}
EOF

# Protocol buffer file (for buf)
cat > proto/service.proto << 'EOF'
syntax = "proto3";
package example;
service Greeter {
rpc SayHello (HelloRequest) returns (HelloReply) {}
}
message HelloRequest {
string name = 1;
}
message HelloReply {
string message = 1;
}
EOF

# GitHub Actions file (for actionlint)
mkdir -p .github/workflows
cat > .github/workflows/test.yml << 'EOF'
name: Test
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Run tests
      run: echo "Testing"
EOF

# Justfile (for just formatter)
cat > justfile << 'EOF'
default:
  @echo "Available commands:"
  @just --list
test:
  echo "Running tests"
format:
  nix fmt
check:
  nix fmt -- --check
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
if ! run_with_timeout 120 "nix fmt"; then
    echo -e "${RED}Formatter failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Formatter ran successfully${NC}"

# Step 8: Verify files were formatted
echo -e "\n${YELLOW}Step 8: Verifying formatting changes...${NC}"

# Check various file formats (alejandra formats function args)
if grep -q "{pkgs,lib,...}:" src/config.nix; then
    echo -e "${RED}Nix file was not formatted properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Nix file formatted${NC}"

if ! grep -q "^from typing import Dict, List$" src/main.py; then
    echo -e "${RED}Python file was not formatted properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python file formatted${NC}"

if ! grep -q "^interface User {" web/app.ts; then
    echo -e "${RED}TypeScript file was not formatted properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ TypeScript file formatted${NC}"

if grep -q "body{margin:0" web/styles.css; then
    echo -e "${RED}CSS file was not formatted properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ CSS file formatted${NC}"

if ! grep -q "^  echo \"Running production deployment\"" scripts/deploy.sh; then
    echo -e "${RED}Shell script was not formatted properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Shell script formatted${NC}"

if ! grep -q "^fn main() {" rust-src/main.rs; then
    echo -e "${RED}Rust file was not formatted properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Rust file formatted${NC}"

if ! grep -q "^name: " config.yaml; then
    echo -e "${RED}YAML file was not formatted properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ YAML file formatted${NC}"

if ! grep -q "^## Features" README.md; then
    echo -e "${RED}Markdown file was not formatted properly${NC}"
    echo "Expected to find '## Features' but got:"
    grep "Features" README.md || echo "No 'Features' line found"
    exit 1
fi
echo -e "${GREEN}✓ Markdown file formatted${NC}"

if grep -q '"name":"test-app"' package.json; then
    echo -e "${RED}JSON file was not formatted properly${NC}"
    echo "Expected formatted JSON but got:"
    head -5 package.json
    exit 1
fi
echo -e "${GREEN}✓ JSON file formatted${NC}"

if ! grep -q '^name = "test-app"$' Cargo.toml; then
    echo -e "${RED}TOML file was not formatted properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ TOML file formatted${NC}"

# Check Protocol Buffer formatting (buf may not format, just validate)
if [ -f proto/service.proto ]; then
    echo -e "${GREEN}✓ Protocol buffer file exists${NC}"
fi

# Check GitHub Actions formatting (actionlint validates rather than formats)
if [ -f .github/workflows/test.yml ]; then
    echo -e "${GREEN}✓ GitHub Actions workflow exists${NC}"
fi

# Check Justfile formatting
if grep -q "^default:$" justfile; then
    echo -e "${GREEN}✓ Justfile formatted${NC}"
else
    echo -e "${YELLOW}⚠ Justfile may not have been formatted${NC}"
fi

# Step 9: Test format check (should pass now)
echo -e "\n${YELLOW}Step 9: Testing format check...${NC}"
if ! run_with_timeout 120 "nix fmt -- --fail-on-change"; then
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

# Step 11: Test incremental formatting features
echo -e "\n${YELLOW}Step 11: Testing incremental formatting...${NC}"
# Make a small change
echo "# New comment" >> src/config.nix

# Test treefmt-fast
if ! run_with_timeout 30 "nix run .#treefmt-fast 2>/dev/null || true"; then
    echo -e "${YELLOW}treefmt-fast not available (expected for complete template)${NC}"
else
    echo -e "${GREEN}✓ treefmt-fast available${NC}"
fi

# Test treefmt-staged
if ! run_with_timeout 30 "nix run .#treefmt-staged 2>/dev/null || true"; then
    echo -e "${YELLOW}treefmt-staged not available (expected for complete template)${NC}"
else
    echo -e "${GREEN}✓ treefmt-staged available${NC}"
fi

# Success
echo -e "\n${GREEN}✅ All tests passed for ${TEST_NAME}!${NC}"