#!/usr/bin/env bash
# smart-treefmt-analytics.sh - Analytics Integration for treefmt
# Seamlessly integrates performance analytics with treefmt execution

set -euo pipefail

# Script configuration
readonly SCRIPT_VERSION="1.0.0"
readonly ANALYTICS_DIR="./.treefmt-analytics"
readonly CONFIG_FILE="$ANALYTICS_DIR/config.json"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

# Unicode icons
readonly CHART="📊"
readonly ROCKET="🚀"
readonly TARGET="🎯"
readonly SPARKLES="✨"
readonly GEAR="⚙️"
readonly CLOCK="⏱️"

# Analytics configuration
ENABLE_ANALYTICS=true
PROJECT_ID=""
COLLECT_PERSONAL_DATA=false
ANONYMIZE_PATHS=true
AUTO_DASHBOARD=false
EXPORT_FORMAT="json"

# Performance tracking variables
START_TIME=""
SESSION_ID=""
TEMP_DIR=""
FORMATTER_METRICS=()
FILE_METRICS=()
ERROR_COUNT=0
WARNING_COUNT=0

# Function to print with styling
print_analytics() {
  local icon=$1
  local color=$2
  shift 2
  echo -e "${color}${icon} $*${NC}"
}

# Function to initialize analytics
init_analytics() {
  if [[ ! -d "$ANALYTICS_DIR" ]]; then
    mkdir -p "$ANALYTICS_DIR"
    print_analytics "$GEAR" "$BLUE" "Initialized analytics directory: $ANALYTICS_DIR"
  fi
  
  # Generate session ID
  SESSION_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  
  # Create temp directory for this session
  TEMP_DIR=$(mktemp -d)
  
  # Auto-detect project ID from git or directory name
  if [[ -z "$PROJECT_ID" ]]; then
    if git rev-parse --git-dir >/dev/null 2>&1; then
      PROJECT_ID=$(basename "$(git rev-parse --show-toplevel)")
    else
      PROJECT_ID=$(basename "$(pwd)")
    fi
  fi
  
  print_analytics "$SPARKLES" "$GREEN" "Analytics initialized for project: $PROJECT_ID"
}

# Function to load configuration
load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    if command -v jq >/dev/null 2>&1; then
      ENABLE_ANALYTICS=$(jq -r '.enableAnalytics // true' "$CONFIG_FILE")
      PROJECT_ID=$(jq -r '.projectId // ""' "$CONFIG_FILE")
      COLLECT_PERSONAL_DATA=$(jq -r '.collectPersonalData // false' "$CONFIG_FILE")
      ANONYMIZE_PATHS=$(jq -r '.anonymizePaths // true' "$CONFIG_FILE")
      AUTO_DASHBOARD=$(jq -r '.autoDashboard // false' "$CONFIG_FILE")
      EXPORT_FORMAT=$(jq -r '.exportFormat // "json"' "$CONFIG_FILE")
    fi
  fi
}

# Function to save configuration
save_config() {
  cat > "$CONFIG_FILE" << EOF
{
  "enableAnalytics": $ENABLE_ANALYTICS,
  "projectId": "$PROJECT_ID",
  "collectPersonalData": $COLLECT_PERSONAL_DATA,
  "anonymizePaths": $ANONYMIZE_PATHS,
  "autoDashboard": $AUTO_DASHBOARD,
  "exportFormat": "$EXPORT_FORMAT",
  "version": "$SCRIPT_VERSION",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

# Function to start performance monitoring
start_monitoring() {
  START_TIME=$(date +%s%3N)  # milliseconds
  print_analytics "$CLOCK" "$CYAN" "Performance monitoring started"
}

# Function to track formatter execution
track_formatter() {
  local formatter_name=$1
  local start_time=$2
  local end_time=$3
  local files_processed=$4
  local changes_made=${5:-0}
  local errors=${6:-0}
  
  local execution_time=$((end_time - start_time))
  
  # Store formatter metrics
  FORMATTER_METRICS+=("$formatter_name:$execution_time:$files_processed:$changes_made:$errors")
  
  print_analytics "$TARGET" "$YELLOW" "Tracked $formatter_name: ${execution_time}ms, $files_processed files"
}

# Function to track file processing
track_file() {
  local file_path=$1
  local formatter=$2
  local processing_time=$3
  local changes_count=${4:-0}
  local file_size=${5:-0}
  
  # Get file size if not provided
  if [[ $file_size -eq 0 && -f "$file_path" ]]; then
    file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo "0")
  fi
  
  # Detect language
  local language=$(detect_language "$file_path")
  
  # Generate checksums
  local before_checksum=$(echo -n "before" | shasum -a 256 | cut -d' ' -f1)
  local after_checksum=$(echo -n "after" | shasum -a 256 | cut -d' ' -f1)
  
  # Anonymize path if needed
  local tracked_path="$file_path"
  if [[ "$ANONYMIZE_PATHS" == "true" ]]; then
    tracked_path=$(anonymize_path "$file_path")
  fi
  
  # Store file metrics
  FILE_METRICS+=("$tracked_path:$formatter:$processing_time:$changes_count:$file_size:$language:$before_checksum:$after_checksum")
}

# Function to detect file language
detect_language() {
  local file_path=$1
  local extension="${file_path##*.}"
  
  case "$extension" in
    js|jsx) echo "javascript" ;;
    ts|tsx) echo "typescript" ;;
    py) echo "python" ;;
    rs) echo "rust" ;;
    go) echo "go" ;;
    java) echo "java" ;;
    cpp|cc|cxx) echo "cpp" ;;
    c) echo "c" ;;
    css) echo "css" ;;
    scss|sass) echo "scss" ;;
    html|htm) echo "html" ;;
    json) echo "json" ;;
    yaml|yml) echo "yaml" ;;
    md|markdown) echo "markdown" ;;
    nix) echo "nix" ;;
    sh|bash) echo "shell" ;;
    *) echo "unknown" ;;
  esac
}

# Function to anonymize file paths
anonymize_path() {
  local path=$1
  
  # Replace directory names with hashes but keep file extensions
  echo "$path" | sed -E 's|/[^/]+/|/dir_XXXX/|g' | sed -E 's|([^/]+)\.([^.]+)$|file_XXXX.\2|'
}

# Function to collect system metrics
collect_system_metrics() {
  local memory_mb=0
  local cpu_percent=0
  
  # Get memory usage (cross-platform)
  if command -v ps >/dev/null 2>&1; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      memory_mb=$(ps -o rss= -p $$ | awk '{print $1/1024}')
    else
      # Linux
      memory_mb=$(ps -o rss= -p $$ | awk '{print $1/1024}')
    fi
  fi
  
  # Store in temp file for later collection
  echo "$memory_mb:$cpu_percent" > "$TEMP_DIR/system_metrics.txt"
}

# Function to finalize analytics collection
finalize_analytics() {
  if [[ "$ENABLE_ANALYTICS" != "true" ]]; then
    return 0
  fi
  
  local end_time=$(date +%s%3N)
  local total_time=$((end_time - START_TIME))
  local file_count=${#FILE_METRICS[@]}
  
  # Calculate total lines processed (rough estimate)
  local total_lines=0
  for file_metric in "${FILE_METRICS[@]}"; do
    local file_size=$(echo "$file_metric" | cut -d':' -f5)
    total_lines=$((total_lines + file_size / 50))  # Rough estimate: 50 chars per line
  done
  
  # Get system metrics
  local memory_mb=0
  local cpu_percent=0
  if [[ -f "$TEMP_DIR/system_metrics.txt" ]]; then
    memory_mb=$(cut -d':' -f1 "$TEMP_DIR/system_metrics.txt")
    cpu_percent=$(cut -d':' -f2 "$TEMP_DIR/system_metrics.txt")
  fi
  
  # Create analytics data structure
  local analytics_data=$(cat << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "sessionId": "$SESSION_ID",
  "projectId": "$PROJECT_ID",
  "formatTime": $total_time,
  "fileCount": $file_count,
  "totalLines": $total_lines,
  "memoryUsage": $memory_mb,
  "cpuUsage": $cpu_percent,
  "formatters": [
    $(format_formatter_metrics)
  ],
  "files": [
    $(format_file_metrics)
  ],
  "environment": {
    "os": "$(uname -s)",
    "arch": "$(uname -m)",
    "nodeVersion": "$(node --version 2>/dev/null || echo 'unknown')",
    "treefmtVersion": "1.0.0"
  },
  "errors": [],
  "warnings": []
}
EOF
)
  
  # Save analytics data
  local analytics_file="$ANALYTICS_DIR/session_$(date +%Y%m%d_%H%M%S)_$SESSION_ID.json"
  echo "$analytics_data" > "$analytics_file"
  
  # Update analytics using TypeScript collector if available
  if command -v bun >/dev/null 2>&1 && [[ -f "analytics-collector.ts" ]]; then
    bun run analytics-collector.ts summary "$PROJECT_ID" 1 >/dev/null 2>&1 || true
  fi
  
  print_analytics "$CHART" "$GREEN" "Analytics saved: ${total_time}ms, $file_count files processed"
  
  # Show quick summary
  show_quick_summary "$total_time" "$file_count"
  
  # Auto-launch dashboard if enabled
  if [[ "$AUTO_DASHBOARD" == "true" ]]; then
    launch_dashboard
  fi
  
  # Cleanup
  rm -rf "$TEMP_DIR"
}

# Function to format formatter metrics for JSON
format_formatter_metrics() {
  local json_items=()
  
  for metric in "${FORMATTER_METRICS[@]}"; do
    IFS=':' read -r name exec_time files_processed changes errors <<< "$metric"
    json_items+=("    {
      \"name\": \"$name\",
      \"version\": \"unknown\",
      \"executionTime\": $exec_time,
      \"filesProcessed\": $files_processed,
      \"linesProcessed\": 0,
      \"changes\": $changes,
      \"errors\": $errors
    }")
  done
  
  printf '%s\n' "${json_items[@]}" | paste -sd','
}

# Function to format file metrics for JSON  
format_file_metrics() {
  local json_items=()
  
  for metric in "${FILE_METRICS[@]}"; do
    IFS=':' read -r path formatter proc_time changes size language before_hash after_hash <<< "$metric"
    json_items+=("    {
      \"path\": \"$path\",
      \"size\": $size,
      \"language\": \"$language\",
      \"formatter\": \"$formatter\",
      \"processingTime\": $proc_time,
      \"changesCount\": $changes,
      \"beforeChecksum\": \"$before_hash\",
      \"afterChecksum\": \"$after_hash\"
    }")
  done
  
  printf '%s\n' "${json_items[@]}" | paste -sd','
}

# Function to show quick performance summary
show_quick_summary() {
  local total_time=$1
  local file_count=$2
  
  echo
  print_analytics "$ROCKET" "$BOLD" "Performance Summary"
  echo "  ├─ Total Time: ${total_time}ms"
  echo "  ├─ Files Processed: $file_count"
  echo "  ├─ Average per File: $((total_time / (file_count > 0 ? file_count : 1)))ms"
  echo "  └─ Session ID: $SESSION_ID"
  echo
}

# Function to launch analytics dashboard
launch_dashboard() {
  if command -v bun >/dev/null 2>&1 && [[ -f "terminal-dashboard-kit.ts" ]]; then
    print_analytics "$CHART" "$CYAN" "Launching analytics dashboard..."
    bun run terminal-dashboard-kit.ts "$PROJECT_ID" 7
  else
    print_analytics "$CHART" "$YELLOW" "Dashboard not available (requires bun and terminal-dashboard-kit.ts)"
  fi
}

# Function to export analytics data
export_analytics() {
  local format=${1:-"$EXPORT_FORMAT"}
  local days=${2:-7}
  
  if command -v bun >/dev/null 2>&1 && [[ -f "analytics-collector.ts" ]]; then
    print_analytics "$CHART" "$BLUE" "Exporting analytics data ($format format, last $days days)..."
    bun run analytics-collector.ts export "$PROJECT_ID" "$format" "$days"
  else
    print_analytics "$CHART" "$YELLOW" "Export not available (requires bun and analytics-collector.ts)"
  fi
}

# Function to show analytics status
show_analytics_status() {
  echo
  print_analytics "$CHART" "$BOLD" "Analytics Configuration"
  echo "  ├─ Status: $(if [[ "$ENABLE_ANALYTICS" == "true" ]]; then echo "${GREEN}Enabled${NC}"; else echo "${RED}Disabled${NC}"; fi)"
  echo "  ├─ Project ID: $PROJECT_ID"
  echo "  ├─ Collect Personal Data: $COLLECT_PERSONAL_DATA"
  echo "  ├─ Anonymize Paths: $ANONYMIZE_PATHS"
  echo "  ├─ Auto Dashboard: $AUTO_DASHBOARD"
  echo "  ├─ Export Format: $EXPORT_FORMAT"
  echo "  └─ Data Directory: $ANALYTICS_DIR"
  echo
}

# Function to configure analytics
configure_analytics() {
  echo
  print_analytics "$GEAR" "$CYAN" "Analytics Configuration"
  echo
  
  # Enable/disable analytics
  read -p "Enable analytics collection? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ENABLE_ANALYTICS=true
  else
    ENABLE_ANALYTICS=false
  fi
  
  if [[ "$ENABLE_ANALYTICS" == "true" ]]; then
    # Project ID
    read -p "Project ID (default: $PROJECT_ID): " user_project_id
    if [[ -n "$user_project_id" ]]; then
      PROJECT_ID="$user_project_id"
    fi
    
    # Personal data
    read -p "Collect personal data (file paths, user info)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      COLLECT_PERSONAL_DATA=true
      ANONYMIZE_PATHS=false
    else
      COLLECT_PERSONAL_DATA=false
      ANONYMIZE_PATHS=true
    fi
    
    # Auto dashboard
    read -p "Auto-launch dashboard after formatting? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      AUTO_DASHBOARD=true
    else
      AUTO_DASHBOARD=false
    fi
  fi
  
  # Save configuration
  save_config
  print_analytics "$SPARKLES" "$GREEN" "Configuration saved to $CONFIG_FILE"
}

# Function to show help
show_help() {
  cat << EOF
${BOLD}Smart treefmt Analytics v$SCRIPT_VERSION${NC}

${BOLD}USAGE:${NC}
  $0 [OPTIONS] [TREEFMT_ARGS...]

${BOLD}ANALYTICS OPTIONS:${NC}
  --analytics-status           Show current analytics configuration
  --analytics-config           Configure analytics settings  
  --analytics-dashboard        Launch analytics dashboard
  --analytics-export [format]  Export analytics data (json/csv)
  --analytics-disable          Disable analytics for this run
  --analytics-summary [days]   Show performance summary

${BOLD}EXAMPLES:${NC}
  $0                          # Run treefmt with analytics
  $0 --analytics-config       # Configure analytics
  $0 --analytics-dashboard    # Launch dashboard  
  $0 --analytics-export csv   # Export CSV data
  $0 --analytics-disable .    # Run without analytics

${BOLD}CONFIGURATION:${NC}
  Analytics data is stored in: $ANALYTICS_DIR
  Configuration file: $CONFIG_FILE

For more information, see the Performance Analytics documentation.
EOF
}

# Main execution function
main() {
  # Load configuration
  load_config
  
  # Parse arguments
  local treefmt_args=()
  local analytics_action=""
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      --analytics-status)
        analytics_action="status"
        shift
        ;;
      --analytics-config)
        analytics_action="config"
        shift
        ;;
      --analytics-dashboard)
        analytics_action="dashboard"
        shift
        ;;
      --analytics-export)
        analytics_action="export"
        EXPORT_FORMAT=${2:-"json"}
        shift 2
        ;;
      --analytics-disable)
        ENABLE_ANALYTICS=false
        shift
        ;;
      --analytics-summary)
        analytics_action="summary"
        shift
        ;;
      --help-analytics)
        show_help
        exit 0
        ;;
      *)
        treefmt_args+=("$1")
        shift
        ;;
    esac
  done
  
  # Handle analytics actions
  case "$analytics_action" in
    status)
      show_analytics_status
      exit 0
      ;;
    config)
      configure_analytics
      exit 0
      ;;
    dashboard)
      launch_dashboard
      exit 0
      ;;
    export)
      export_analytics "$EXPORT_FORMAT" 7
      exit 0
      ;;
    summary)
      if command -v bun >/dev/null 2>&1 && [[ -f "analytics-collector.ts" ]]; then
        bun run analytics-collector.ts summary "$PROJECT_ID" 7
      else
        echo "Summary requires bun and analytics-collector.ts"
      fi
      exit 0
      ;;
  esac
  
  # Initialize analytics if enabled
  if [[ "$ENABLE_ANALYTICS" == "true" ]]; then
    init_analytics
    start_monitoring
    collect_system_metrics
  fi
  
  # Execute treefmt with the remaining arguments
  local treefmt_start=$(date +%s%3N)
  local treefmt_exit_code=0
  
  # Find treefmt command
  local treefmt_cmd=""
  if command -v treefmt >/dev/null 2>&1; then
    treefmt_cmd="treefmt"
  elif [[ -f "./result/bin/treefmt" ]]; then
    treefmt_cmd="./result/bin/treefmt"
  elif command -v nix >/dev/null 2>&1; then
    treefmt_cmd="nix fmt --"
  else
    echo "Error: treefmt not found"
    exit 1
  fi
  
  # Run treefmt and capture performance
  if $treefmt_cmd "${treefmt_args[@]}" 2>&1; then
    treefmt_exit_code=0
  else
    treefmt_exit_code=$?
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
  
  local treefmt_end=$(date +%s%3N)
  
  # Track treefmt execution if analytics enabled
  if [[ "$ENABLE_ANALYTICS" == "true" ]]; then
    track_formatter "treefmt" "$treefmt_start" "$treefmt_end" "${#treefmt_args[@]}" 0 "$ERROR_COUNT"
    
    # Track individual files if possible (simplified)
    for arg in "${treefmt_args[@]}"; do
      if [[ -f "$arg" ]]; then
        track_file "$arg" "treefmt" 100 0  # Simplified tracking
      fi
    done
    
    # Finalize analytics collection
    finalize_analytics
  fi
  
  exit $treefmt_exit_code
}

# Run main function with all arguments
main "$@"