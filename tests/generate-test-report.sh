#!/usr/bin/env bash
set -euo pipefail

# Test report generator
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${1:-$SCRIPT_DIR/.test-results}"
REPORT_FILE="${2:-$SCRIPT_DIR/test-report.html}"

# Check if results directory exists
if [ ! -d "$RESULTS_DIR" ]; then
  echo "Error: Results directory not found: $RESULTS_DIR"
  echo "Run tests first to generate results"
  exit 1
fi

# Generate HTML report
cat >"$REPORT_FILE" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>treefmt-full-flake Test Report</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
      background: #f5f5f5;
      padding: 20px;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
      background: white;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
      padding: 30px;
    }
    h1 { color: #2c3e50; margin-bottom: 10px; }
    h2 { color: #34495e; margin-top: 30px; margin-bottom: 15px; }
    .summary {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin: 20px 0;
    }
    .stat-card {
      background: #f8f9fa;
      padding: 20px;
      border-radius: 8px;
      text-align: center;
      border: 2px solid transparent;
    }
    .stat-card.passed { border-color: #27ae60; }
    .stat-card.failed { border-color: #e74c3c; }
    .stat-card.total { border-color: #3498db; }
    .stat-card h3 { margin-bottom: 10px; font-size: 14px; text-transform: uppercase; }
    .stat-card .number { font-size: 36px; font-weight: bold; }
    .passed .number { color: #27ae60; }
    .failed .number { color: #e74c3c; }
    .total .number { color: #3498db; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 20px 0;
    }
    th, td {
      text-align: left;
      padding: 12px;
      border-bottom: 1px solid #ddd;
    }
    th {
      background: #f8f9fa;
      font-weight: 600;
      position: sticky;
      top: 0;
    }
    tr:hover { background: #f8f9fa; }
    .status-pass { color: #27ae60; font-weight: 600; }
    .status-fail { color: #e74c3c; font-weight: 600; }
    .log-preview {
      background: #1e1e1e;
      color: #d4d4d4;
      padding: 15px;
      border-radius: 4px;
      font-family: 'Consolas', 'Monaco', monospace;
      font-size: 12px;
      overflow-x: auto;
      margin: 10px 0;
      max-height: 300px;
      overflow-y: auto;
    }
    .timestamp {
      color: #7f8c8d;
      font-size: 14px;
      margin-top: 10px;
    }
    .expandable {
      cursor: pointer;
      user-select: none;
    }
    .expandable::before {
      content: '▶ ';
      display: inline-block;
      transition: transform 0.2s;
    }
    .expandable.expanded::before {
      transform: rotate(90deg);
    }
    .log-content {
      display: none;
      margin-top: 10px;
    }
    .log-content.show { display: block; }
    .filter-buttons {
      margin: 20px 0;
    }
    .filter-btn {
      padding: 8px 16px;
      margin-right: 10px;
      border: 1px solid #ddd;
      background: white;
      border-radius: 4px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .filter-btn:hover { background: #f8f9fa; }
    .filter-btn.active {
      background: #3498db;
      color: white;
      border-color: #3498db;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>🧪 treefmt-full-flake Test Report</h1>
    <p class="timestamp">Generated: <span id="timestamp"></span></p>

    <div class="summary">
      <div class="stat-card passed">
        <h3>Passed</h3>
        <div class="number" id="passed-count">0</div>
      </div>
      <div class="stat-card failed">
        <h3>Failed</h3>
        <div class="number" id="failed-count">0</div>
      </div>
      <div class="stat-card total">
        <h3>Total</h3>
        <div class="number" id="total-count">0</div>
      </div>
    </div>

    <h2>Test Results</h2>
    
    <div class="filter-buttons">
      <button class="filter-btn active" onclick="filterTests('all')">All Tests</button>
      <button class="filter-btn" onclick="filterTests('passed')">Passed Only</button>
      <button class="filter-btn" onclick="filterTests('failed')">Failed Only</button>
    </div>

    <table id="results-table">
      <thead>
        <tr>
          <th>Test Name</th>
          <th>Status</th>
          <th>Duration</th>
          <th>Details</th>
        </tr>
      </thead>
      <tbody id="results-body">
      </tbody>
    </table>
  </div>

  <script>
    // Test data will be injected here
    const testResults = {
EOF

# Parse test results and generate JSON
echo "      tests: [" >>"$REPORT_FILE"

first=true
for result_file in "$RESULTS_DIR"/*.result; do
  if [ -f "$result_file" ]; then
    test_name=$(basename "$result_file" .result)
    result=$(cat "$result_file")
    status=$(echo "$result" | awk '{print $1}')

    if [ "$first" = true ]; then
      first=false
    else
      echo "," >>"$REPORT_FILE"
    fi

    if [ "$status" = "PASS" ]; then
      duration=$(echo "$result" | awk '{print $2}')
      echo -n "        { name: '$test_name', status: 'passed', duration: $duration, exitCode: 0 }" >>"$REPORT_FILE"
    else
      exit_code=$(echo "$result" | awk '{print $2}')
      duration=$(echo "$result" | awk '{print $3}')
      echo -n "        { name: '$test_name', status: 'failed', duration: $duration, exitCode: $exit_code }" >>"$REPORT_FILE"
    fi
  fi
done

cat >>"$REPORT_FILE" <<'EOF'

      ],
      timestamp: new Date().toISOString()
    };

    // Initialize the report
    document.getElementById('timestamp').textContent = new Date(testResults.timestamp).toLocaleString();

    const passed = testResults.tests.filter(t => t.status === 'passed').length;
    const failed = testResults.tests.filter(t => t.status === 'failed').length;

    document.getElementById('passed-count').textContent = passed;
    document.getElementById('failed-count').textContent = failed;
    document.getElementById('total-count').textContent = testResults.tests.length;

    // Format duration
    function formatDuration(seconds) {
      if (seconds < 1) return `${(seconds * 1000).toFixed(0)}ms`;
      if (seconds < 60) return `${seconds.toFixed(1)}s`;
      const minutes = Math.floor(seconds / 60);
      const secs = (seconds % 60).toFixed(0);
      return `${minutes}m ${secs}s`;
    }

    // Populate table
    const tbody = document.getElementById('results-body');
    testResults.tests.forEach(test => {
      const row = document.createElement('tr');
      row.className = `test-row ${test.status}`;
      
      const statusClass = test.status === 'passed' ? 'status-pass' : 'status-fail';
      const statusIcon = test.status === 'passed' ? '✅' : '❌';
      
      row.innerHTML = `
        <td>${test.name}</td>
        <td class="${statusClass}">${statusIcon} ${test.status.toUpperCase()}</td>
        <td>${formatDuration(test.duration)}</td>
        <td>
          ${test.status === 'failed' ? 
            `<span class="expandable" onclick="toggleLog('${test.name}')">View Log</span>
             <div class="log-content" id="log-${test.name}">
               <div class="log-preview">Loading log...</div>
             </div>` : 
            '-'}
        </td>
      `;
      
      tbody.appendChild(row);
    });

    // Filter functionality
    window.filterTests = function(filter) {
      document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
      event.target.classList.add('active');
      
      const rows = document.querySelectorAll('.test-row');
      rows.forEach(row => {
        if (filter === 'all') {
          row.style.display = '';
        } else if (filter === 'passed' && row.classList.contains('passed')) {
          row.style.display = '';
        } else if (filter === 'failed' && row.classList.contains('failed')) {
          row.style.display = '';
        } else {
          row.style.display = 'none';
        }
      });
    };

    // Toggle log view
    window.toggleLog = function(testName) {
      const toggle = event.target;
      const content = document.getElementById(`log-${testName}`);
      
      toggle.classList.toggle('expanded');
      content.classList.toggle('show');
      
      // Load log content if not already loaded
      if (content.classList.contains('show') && content.querySelector('.log-preview').textContent === 'Loading log...') {
        // In a real implementation, this would fetch the log file
        content.querySelector('.log-preview').textContent = 'Log content would be loaded here from the .log file';
      }
    };
  </script>
</body>
</html>
EOF

echo "Test report generated: $REPORT_FILE"

# Also generate a markdown summary
SUMMARY_MD="$SCRIPT_DIR/test-summary.md"
cat >"$SUMMARY_MD" <<EOF
# Test Summary

**Generated**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Results

EOF

# Count passed/failed
passed=0
failed=0

for result_file in "$RESULTS_DIR"/*.result; do
  if [ -f "$result_file" ]; then
    result=$(cat "$result_file")
    status=$(echo "$result" | awk '{print $1}')
    if [ "$status" = "PASS" ]; then
      ((passed++))
    else
      ((failed++))
    fi
  fi
done

cat >>"$SUMMARY_MD" <<EOF
- **Total Tests**: $((passed + failed))
- **Passed**: $passed ✅
- **Failed**: $failed ❌
- **Success Rate**: $(awk "BEGIN {printf \"%.1f\", ($passed / ($passed + $failed)) * 100}")%

## Individual Results

| Test | Status | Duration |
|------|--------|----------|
EOF

# Add individual results
for result_file in "$RESULTS_DIR"/*.result; do
  if [ -f "$result_file" ]; then
    test_name=$(basename "$result_file" .result)
    result=$(cat "$result_file")
    status=$(echo "$result" | awk '{print $1}')

    if [ "$status" = "PASS" ]; then
      duration=$(echo "$result" | awk '{print $2}')
      echo "| $test_name | ✅ PASS | ${duration}s |" >>"$SUMMARY_MD"
    else
      duration=$(echo "$result" | awk '{print $3}')
      echo "| $test_name | ❌ FAIL | ${duration}s |" >>"$SUMMARY_MD"
    fi
  fi
done

echo "Markdown summary generated: $SUMMARY_MD"
