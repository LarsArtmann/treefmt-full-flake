#!/usr/bin/env bash
# Wrapper function to handle CI mode for template tests

# Function to get template path based on CI mode
get_template_path() {
  local template_name=$1

  if [ -n "${TREEFMT_TEST_CI_MODE:-}" ] && [ -d "${REPO_ROOT}/templates/${template_name}-ci" ]; then
    echo "${REPO_ROOT}#${template_name}-ci"
  else
    echo "${REPO_ROOT}#${template_name}"
  fi
}

# Export function for use in test scripts
export -f get_template_path
