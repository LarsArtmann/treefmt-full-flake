#!/usr/bin/env bash
# Quick template syntax validation (no network required)
set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FAILED=0
PASSED=0

echo "Template Syntax Validation"
echo "=========================="
echo ""

validate_nix() {
  local file="$1"
  local name="$2"
  
  echo -n "Validating $name... "
  
  # Use nix-instantiate --parse for fast syntax check
  if nix-instantiate --parse "$file" >/dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}FAILED${NC}"
    FAILED=$((FAILED + 1))
  fi
}

# Validate all templates
validate_nix "$REPO_ROOT/templates/minimal/flake.nix" "minimal template"
validate_nix "$REPO_ROOT/templates/default/flake.nix" "default template"
validate_nix "$REPO_ROOT/templates/complete/flake.nix" "complete template"
validate_nix "$REPO_ROOT/templates/local-development/flake.nix" "local-development template"

echo ""
echo "Results: $PASSED passed, $FAILED failed"

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}All templates are syntactically valid!${NC}"
  exit 0
else
  echo -e "${RED}Some templates have syntax errors${NC}"
  exit 1
fi
