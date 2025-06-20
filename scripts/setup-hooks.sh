#!/usr/bin/env bash
# Setup script for git hooks

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

echo -e "${YELLOW}Setting up git hooks...${NC}"

# Create .git/hooks directory if it doesn't exist
mkdir -p "$REPO_ROOT/.git/hooks"

# Install pre-commit hook
if [ -f "$REPO_ROOT/.githooks/pre-commit" ]; then
    cp "$REPO_ROOT/.githooks/pre-commit" "$REPO_ROOT/.git/hooks/pre-commit"
    chmod +x "$REPO_ROOT/.git/hooks/pre-commit"
    echo -e "${GREEN}✓ Installed pre-commit hook${NC}"
else
    echo -e "${RED}Error: pre-commit hook not found in .githooks/${NC}"
    exit 1
fi

# Alternative: Use git config to set hooks path (Git 2.9+)
echo -e "\n${YELLOW}Configuring git to use .githooks directory...${NC}"
git config core.hooksPath .githooks
echo -e "${GREEN}✓ Git configured to use .githooks directory${NC}"

echo -e "\n${GREEN}✅ Git hooks setup complete!${NC}"
echo -e "${YELLOW}Note: The pre-commit hook will automatically format your code before each commit${NC}"
echo -e "${YELLOW}To disable temporarily, use: git commit --no-verify${NC}"