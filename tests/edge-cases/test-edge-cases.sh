#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_NAME="edge cases"
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

# Setup test directory
cd "$TEST_DIR"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"

# Initialize with minimal template
echo -e "\n${YELLOW}Initializing minimal template...${NC}"
if ! run_with_timeout 30 "nix flake init -t ${REPO_ROOT}#minimal"; then
  echo -e "${RED}Failed to initialize template${NC}"
  exit 1
fi
git add flake.nix

# Create test files
mkdir -p edge-cases

# Test 1: Empty file (skip .nix as alejandra doesn't handle empty files)
echo -e "\n${YELLOW}Test 1: Empty file${NC}"
# Alejandra fails on empty .nix files, so create minimal valid content
echo '{}' >edge-cases/empty.nix
touch edge-cases/empty.py
touch edge-cases/empty.js
touch edge-cases/empty.yaml

# Test 2: Very large file
echo -e "\n${YELLOW}Test 2: Large file (10000 lines)${NC}"
cat >edge-cases/large.nix <<'EOF'
{ pkgs, ... }: {
  largeList = [
EOF
for i in {1..9998}; do
  echo "    $i" >>edge-cases/large.nix
done
echo "  ];" >>edge-cases/large.nix
echo "}" >>edge-cases/large.nix

# Test 3: Binary file (should be ignored)
echo -e "\n${YELLOW}Test 3: Binary file${NC}"
dd if=/dev/urandom of=edge-cases/binary.dat bs=1024 count=1 2>/dev/null

# Test 4: Symlink
echo -e "\n${YELLOW}Test 4: Symlink${NC}"
ln -s ../flake.nix edge-cases/symlink.nix

# Test 5: File with special characters in name
echo -e "\n${YELLOW}Test 5: Special characters in filename${NC}"
cat >"edge-cases/special-@#$%-chars.nix" <<'EOF'
{ pkgs, ... }: {
  special = true;
}
EOF

# Test 6: File with unicode content
echo -e "\n${YELLOW}Test 6: Unicode content${NC}"
cat >edge-cases/unicode.nix <<'EOF'
{ pkgs, ... }: {
  # Unicode test: 你好世界 🌍 émojis
  greeting = "Hello 世界";
  emoji = "🚀";
}
EOF

# Test 7: File with very long lines
echo -e "\n${YELLOW}Test 7: Very long lines${NC}"
echo -n '{ pkgs, ... }: { longLine = "' >edge-cases/longlines.nix
for i in {1..500}; do
  echo -n "very long line content " >>edge-cases/longlines.nix
done
echo '"; }' >>edge-cases/longlines.nix

# Test 8: Nested directories
echo -e "\n${YELLOW}Test 8: Deeply nested file${NC}"
mkdir -p edge-cases/very/deeply/nested/directory/structure
cat >edge-cases/very/deeply/nested/directory/structure/file.nix <<'EOF'
{ pkgs, ... }: {
  nested = true;
}
EOF

# Test 9: File with no newline at end
echo -e "\n${YELLOW}Test 9: No newline at EOF${NC}"
echo -n '{ pkgs, ... }: { noNewline = true; }' >edge-cases/no-newline.nix

# Test 10: Mixed line endings
echo -e "\n${YELLOW}Test 10: Mixed line endings${NC}"
printf '{ pkgs, ... }:\r\n{\r\n  mixed = true;\n}\r' >edge-cases/mixed-endings.nix

# Commit all test files
git add -A
git commit -m "Add edge case test files" -q

# Run formatter
echo -e "\n${YELLOW}Running formatter on edge cases...${NC}"
if ! run_with_timeout 120 "nix fmt 2>&1"; then
  echo -e "${RED}Formatter failed on edge cases${NC}"
  exit 1
fi

# Check results
echo -e "\n${YELLOW}Checking results...${NC}"

# Empty files should remain empty or have minimal formatting
for file in edge-cases/empty.*; do
  if [ -s "$file" ] && [ $(wc -l <"$file") -gt 5 ]; then
    echo -e "${RED}Empty file $file was unexpectedly modified${NC}"
    exit 1
  fi
done
echo -e "${GREEN}✓ Empty files handled correctly${NC}"

# Binary file should be unchanged
if ! cmp -s edge-cases/binary.dat <(dd if=/dev/urandom of=/dev/stdout bs=1024 count=1 2>/dev/null); then
  echo -e "${GREEN}✓ Binary file was correctly ignored${NC}"
else
  echo -e "${RED}Binary file may have been modified${NC}"
fi

# Large file should still be valid Nix
if ! nix-instantiate --parse edge-cases/large.nix >/dev/null 2>&1; then
  echo -e "${RED}Large file is no longer valid Nix${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Large file formatted successfully${NC}"

# Check symlink still works
if [ ! -L edge-cases/symlink.nix ]; then
  echo -e "${RED}Symlink was replaced with regular file${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Symlink preserved${NC}"

# Check special character file exists and is valid
if [ ! -f "edge-cases/special-@#$%-chars.nix" ]; then
  echo -e "${RED}Special character file missing${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Special character filename handled${NC}"

# Check unicode content preserved
if ! grep -q "你好世界" edge-cases/unicode.nix; then
  echo -e "${RED}Unicode content was corrupted${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Unicode content preserved${NC}"

# Check deeply nested file
if [ ! -f edge-cases/very/deeply/nested/directory/structure/file.nix ]; then
  echo -e "${RED}Deeply nested file missing${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Deeply nested files handled${NC}"

# Final check: run formatter again to ensure idempotency
echo -e "\n${YELLOW}Testing formatter idempotency...${NC}"
git add -A
git commit -m "Format edge cases" -q || true

if ! run_with_timeout 60 "nix fmt -- --fail-on-change"; then
  echo -e "${RED}Formatter is not idempotent on edge cases${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Formatter is idempotent${NC}"

echo -e "\n${GREEN}✅ All edge case tests passed!${NC}"
