#!/usr/bin/env bash
# Test result caching utilities

# Cache configuration
CACHE_DIR="${TEST_CACHE_DIR:-$HOME/.cache/treefmt-tests}"
CACHE_TTL="${TEST_CACHE_TTL:-3600}" # Default 1 hour

# Cross-platform file modification time
_file_mtime() {
  local file=$1
  stat -c "%Y" "$file" 2>/dev/null || stat -f "%m" "$file" 2>/dev/null || echo "0"
}

# Initialize cache directory
init_cache() {
  mkdir -p "$CACHE_DIR"
}

# Generate cache key based on test inputs
generate_cache_key() {
  local test_name=$1
  local test_script=$2

  local script_mtime=$(_file_mtime "$test_script")
  local script_hash=$(sha256sum "$test_script" | cut -d' ' -f1)

  local flake_lock_hash=""
  if [ -f "../flake.lock" ]; then
    flake_lock_hash=$(sha256sum "../flake.lock" | cut -d' ' -f1)
  fi

  local formatter_hash=""
  if [[ $test_name =~ formatter ]]; then
    formatter_hash=$(find ../formatters -name "*.nix" -type f -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1)
  fi

  echo "${test_name}_${script_mtime}_${script_hash}_${flake_lock_hash}_${formatter_hash}" | sha256sum | cut -d' ' -f1
}

# Check if cached result exists and is valid
check_cache() {
  local cache_key=$1
  local cache_file="$CACHE_DIR/$cache_key"

  if [ ! -f "$cache_file" ]; then
    return 1
  fi

  local cache_age=$(($(date +%s) - $(_file_mtime "$cache_file")))
  if [ $cache_age -gt $CACHE_TTL ]; then
    rm -f "$cache_file"
    return 1
  fi

  return 0
}

# Save test result to cache
save_to_cache() {
  local cache_key=$1
  local result=$2
  local log_file=$3

  local cache_file="$CACHE_DIR/$cache_key"
  local cache_log="$CACHE_DIR/${cache_key}.log"

  echo "$result" >"$cache_file"
  if [ -f "$log_file" ]; then
    cp "$log_file" "$cache_log"
  fi
}

# Load result from cache
load_from_cache() {
  local cache_key=$1
  local result_file=$2
  local log_file=$3

  local cache_file="$CACHE_DIR/$cache_key"
  local cache_log="$CACHE_DIR/${cache_key}.log"

  if [ -f "$cache_file" ]; then
    cp "$cache_file" "$result_file"
  fi

  if [ -f "$cache_log" ] && [ -n "$log_file" ]; then
    cp "$cache_log" "$log_file"
  fi
}

# Clean expired cache entries
clean_cache() {
  init_cache

  local cleaned=0
  echo "Cleaning expired cache entries..."

  find "$CACHE_DIR" -type f | while read -r file; do
    local age=$(($(date +%s) - $(_file_mtime "$file")))
    if [ $age -gt $CACHE_TTL ]; then
      rm -f "$file"
      cleaned=$((cleaned + 1))
    fi
  done

  echo "Cleaned $cleaned expired cache entries"
}

# Clear entire cache
clear_cache() {
  echo "Clearing test cache..."
  rm -rf "$CACHE_DIR"
  init_cache
  echo "Cache cleared"
}

# Show cache statistics
cache_stats() {
  init_cache

  local total_files=$(find "$CACHE_DIR" -type f | wc -l)
  local cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)

  echo "Cache Statistics:"
  echo "  Directory: $CACHE_DIR"
  echo "  Total files: $total_files"
  echo "  Cache size: $cache_size"
  echo "  TTL: $((CACHE_TTL / 60)) minutes"
}
