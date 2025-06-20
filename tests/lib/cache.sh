#!/usr/bin/env bash
# Test result caching utilities

# Cache configuration
CACHE_DIR="${TEST_CACHE_DIR:-$HOME/.cache/treefmt-tests}"
CACHE_TTL="${TEST_CACHE_TTL:-3600}" # Default 1 hour

# Initialize cache directory
init_cache() {
  mkdir -p "$CACHE_DIR"
}

# Generate cache key based on test inputs
generate_cache_key() {
  local test_name=$1
  local test_script=$2

  # Include test script modification time and content hash
  local script_mtime=$(stat -f "%m" "$test_script" 2>/dev/null || stat -c "%Y" "$test_script" 2>/dev/null || echo "0")
  local script_hash=$(sha256sum "$test_script" | cut -d' ' -f1)

  # Include flake.lock hash if it exists
  local flake_lock_hash=""
  if [ -f "../flake.lock" ]; then
    flake_lock_hash=$(sha256sum "../flake.lock" | cut -d' ' -f1)
  fi

  # Include relevant formatter module hashes
  local formatter_hash=""
  if [[ $test_name =~ formatter ]]; then
    formatter_hash=$(find ../formatters -name "*.nix" -type f -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1)
  fi

  # Combine all factors into cache key
  echo "${test_name}_${script_mtime}_${script_hash}_${flake_lock_hash}_${formatter_hash}" | sha256sum | cut -d' ' -f1
}

# Check if cached result exists and is valid
check_cache() {
  local cache_key=$1
  local cache_file="$CACHE_DIR/$cache_key"

  if [ ! -f "$cache_file" ]; then
    return 1 # Cache miss
  fi

  # Check if cache is expired
  local cache_age=$(($(date +%s) - $(stat -f "%m" "$cache_file" 2>/dev/null || stat -c "%Y" "$cache_file" 2>/dev/null || echo "0")))
  if [ $cache_age -gt $CACHE_TTL ]; then
    rm -f "$cache_file"
    return 1 # Cache expired
  fi

  return 0 # Cache hit
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

  find "$CACHE_DIR" -type f -name "*.log" -o -type f ! -name "*.log" | while read -r file; do
    local age=$(($(date +%s) - $(stat -f "%m" "$file" 2>/dev/null || stat -c "%Y" "$file" 2>/dev/null || echo "0")))
    if [ $age -gt $CACHE_TTL ]; then
      rm -f "$file"
      ((cleaned++))
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
  local oldest_file=$(find "$CACHE_DIR" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | sort -n | head -1 | cut -d' ' -f2-)

  echo "Cache Statistics:"
  echo "  Directory: $CACHE_DIR"
  echo "  Total files: $total_files"
  echo "  Cache size: $cache_size"
  echo "  TTL: $((CACHE_TTL / 60)) minutes"

  if [ -n "$oldest_file" ]; then
    local oldest_age=$(($(date +%s) - $(stat -f "%m" "$oldest_file" 2>/dev/null || stat -c "%Y" "$oldest_file" 2>/dev/null || echo "0")))
    echo "  Oldest entry: $(basename "$oldest_file") ($((oldest_age / 60)) minutes old)"
  fi
}
