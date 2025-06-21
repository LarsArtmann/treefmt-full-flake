{lib}: let
  # Performance tracking and benchmarking utilities for treefmt
  # Performance metrics collection
  performanceMetrics = {
    # Core timing metrics
    timing = {
      start = "$(date +%s.%N)";
      end = "$(date +%s.%N)";
      duration = start: end: "$(echo \"${end} - ${start}\" | bc 2>/dev/null || echo \"0\")";
    };

    # File processing metrics
    fileMetrics = {
      # Count files by type
      countFilesByExtension = ''
        count_files_by_type() {
          local files=("$@")
          declare -A file_counts
          declare -A file_sizes
          local total_size=0

          for file in "''${files[@]}"; do
            if [[ -f "$file" ]]; then
              local ext="''${file##*.}"
              local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")

              file_counts["$ext"]=$((''${file_counts["$ext"]:-0} + 1))
              file_sizes["$ext"]=$((''${file_sizes["$ext"]:-0} + size))
              total_size=$((total_size + size))
            fi
          done

          echo "📊 File Analysis:"
          echo "  Total files: ''${#files[@]}"
          echo "  Total size: $(numfmt --to=iec $total_size 2>/dev/null || echo \"$total_size bytes\")"
          echo "  By type:"

          for ext in "''${!file_counts[@]}"; do
            local count="''${file_counts["$ext"]}"
            local size="''${file_sizes["$ext"]}"
            local size_human=$(numfmt --to=iec $size 2>/dev/null || echo "$size bytes")
            echo "    .$ext: $count files ($size_human)"
          done
        }
      '';

      # Calculate processing speed
      calculateSpeed = ''
        calculate_processing_speed() {
          local file_count="$1"
          local duration="$2"
          local total_size="$3"

          if [[ "$duration" != "0" && "$duration" != "" ]]; then
            local files_per_sec=$(echo "scale=2; $file_count / $duration" | bc 2>/dev/null || echo "0")
            local bytes_per_sec=$(echo "scale=0; $total_size / $duration" | bc 2>/dev/null || echo "0")
            local mb_per_sec=$(echo "scale=2; $bytes_per_sec / 1048576" | bc 2>/dev/null || echo "0")

            echo "⚡ Processing Speed:"
            echo "  Files/sec: $files_per_sec"
            echo "  MB/sec: $mb_per_sec"
          fi
        }
      '';
    };

    # Formatter-specific metrics
    formatterMetrics = {
      # Track which formatters ran
      trackFormatters = ''
        track_formatter_usage() {
          local formatters_used=()
          local formatter_times=()

          # This would be populated by the actual formatter execution
          # For now, we'll extract from treefmt output if possible
          echo "🔧 Formatters Used: (detected from treefmt output)"
        }
      '';

      # Performance by formatter type
      formatterBreakdown = ''
        show_formatter_breakdown() {
          echo "📈 Performance Breakdown:"
          echo "  Profile: ''${PERFORMANCE_PROFILE:-balanced}"
          echo "  Mode: ''${INCREMENTAL_MODE:-full}"
          echo "  Cache: ''${CACHE_ENABLED:-disabled}"
          echo "  Parallel: ''${PARALLEL_ENABLED:-disabled}"
        }
      '';
    };

    # System resource metrics
    systemMetrics = {
      # Memory usage tracking
      memoryUsage = ''
        track_memory_usage() {
          local start_mem=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
          echo "start_mem=$start_mem"
        }

        report_memory_usage() {
          local start_mem="$1"
          local end_mem=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
          local mem_diff=$((end_mem - start_mem))

          if [[ "$mem_diff" -gt 0 ]]; then
            echo "💾 Memory: +$(echo "$mem_diff * 1024" | bc 2>/dev/null || echo "$mem_diff KB") bytes"
          fi
        }
      '';

      # CPU usage approximation
      cpuUsage = ''
        estimate_cpu_usage() {
          local duration="$1"
          local cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "1")
          echo "🖥️  CPU cores available: $cores"
          echo "⏱️  Wall time: ''${duration}s"
        }
      '';
    };
  };

  # Benchmark comparison utilities
  benchmarkUtils = {
    # Store benchmark results
    storeBenchmark = ''
            store_benchmark_result() {
              local profile="$1"
              local file_count="$2"
              local duration="$3"
              local cache_dir="''${CACHE_DIR:-~/.cache/treefmt}"
              local benchmark_file="$cache_dir/benchmarks.json"

              mkdir -p "$(dirname "$benchmark_file")"

              local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
              local result=$(cat <<EOF
      {
        "timestamp": "$timestamp",
        "profile": "$profile",
        "file_count": $file_count,
        "duration": $duration,
        "files_per_sec": $(echo "scale=2; $file_count / $duration" | bc 2>/dev/null || echo "0")
      }
      EOF
      )

              # Append to benchmarks file (simple JSON lines format)
              echo "$result" >> "$benchmark_file"
            }
    '';

    # Show benchmark history
    showBenchmarkHistory = ''
      show_benchmark_history() {
        local cache_dir="''${CACHE_DIR:-~/.cache/treefmt}"
        local benchmark_file="$cache_dir/benchmarks.json"

        if [[ -f "$benchmark_file" ]]; then
          echo "📊 Recent Performance History (last 5 runs):"
          tail -5 "$benchmark_file" | while IFS= read -r line; do
            local timestamp=$(echo "$line" | sed -n 's/.*"timestamp": *"\([^"]*\)".*/\1/p')
            local profile=$(echo "$line" | sed -n 's/.*"profile": *"\([^"]*\)".*/\1/p')
            local file_count=$(echo "$line" | sed -n 's/.*"file_count": *\([0-9]*\).*/\1/p')
            local duration=$(echo "$line" | sed -n 's/.*"duration": *\([0-9.]*\).*/\1/p')
            local speed=$(echo "$line" | sed -n 's/.*"files_per_sec": *\([0-9.]*\).*/\1/p')

            echo "  $(date -d "$timestamp" "+%H:%M:%S" 2>/dev/null || echo "$timestamp"): $file_count files in ''${duration}s ($speed files/sec, $profile profile)"
          done
        else
          echo "📊 No benchmark history available yet"
        fi
      }
    '';

    # Performance recommendations
    performanceRecommendations = ''
      suggest_performance_optimizations() {
        local file_count="$1"
        local duration="$2"
        local profile="$3"

        echo "💡 Performance Recommendations:"

        if [[ "$profile" == "thorough" && "$file_count" -gt 100 ]]; then
          echo "  • Consider switching to 'balanced' profile for faster processing"
        fi

        if [[ "$file_count" -gt 50 && "$duration" != "0" ]]; then
          local speed=$(echo "scale=2; $file_count / $duration" | bc 2>/dev/null || echo "0")
          local speed_int=$(echo "$speed" | cut -d. -f1)

          if [[ "$speed_int" -lt 10 ]]; then
            echo "  • Enable incremental formatting for faster subsequent runs"
            echo "  • Consider using 'fast' profile if accuracy allows"
            echo "  • Enable parallel processing if available"
          fi
        fi

        if [[ ! -d "''${CACHE_DIR:-~/.cache/treefmt}" ]]; then
          echo "  • Enable caching for improved performance"
        fi

        if [[ "$INCREMENTAL_MODE" != "git" && -d ".git" ]]; then
          echo "  • Consider enabling git-based incremental formatting"
        fi
      }
    '';
  };

  # Complete performance reporting function
  generatePerformanceReport = {
    # Comprehensive performance report
    fullReport = ''
      generate_performance_report() {
        local start_time="$1"
        local end_time="$2"
        local file_count="$3"
        local files_array=("''${@:4}")
        local profile="''${PERFORMANCE_PROFILE:-balanced}"
        local mode="''${INCREMENTAL_MODE:-full}"

        local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")

        echo ""
        echo "🎯 Performance Report"
        echo "=================="

        # Basic metrics
        echo "⏱️  Timing:"
        echo "  Duration: ''${duration}s"
        echo "  Started: $(date -d "@$start_time" "+%H:%M:%S" 2>/dev/null || echo "N/A")"
        echo "  Finished: $(date -d "@$end_time" "+%H:%M:%S" 2>/dev/null || echo "N/A")"

        # File metrics
        count_files_by_type "''${files_array[@]}"

        # Calculate total size for speed calculation
        local total_size=0
        for file in "''${files_array[@]}"; do
          if [[ -f "$file" ]]; then
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            total_size=$((total_size + size))
          fi
        done

        # Processing speed
        calculate_processing_speed "$file_count" "$duration" "$total_size"

        # Formatter breakdown
        show_formatter_breakdown

        # System resource usage
        estimate_cpu_usage "$duration"

        # Store benchmark for future comparison
        store_benchmark_result "$profile" "$file_count" "$duration"

        # Show historical context
        show_benchmark_history

        # Performance recommendations
        suggest_performance_optimizations "$file_count" "$duration" "$profile"

        echo "=================="
      }
    '';

    # Quick summary report
    quickReport = ''
      generate_quick_report() {
        local duration="$1"
        local file_count="$2"
        local profile="$3"

        echo "✅ Completed in ''${duration}s (''${file_count} files, $profile profile)"

        if [[ "$duration" != "0" && "$file_count" -gt 0 ]]; then
          local speed=$(echo "scale=1; $file_count / $duration" | bc 2>/dev/null || echo "0")
          echo "⚡ Speed: $speed files/sec"
        fi
      }
    '';
  };

  # Export helper functions for shell scripts
  exportFunctions = ''
    # Source all performance tracking functions
    ${performanceMetrics.fileMetrics.countFilesByExtension}
    ${performanceMetrics.fileMetrics.calculateSpeed}
    ${performanceMetrics.formatterMetrics.formatterBreakdown}
    ${performanceMetrics.systemMetrics.memoryUsage}
    ${performanceMetrics.systemMetrics.cpuUsage}
    ${benchmarkUtils.storeBenchmark}
    ${benchmarkUtils.showBenchmarkHistory}
    ${benchmarkUtils.performanceRecommendations}
    ${generatePerformanceReport.fullReport}
    ${generatePerformanceReport.quickReport}
  '';
in {
  inherit
    performanceMetrics
    benchmarkUtils
    generatePerformanceReport
    exportFunctions
    ;

  # Export shell script helpers
  shellHelpers = {
    # Basic timing
    startTimer = performanceMetrics.timing.start;
    endTimer = performanceMetrics.timing.end;

    # File analysis
    analyzeFiles = performanceMetrics.fileMetrics.countFilesByExtension;

    # Complete reporting
    fullReport = generatePerformanceReport.fullReport;
    quickReport = generatePerformanceReport.quickReport;

    # Export all functions
    exportAll = exportFunctions;
  };
}
