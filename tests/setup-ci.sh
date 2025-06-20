#!/usr/bin/env bash
# CI Setup Script for Template Testing
# This script prepares the environment for testing templates in CI

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up CI environment for template testing...${NC}"

# Function to check if we're in CI
is_ci() {
  [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ] || [ -n "${GITLAB_CI:-}" ] || [ -n "${CIRCLECI:-}" ]
}

# Function to setup mock repository
setup_mock_repo() {
  echo -e "${YELLOW}Setting up mock repository...${NC}"

  # Create a local bare repository that mimics the remote
  local MOCK_REPO_DIR="/tmp/treefmt-full-flake-mock.git"

  if [ -d "$MOCK_REPO_DIR" ]; then
    rm -rf "$MOCK_REPO_DIR"
  fi

  # Clone current repository as bare
  git clone --bare . "$MOCK_REPO_DIR" 2>/dev/null || {
    # If not in a git repo, initialize one
    git init --bare "$MOCK_REPO_DIR"
  }

  # Export environment variable for tests to use
  export TREEFMT_FLAKE_MOCK_REPO="file://$MOCK_REPO_DIR"

  echo -e "${GREEN}✓ Mock repository created at $MOCK_REPO_DIR${NC}"
}

# Function to patch template files for CI
patch_templates_for_ci() {
  echo -e "${YELLOW}Patching templates for CI...${NC}"

  # Create temporary copies of templates with file:// URLs
  for template in minimal default complete; do
    local template_dir="templates/${template}"
    local ci_template_dir="templates/${template}-ci"

    # Copy template
    cp -r "$template_dir" "$ci_template_dir"

    # Patch the flake.nix to use mock repository
    if [ -f "$ci_template_dir/flake.nix" ]; then
      sed -i.bak 's|git+ssh://git@github.com/LarsArtmann/treefmt-full-flake.git|'"${TREEFMT_FLAKE_MOCK_REPO}"'|g' "$ci_template_dir/flake.nix"
      rm -f "$ci_template_dir/flake.nix.bak"
    fi
  done

  echo -e "${GREEN}✓ Templates patched for CI${NC}"
}

# Function to update test scripts for CI
update_test_scripts_for_ci() {
  echo -e "${YELLOW}Updating test scripts for CI...${NC}"

  # Export flag for test scripts to use CI templates
  export TREEFMT_TEST_CI_MODE=1

  echo -e "${GREEN}✓ Test scripts configured for CI mode${NC}"
}

# Main setup
main() {
  echo -e "${BLUE}CI Environment Detection:${NC}"
  if is_ci; then
    echo -e "${GREEN}✓ Running in CI environment${NC}"
  else
    echo -e "${YELLOW}⚠ Not in CI environment, but continuing setup...${NC}"
  fi

  # Setup steps
  setup_mock_repo
  patch_templates_for_ci
  update_test_scripts_for_ci

  # Summary
  echo -e "\n${BLUE}CI Setup Complete!${NC}"
  echo -e "Mock repository: ${TREEFMT_FLAKE_MOCK_REPO}"
  echo -e "CI mode enabled: ${TREEFMT_TEST_CI_MODE}"
  echo -e "\n${GREEN}You can now run the template tests.${NC}"
}

# Cleanup function
cleanup() {
  echo -e "\n${YELLOW}Cleaning up CI setup...${NC}"
  rm -rf templates/*-ci
}

# Register cleanup on exit
trap cleanup EXIT

# Run main
main "$@"
