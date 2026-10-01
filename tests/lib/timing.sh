#!/usr/bin/env bash
# Timing utilities for test scripts

# Function to format duration in human-readable format
format_duration() {
  local duration=$1
  local minutes=$((duration / 60))
  local seconds=$((duration % 60))

  if [ $minutes -gt 0 ]; then
    echo "${minutes}m ${seconds}s"
  else
    echo "${seconds}s"
  fi
}

# Function to time a command and report results
time_command() {
  local name=$1
  shift
  local cmd="$@"

  local start_time=$(date +%s)

  if eval "$cmd"; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo -e "${GREEN}✓ $name completed in $(format_duration $duration)${NC}"
    return 0
  else
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo -e "${RED}✗ $name failed after $(format_duration $duration)${NC}"
    return 1
  fi
}

# Function to start timing a section
start_timer() {
  SECTION_START_TIME=$(date +%s)
}

# Function to end timing and report
end_timer() {
  local section_name=$1
  local end_time=$(date +%s)
  local duration=$((end_time - SECTION_START_TIME))
  echo -e "${BLUE}⏱️  $section_name took $(format_duration $duration)${NC}"
}
