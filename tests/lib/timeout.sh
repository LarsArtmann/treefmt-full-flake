#!/usr/bin/env bash
# Universal timeout wrapper that works on Linux and macOS

# Function to run command with timeout
# Usage: run_with_timeout <timeout_seconds> <command...>
run_with_timeout() {
  local timeout=$1
  shift
  local cmd="$@"

  # Try different timeout implementations in order of preference
  if command -v timeout >/dev/null 2>&1; then
    # GNU coreutils timeout (Linux)
    timeout "$timeout" bash -c "$cmd"
  elif command -v gtimeout >/dev/null 2>&1; then
    # GNU coreutils timeout from homebrew (macOS)
    gtimeout "$timeout" bash -c "$cmd"
  else
    # Fallback implementation using background process
    (
      eval "$cmd" &
      local pid=$!
      local count=0

      # Monitor process
      while kill -0 $pid 2>/dev/null && [ $count -lt $timeout ]; do
        sleep 1
        ((count++))
      done

      # Kill if still running
      if kill -0 $pid 2>/dev/null; then
        kill -TERM $pid 2>/dev/null
        sleep 1
        kill -KILL $pid 2>/dev/null
        wait $pid 2>/dev/null
        return 124 # timeout exit code
      fi

      wait $pid
    )
  fi
}

# Export for use in subshells
export -f run_with_timeout
