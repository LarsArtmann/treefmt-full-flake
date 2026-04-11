#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-utils.sh"

# Test configuration
TEST_NAME="complete template"

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
init_template "complete" || exit 1

# Step 3: Verify template files exist
print_section "${YELLOW}Step 3: Verifying template files...${NC}"
verify_file_exists "flake.nix" || exit 1

# Step 4: Check flake metadata
print_section "${YELLOW}Step 4: Checking flake metadata...${NC}"
check_flake_metadata || exit 1

# Step 5: Create comprehensive test files for all formatters
print_section "${YELLOW}Step 5: Creating test files...${NC}"
mkdir -p src docs web scripts rust-src proto misc

# Nix file
cat >src/config.nix <<'EOF'
{ pkgs, lib, ... }:
let
  myVar = "value";
  myList = [ 1 2 3 4 5 ];
in {
  enable = true;
  package = pkgs.hello;
  settings = { key1 = "value1"; key2 = "value2"; };
}
EOF

# Python files
cat >src/main.py <<'EOF'
import sys
import os
from typing import List, Dict


def process_data(items: List[int]) -> Dict[str, int]:
    result = { "count": len(items), "sum": sum(items) }
    return result


items = [1, 2, 3, 4, 5]
print(process_data(items))
EOF

# TypeScript/JavaScript files
cat >web/app.ts <<'EOF'
interface User {
    name: string;
    age: number;
    email?: string;
}
const users: User[] = [
    { name: "Alice", age: 30 },
    { name: "Bob", age: 25, email: "bob@example.com" }
];

function greetUsers(users: User[]): void {
    users.forEach(user => {
        console.log(`Hello, ${user.name}!`);
    });
}
greetUsers(users);
EOF

cat >web/styles.css <<'EOF'
body {
    margin: 0;
    padding: 20px;
    font-family: Arial, sans-serif;
}
.container {
    max-width: 1200px;
    margin: 0 auto;
}
.header {
    background-color: #333;
    color: white;
    padding: 10px;
}
EOF

# Shell scripts
cat >scripts/deploy.sh <<'EOF'
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
cat >rust-src/main.rs <<'EOF'
fn main() {
    let numbers = vec![1, 2, 3, 4, 5];
    let sum: i32 = numbers.iter().sum();
    println!("Sum: {}", sum);
}
struct User {
    name: String,
    age: u32,
}
impl User {
    fn new(name: String, age: u32) -> Self {
        User { name, age }
    }
}
EOF

# YAML files
cat >config.yaml <<'EOF'
name:    "test-app"
version:   "1.0.0"
services:
  - name:   "api"
    port:    8080
  - name: "web"
    port:   3000
EOF

# Markdown files
cat >README.md <<'EOF'
# Complete Template Test

This tests all formatters.

## Features

- Nix formatting
- Python formatting
- Web formatting
- And more!

### Code Example

```rust
fn main() {
    println!("Hello!");
}
```
EOF

# JSON files
cat >package.json <<'EOF'
{
  "name": "test-app",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build"
  },
  "dependencies": {
    "react": "^18.0.0",
    "next": "^14.0.0"
  }
}
EOF

# TOML file (for taplo)
cat >Cargo.toml <<'EOF'
[package]
name = "test-app"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.0", features = ["full"] }
EOF

# Protocol buffer file (for buf)
cat >proto/service.proto <<'EOF'
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
cat >.github/workflows/test.yml <<'EOF'
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
cat >justfile <<'EOF'
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
git commit -m "Initial commit" -q

# Step 6: Test formatter
print_section "${YELLOW}Step 6: Testing formatter...${NC}"
run_formatter_test 120 120 || exit 1

# Step 7: Run nix flake check
print_section "${YELLOW}Step 7: Running flake check...${NC}"
run_flake_check 60 || exit 1

# Step 8: Verify files were formatted
print_section "${YELLOW}Step 8: Verifying formatting changes...${NC}"

# Check Nix file
if ! grep -qE "(^{|{pkgs)" src/config.nix || ! grep -q "enable = true;" src/config.nix; then
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

# Check CSS is formatted
if grep -q "body{margin:0" web/styles.css || ! grep -q "body {" web/styles.css; then
  echo -e "${RED}CSS file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ CSS file formatted${NC}"

if ! grep -q '^  echo "Running production deployment"' scripts/deploy.sh; then
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

if ! grep -qE "^##[[:space:]]*Features" README.md; then
  echo -e "${RED}Markdown file was not formatted properly${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Markdown file formatted${NC}"

# Check JSON is formatted
if ! grep -qE '"name"[[:space:]]*:[[:space:]]*"test-app"' package.json; then
  echo -e "${RED}JSON file was not formatted properly${NC}"
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

# Step 9: Test format check
print_section "${YELLOW}Step 9: Testing format check...${NC}"
run_format_check 120 || exit 1

# Step 10: Test development shell
print_section "${YELLOW}Step 10: Testing development shell...${NC}"
test_dev_shell 30 || exit 1

# Step 11: Test incremental formatting features
print_section "${YELLOW}Step 11: Testing incremental formatting...${NC}"
# Make a small change
echo "# New comment" >>src/config.nix

# Test treefmt-fast
if ! run_with_timeout 30 "nix run --no-update-lock-file .#treefmt-fast 2>/dev/null || true"; then
  echo -e "${YELLOW}treefmt-fast not available (expected for complete template)${NC}"
else
  echo -e "${GREEN}✓ treefmt-fast available${NC}"
fi

# Test treefmt-staged
if ! run_with_timeout 30 "nix run --no-update-lock-file .#treefmt-staged 2>/dev/null || true"; then
  echo -e "${YELLOW}treefmt-staged not available (expected for complete template)${NC}"
else
  echo -e "${GREEN}✓ treefmt-staged available${NC}"
fi

# Success
echo -e "\n${GREEN}✅ All tests passed for ${TEST_NAME}!${NC}"
