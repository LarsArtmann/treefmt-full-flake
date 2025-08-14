#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Cleaning up test artifacts...${NC}"

# Find all directories with .git subdirectories (excluding main repo)
NESTED_GIT_DIRS=$(find . -type d -name ".git" -not -path "./.git" 2>/dev/null | sed 's|/\.git||' || true)

if [[ -z "$NESTED_GIT_DIRS" ]]; then
    echo -e "${GREEN}✓ No nested git repositories found${NC}"
else
    echo -e "${YELLOW}Found nested git repositories:${NC}"
    echo "$NESTED_GIT_DIRS"
    
    # Remove each directory containing a nested .git
    while IFS= read -r dir; do
        if [[ -n "$dir" ]]; then
            echo -e "  Removing: $dir"
            trash "$dir" 2>/dev/null || rm -rf "$dir"
        fi
    done <<< "$NESTED_GIT_DIRS"
    
    echo -e "${GREEN}✓ Cleaned up nested git repositories${NC}"
fi

# Clean up common test artifact patterns
TEST_PATTERNS=(
    "template-test-*"
    "test-comprehensive"
    "test-schema-debug"
    "test-hook-dir"
    "test-treefmt-flags"
    "test-user-experience"
    "treefmt-template-debug"
    "final-test"
)

CLEANED=0
for pattern in "${TEST_PATTERNS[@]}"; do
    for dir in $pattern; do
        if [[ -d "$dir" ]]; then
            echo -e "  Removing test artifact: $dir"
            trash "$dir" 2>/dev/null || rm -rf "$dir"
            ((CLEANED++))
        fi
    done
done

if [[ $CLEANED -gt 0 ]]; then
    echo -e "${GREEN}✓ Cleaned up $CLEANED test artifact directories${NC}"
else
    echo -e "${GREEN}✓ No test artifacts to clean${NC}"
fi

# Clean up treefmt cache if requested
if [[ "${1:-}" == "--all" ]]; then
    echo -e "${YELLOW}Cleaning treefmt cache...${NC}"
    trash .treefmt-cache 2>/dev/null || rm -rf .treefmt-cache
    echo -e "${GREEN}✓ Cleaned treefmt cache${NC}"
fi

echo -e "${GREEN}✓ Cleanup complete${NC}"