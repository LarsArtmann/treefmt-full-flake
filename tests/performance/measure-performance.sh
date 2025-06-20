#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
RESULTS_FILE="$SCRIPT_DIR/performance-results.json"
ITERATIONS=${1:-3}  # Number of iterations per test

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Performance Measurement Suite       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Running $ITERATIONS iterations per test${NC}"
echo ""

# Initialize results
echo "{" > "$RESULTS_FILE"
echo '  "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",' >> "$RESULTS_FILE"
echo '  "iterations": '$ITERATIONS',' >> "$RESULTS_FILE"
echo '  "system": {' >> "$RESULTS_FILE"
echo '    "os": "'$(uname -s)'",' >> "$RESULTS_FILE"
echo '    "arch": "'$(uname -m)'",' >> "$RESULTS_FILE"
echo '    "nix_version": "'$(nix --version | cut -d' ' -f3)'"' >> "$RESULTS_FILE"
echo '  },' >> "$RESULTS_FILE"
echo '  "tests": {' >> "$RESULTS_FILE"

# Function to measure command execution time
measure_time() {
    local name=$1
    local cmd=$2
    local times=()
    
    echo -e "${YELLOW}Measuring: $name${NC}"
    
    for i in $(seq 1 $ITERATIONS); do
        echo -n "  Iteration $i/$ITERATIONS... "
        
        # Create temporary directory for test
        local test_dir=$(mktemp -d)
        cd "$test_dir"
        
        # Measure execution time
        local start_time=$(date +%s.%N)
        if eval "$cmd" >/dev/null 2>&1; then
            local end_time=$(date +%s.%N)
            local duration=$(echo "$end_time - $start_time" | bc)
            times+=($duration)
            echo -e "${GREEN}${duration}s${NC}"
        else
            echo -e "${RED}Failed${NC}"
            times+=(0)
        fi
        
        # Cleanup
        cd - >/dev/null
        rm -rf "$test_dir"
    done
    
    # Calculate statistics
    local sum=0
    local min=${times[0]}
    local max=${times[0]}
    
    for time in "${times[@]}"; do
        sum=$(echo "$sum + $time" | bc)
        if (( $(echo "$time < $min" | bc -l) )); then
            min=$time
        fi
        if (( $(echo "$time > $max" | bc -l) )); then
            max=$time
        fi
    done
    
    local avg=$(echo "scale=3; $sum / $ITERATIONS" | bc)
    
    echo -e "  ${GREEN}Average: ${avg}s, Min: ${min}s, Max: ${max}s${NC}"
    echo ""
    
    # Add to results file
    if [ "$name" != "format-check" ]; then
        echo "," >> "$RESULTS_FILE"
    fi
    echo '    "'$name'": {' >> "$RESULTS_FILE"
    echo '      "avg": '$avg',' >> "$RESULTS_FILE"
    echo '      "min": '$min',' >> "$RESULTS_FILE"
    echo '      "max": '$max',' >> "$RESULTS_FILE"
    echo '      "times": ['$(IFS=,; echo "${times[*]}")']' >> "$RESULTS_FILE"
    echo -n '    }' >> "$RESULTS_FILE"
}

# Test 1: Template initialization
first_test=true
measure_time "template-init-minimal" "nix flake init -t ${REPO_ROOT}#minimal"
first_test=false

measure_time "template-init-default" "nix flake init -t ${REPO_ROOT}#default"

measure_time "template-init-complete" "nix flake init -t ${REPO_ROOT}#complete"

# Test 2: Formatter performance on different file counts
echo -e "${YELLOW}Preparing formatter performance tests...${NC}"

# Small project (10 files)
measure_time "format-small" '
    nix flake init -t '${REPO_ROOT}'#minimal &&
    mkdir -p src &&
    for i in {1..10}; do
        echo "{ pkgs, ... }: { test = $i; }" > src/file$i.nix
    done &&
    nix fmt
'

# Medium project (100 files)
measure_time "format-medium" '
    nix flake init -t '${REPO_ROOT}'#minimal &&
    mkdir -p src &&
    for i in {1..100}; do
        echo "{ pkgs, ... }: { test = $i; }" > src/file$i.nix
    done &&
    nix fmt
'

# Large project (500 files)
measure_time "format-large" '
    nix flake init -t '${REPO_ROOT}'#minimal &&
    mkdir -p src &&
    for i in {1..500}; do
        echo "{ pkgs, ... }: { test = $i; }" > src/file$i.nix
    done &&
    nix fmt
'

# Test 3: Format check performance
measure_time "format-check" '
    nix flake init -t '${REPO_ROOT}'#minimal &&
    mkdir -p src &&
    echo "{ pkgs, ... }: { test = true; }" > src/test.nix &&
    nix fmt &&
    nix fmt -- --check
'

# Close JSON
echo "" >> "$RESULTS_FILE"
echo "  }" >> "$RESULTS_FILE"
echo "}" >> "$RESULTS_FILE"

# Display summary
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Performance Summary            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Parse and display results
if command -v jq >/dev/null 2>&1; then
    echo -e "${YELLOW}Template Initialization:${NC}"
    jq -r '.tests | to_entries | .[] | select(.key | startswith("template-init")) | "  \(.key): \(.value.avg)s avg"' "$RESULTS_FILE"
    
    echo -e "\n${YELLOW}Formatter Performance:${NC}"
    jq -r '.tests | to_entries | .[] | select(.key | startswith("format")) | "  \(.key): \(.value.avg)s avg"' "$RESULTS_FILE"
    
    echo -e "\n${GREEN}Results saved to: $RESULTS_FILE${NC}"
else
    echo -e "${YELLOW}Install jq for better result formatting${NC}"
    echo -e "${GREEN}Results saved to: $RESULTS_FILE${NC}"
fi

# Generate performance report
REPORT_FILE="$SCRIPT_DIR/performance-report.md"
echo "# Performance Report" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Generated on: $(date -u +"%Y-%m-%d %H:%M:%S UTC")" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## System Information" >> "$REPORT_FILE"
echo "- OS: $(uname -s)" >> "$REPORT_FILE"
echo "- Architecture: $(uname -m)" >> "$REPORT_FILE"
echo "- Nix Version: $(nix --version | cut -d' ' -f3)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## Results ($ITERATIONS iterations per test)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if command -v jq >/dev/null 2>&1; then
    echo "| Test | Average | Min | Max |" >> "$REPORT_FILE"
    echo "|------|---------|-----|-----|" >> "$REPORT_FILE"
    jq -r '.tests | to_entries | .[] | "| \(.key) | \(.value.avg)s | \(.value.min)s | \(.value.max)s |"' "$RESULTS_FILE" >> "$REPORT_FILE"
fi

echo -e "\n${GREEN}Performance report saved to: $REPORT_FILE${NC}"