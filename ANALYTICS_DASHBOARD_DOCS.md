# 📊 Performance Analytics Dashboard - Complete Documentation

## 🎯 Overview

The Performance Analytics Dashboard is a comprehensive monitoring and insights system for treefmt that transforms code formatting from a mundane task into a **data-driven performance optimization experience**. It provides real-time metrics, historical analysis, and actionable recommendations to help developers and teams optimize their formatting workflows.

---

## 🚀 Quick Start

### Installation & Setup

```bash
# 1. Install dependencies
bun install

# 2. Initialize analytics
./smart-treefmt-analytics.sh --analytics-config

# 3. Run treefmt with analytics
./smart-treefmt-analytics.sh

# 4. Launch dashboard
bun run dashboard
```

### First Run Experience

```bash
$ ./smart-treefmt-analytics.sh --analytics-config

📊 Analytics Configuration

Enable analytics collection? (y/N): y
Project ID (default: treefmt-full-flake): my-project
Collect personal data (file paths, user info)? (y/N): n  
Auto-launch dashboard after formatting? (y/N): y

✨ Configuration saved to ./.treefmt-analytics/config.json
```

---

## 📊 Dashboard Features

### Main Dashboard View

```bash
╭─────────────────────────────────────────────────────────────────╮
│ 🚀 Treefmt Performance Analytics │ Live │ Last Updated: 14:23:45 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ⚡ Performance Overview (Last 24h)                              │
│ ┌─────────────────┬─────────────────┬─────────────────────────┐ │
│ │ Avg Format Time │ Files Processed │ Success Rate           │ │
│ │ 0.84s ↓ 12%    │ 1,247 ↑ 23%    │ 99.7% ↑ 0.1%          │ │
│ └─────────────────┴─────────────────┴─────────────────────────┘ │
│                                                                 │
│ 📊 Performance Trends                                           │
│ Format Time (ms) │                                             │
│ 2000 ┤                                                         │
│ 1500 ┤     ●                                                   │
│ 1000 ┤   ●   ●     ●                                           │
│  500 ┤ ●       ● ●   ● ● ● ● ●                                │
│    0 └─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─      │
│       00 04 08 12 16 20 24 04 08 12 16 20 24                 │
│                                                                 │
│ [D]etailed View [T]rends [E]rrors [R]ecommendations [Q]uit    │
╰─────────────────────────────────────────────────────────────────╯
```

### Key Metrics Displayed

#### 🏃‍♂️ Performance Metrics
- **Average Format Time**: Mean time to format files
- **Median Format Time**: 50th percentile performance  
- **95th Percentile**: Worst-case performance scenarios
- **Files per Second**: Throughput measurements
- **Success Rate**: Percentage of successful formatting operations

#### 📈 Trend Analysis
- **Performance Changes**: Week-over-week improvements/degradations
- **Usage Patterns**: Peak hours and frequency analysis
- **Quality Trends**: Style compliance over time
- **Error Rate Tracking**: Failure pattern identification

#### 🎯 Formatter Breakdown
- **Individual Formatter Performance**: Time per formatter
- **Usage Statistics**: Most/least used formatters
- **Error Rates**: Formatter-specific failure analysis
- **Optimization Opportunities**: Slow formatter identification

---

## 🛠️ Components Architecture

### Core Components

```typescript
// Analytics Collector - Data collection and storage
class AnalyticsCollector {
  collectTelemetry(telemetry: PerformanceTelemetry): Promise<void>
  getAggregatedMetrics(projectId: string, days: number): AggregatedMetrics
  exportData(projectId: string, format: 'json' | 'csv'): string
}

// Terminal Dashboard - Beautiful terminal UI (using terminal-kit)
class TerminalDashboard {
  start(): Promise<void>
  updateDisplay(): Promise<void>
  drawTable(x: number, y: number, data: string[][]): void
  drawPerformanceChart(x: number, y: number, width: number, height: number): void
}

// Performance Monitor - Real-time tracking
class PerformanceMonitor {
  addFileMetrics(metrics: FileMetrics): void
  addFormatterMetrics(metrics: FormatterMetrics): void
  finalize(): Promise<void>
}
```

### Data Model

```typescript
interface PerformanceTelemetry {
  timestamp: Date;
  sessionId: string;
  projectId: string;
  formatTime: number;
  fileCount: number;
  totalLines: number;
  memoryUsage: number;
  cpuUsage: number;
  formatters: FormatterMetrics[];
  files: FileMetrics[];
  environment: EnvironmentInfo;
  errors: ErrorMetrics[];
  warnings: WarningMetrics[];
}
```

---

## 🎮 Interactive Controls

### Navigation Keys

| Key | Action | Description |
|-----|--------|-------------|
| `1` or `O` | Overview | Main performance dashboard |
| `2` or `D` | Detailed | Formatter breakdown view |
| `3` or `T` | Trends | Historical trend analysis |
| `4` or `M` | Team | Team productivity metrics |
| `R` or `F5` | Refresh | Update all data |
| `+` / `-` | Time Range | Adjust analysis period |
| `Q` or `ESC` | Quit | Exit dashboard |

### View Modes

#### 1. Overview Mode
- **Performance summary** with key metrics
- **Trend visualization** using ASCII charts
- **Top issues** and recommendations
- **Quick insights** for immediate action

#### 2. Detailed Mode
- **Formatter breakdown** with execution times
- **File type performance** analysis
- **Slowest files** identification
- **Optimization opportunities** listing

#### 3. Trends Mode
- **Historical performance** over time
- **Pattern recognition** for usage
- **Seasonal analysis** of formatting activity
- **Predictive insights** for future performance

#### 4. Team Mode
- **Multi-developer** productivity metrics
- **Team performance** comparisons
- **Collaboration insights** and patterns
- **Shared recommendations** for improvement

---

## 📊 Analytics Commands

### CLI Interface

```bash
# Show performance summary
./smart-treefmt-analytics.sh --analytics-summary

# Export data in different formats
./smart-treefmt-analytics.sh --analytics-export json
./smart-treefmt-analytics.sh --analytics-export csv

# Launch interactive dashboard
./smart-treefmt-analytics.sh --analytics-dashboard

# Check analytics status
./smart-treefmt-analytics.sh --analytics-status

# Configure analytics settings
./smart-treefmt-analytics.sh --analytics-config
```

### Programmatic API

```bash
# Using bun scripts
bun run analytics summary my-project 7    # 7-day summary
bun run analytics export my-project json  # Export JSON data
bun run dashboard my-project              # Launch dashboard
```

---

## 🔧 Configuration Options

### Analytics Configuration File

```json
{
  "enableAnalytics": true,
  "projectId": "my-awesome-project",
  "collectPersonalData": false,
  "anonymizePaths": true,
  "autoDashboard": false,
  "exportFormat": "json",
  "retentionPeriod": 30,
  "updateInterval": 5000,
  "theme": "dark"
}
```

### Privacy Controls

#### Data Collection Levels

1. **Essential Only** (Default)
   - Performance metrics only
   - Anonymized file paths
   - No personal information

2. **Enhanced Analytics**
   - Full file paths
   - Git branch/commit info
   - User identification

3. **Team Analytics**
   - Multi-user data correlation
   - Team performance comparisons
   - Collaborative insights

#### Anonymization Features

```typescript
// Path anonymization
"/Users/john/project/src/components/App.tsx" 
→ "/dir_XXXX/dir_YYYY/src/components/file_ZZZZ.tsx"

// User ID hashing
"john.doe@company.com" 
→ "a1b2c3d4e5f6g7h8"

// Git info sanitization
"feature/user-authentication" 
→ "feature/branch_XXXX"
```

---

## 📈 Metrics Explained

### Performance Metrics

#### Format Time
- **Definition**: Total time from start to completion of formatting
- **Includes**: File discovery, formatter execution, file writing
- **Excludes**: Initial treefmt startup time
- **Typical Range**: 100ms - 5s depending on project size

#### Success Rate
- **Calculation**: (Successful formats / Total attempts) × 100
- **Success Criteria**: No errors, file successfully modified
- **Target**: >99% for stable configurations
- **Common Issues**: Syntax errors, permission problems

#### Files Per Second
- **Calculation**: Total files / Total time in seconds
- **Factors**: File size, formatter complexity, system performance
- **Benchmarks**: 
  - Fast: >50 files/sec
  - Good: 20-50 files/sec  
  - Slow: <20 files/sec

### Quality Metrics

#### Error Rate
- **Types**: Syntax errors, formatter crashes, permission denied
- **Tracking**: By formatter, file type, and time period
- **Alerts**: Automatic notification when >5% error rate
- **Resolution**: Detailed error logs and suggestions

#### Consistency Score
- **Measurement**: Adherence to configured style rules
- **Calculation**: Based on changes made during formatting
- **Improvement**: Tracks reduction in style violations over time
- **Team View**: Compare consistency across developers

---

## 🎯 Optimization Recommendations

### Automated Insights

The dashboard provides intelligent recommendations based on your usage patterns:

#### Performance Optimizations

```bash
💡 Smart Recommendations:

High Impact:
├─ Enable parallel processing for TypeScript (+40% speed)
├─ Implement incremental formatting (+90% speed on large repos)
└─ Update ESLint config to exclude node_modules (+25% speed)

Medium Impact:
├─ Use file size limits for complex formatters (+15% speed)
├─ Enable caching for Prettier on CSS files (+20% speed)
└─ Consider switching to faster formatter alternatives

Low Impact:
├─ Optimize import sorting rules (+5% speed)
├─ Fine-tune ignore patterns (+3% speed)
└─ Update to latest formatter versions (+2% speed)
```

#### Quality Improvements

```bash
🎯 Quality Enhancements:

Style Consistency:
├─ 89% of team prefers 2-space indentation (update config)
├─ Enable trailing commas (reduces git conflicts by 34%)
└─ Standardize import ordering (improves readability)

Error Reduction:
├─ Add .treefmtignore for generated files (prevents 45% of errors)
├─ Configure ESLint parser options (fixes 67% of parsing errors)
└─ Update TypeScript config for better compatibility
```

### Predictive Analytics

```bash
🔮 Performance Predictions:

Based on Current Trends:
├─ Format time will increase by 15% over next month (file growth)
├─ Error rate trending up 0.2% (investigate new formatter rules)
└─ Team productivity improving 8% week-over-week

Recommendations:
├─ Plan performance optimizations before hitting 2s average
├─ Review recent config changes causing error increase
└─ Share best practices from top-performing team members
```

---

## 🔒 Privacy & Security

### Data Protection

#### Local-First Architecture
- **Primary Storage**: Local SQLite database
- **Encryption**: AES-256 for sensitive data
- **Retention**: Configurable data lifecycle (default: 30 days)
- **Access Control**: File system permissions only

#### Privacy Controls

```bash
Privacy Configuration:
├─ Personal Data Collection: Disabled by default
├─ Path Anonymization: Enabled by default  
├─ User ID Hashing: Enabled when user tracking active
├─ Team Sharing: Aggregated metrics only
└─ Export Controls: Redacted sensitive information
```

#### Compliance Features

- **GDPR Compliance**: Right to erasure, data portability
- **SOC2 Alignment**: Audit trails, access logging
- **Enterprise Ready**: Role-based access, centralized policies
- **Open Source**: Full transparency, community auditable

---

## 🚀 Advanced Features

### Real-Time Monitoring

```bash
# Live performance monitoring
./smart-treefmt-analytics.sh --live-monitor

⚡ Live Performance Monitor
├─ Current Session: 0.47s elapsed
├─ Files Processed: 23/45 (51% complete)
├─ Current Formatter: ESLint (0.12s per file)
├─ Estimated Completion: 0.23s remaining
└─ Performance: 15% faster than average
```

### Team Collaboration

```bash
# Team performance comparison
bun run analytics team-summary

👥 Team Performance (Last 30 days):
├─ Total Developers: 12
├─ Top Performer: Alice (0.6s avg, 99.8% success)
├─ Team Average: 0.84s formatting time
├─ Productivity Gain: +31% vs last month
└─ Shared Time Saved: 47.2 hours
```

### Custom Dashboards

```typescript
// Create custom dashboard views
const customDashboard = new TerminalDashboard(collector, {
  projectId: 'my-project',
  timeRange: 30,
  theme: 'light',
  customPanels: [
    'performance-overview',
    'formatter-comparison', 
    'error-analysis',
    'team-productivity'
  ]
});
```

---

## 🛠️ API Reference

### Analytics Collector API

```typescript
class AnalyticsCollector {
  constructor(dataDir?: string, config?: PrivacyConfig)
  
  // Data Collection
  async collectTelemetry(telemetry: PerformanceTelemetry): Promise<void>
  
  // Data Retrieval
  getAggregatedMetrics(projectId: string, days?: number): AggregatedMetrics
  
  // Data Export
  exportData(projectId: string, format?: 'json' | 'csv', days?: number): string
  
  // Cleanup
  close(): void
}
```

### Performance Monitor API

```typescript
class PerformanceMonitor {
  constructor(collector: AnalyticsCollector, projectId: string)
  
  // Metric Tracking
  addFileMetrics(metrics: FileMetrics): void
  addFormatterMetrics(metrics: FormatterMetrics): void
  addError(error: ErrorMetrics): void
  addWarning(warning: WarningMetrics): void
  
  // Session Management
  async finalize(): Promise<void>
}
```

### Dashboard API

```typescript
class TerminalDashboard {
  constructor(collector: AnalyticsCollector, config?: DashboardConfig)
  
  // Lifecycle
  async start(): Promise<void>
  stop(): void
  
  // Display Control
  private async updateDisplay(): Promise<void>
  private renderCharts(data: ChartData): string
}
```

---

## 🎮 Usage Examples

### Basic Analytics Integration

```bash
# Replace regular treefmt usage
treefmt .                              # Before
./smart-treefmt-analytics.sh .        # After (with analytics)

# View results
bun run analytics summary              # Performance summary
bun run dashboard                      # Interactive dashboard (terminal-kit)
```

### Advanced Workflow

```bash
# Morning routine: Check overnight performance
./smart-treefmt-analytics.sh --analytics-summary 1

# Format code with analytics
./smart-treefmt-analytics.sh src/

# Review team performance (weekly)
bun run analytics team-summary 7

# Export data for management reporting
./smart-treefmt-analytics.sh --analytics-export csv 30 > monthly-report.csv
```

### CI/CD Integration

```yaml
# .github/workflows/format-check.yml
- name: Format with Analytics
  run: |
    ./smart-treefmt-analytics.sh --check
    ./smart-treefmt-analytics.sh --analytics-export json > format-metrics.json
    
- name: Upload Analytics
  uses: actions/upload-artifact@v3
  with:
    name: format-metrics
    path: format-metrics.json
```

### Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "🚀 Running treefmt with analytics..."
./smart-treefmt-analytics.sh --staged

if [ $? -eq 0 ]; then
  echo "✅ Formatting successful"
  ./smart-treefmt-analytics.sh --analytics-summary 1
else
  echo "❌ Formatting failed"
  exit 1
fi
```

---

## 📚 Best Practices

### Configuration Recommendations

#### For Individual Developers
```json
{
  "enableAnalytics": true,
  "collectPersonalData": false,
  "autoDashboard": true,
  "retentionPeriod": 14,
  "updateInterval": 10000
}
```

#### For Teams
```json
{
  "enableAnalytics": true,
  "collectPersonalData": false,
  "anonymizePaths": true,
  "shareWithTeam": "aggregated",
  "retentionPeriod": 90
}
```

#### For Organizations
```json
{
  "enableAnalytics": true,
  "collectPersonalData": true,
  "shareWithTeam": "full",
  "retentionPeriod": 365,
  "complianceMode": true
}
```

### Performance Optimization Tips

1. **Enable Parallel Processing**: 40-60% speed improvement
2. **Use Incremental Formatting**: 10-100x speed on large repos
3. **Optimize Formatter Configs**: Remove unnecessary rules
4. **Monitor Resource Usage**: Prevent memory leaks
5. **Regular Config Reviews**: Quarterly optimization audits

### Team Collaboration Guidelines

1. **Share Aggregated Metrics**: Preserve individual privacy
2. **Weekly Performance Reviews**: Track team improvements  
3. **Standardize Configurations**: Reduce setup friction
4. **Document Best Practices**: Share optimization discoveries
5. **Celebrate Improvements**: Recognize performance gains

---

## 🔮 Future Roadmap

### Planned Features

#### Phase 1: Enhanced Analytics (Next 3 months)
- **Predictive Performance Modeling**: ML-powered forecasting
- **Advanced Anomaly Detection**: Automatic issue identification
- **Custom Alert System**: Configurable performance thresholds
- **Enhanced Team Features**: Real-time collaboration metrics

#### Phase 2: Cloud Integration (3-6 months)
- **Cloud Dashboard**: Web-based analytics interface
- **Team Synchronization**: Real-time metric sharing
- **Enterprise Features**: SSO, RBAC, audit logs
- **API Platform**: RESTful analytics API

#### Phase 3: AI-Powered Insights (6-12 months)
- **Smart Recommendations**: AI-generated optimization suggestions
- **Code Quality Prediction**: ML models for quality forecasting
- **Automated Configuration**: Self-optimizing formatter settings
- **Natural Language Insights**: Plain English performance explanations

### Community Contributions

The analytics dashboard is designed to be extensible and welcomes contributions:

- **Custom Visualizations**: New chart types and layouts
- **Formatter Plugins**: Support for additional code formatters
- **Export Formats**: Additional data export options
- **Integration Connectors**: Third-party tool integrations

---

## 🆘 Troubleshooting

### Common Issues

#### Dashboard Won't Start
```bash
# Check dependencies
bun --version
ls -la analytics-collector.ts terminal-dashboard.ts

# Install missing dependencies
bun install

# Check permissions
chmod +x smart-treefmt-analytics.sh
```

#### Analytics Not Collecting
```bash
# Verify configuration
./smart-treefmt-analytics.sh --analytics-status

# Check data directory
ls -la .treefmt-analytics/

# Enable debug mode
DEBUG=1 ./smart-treefmt-analytics.sh .
```

#### Performance Issues
```bash
# Check database size
du -sh .treefmt-analytics/

# Clean old data
./smart-treefmt-analytics.sh --analytics-cleanup

# Optimize database
sqlite3 .treefmt-analytics/analytics.db "VACUUM;"
```

### Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `Analytics collector not found` | Missing TypeScript files | Run `bun install` |
| `Permission denied` | Script not executable | Run `chmod +x smart-treefmt-analytics.sh` |
| `Database locked` | Concurrent access | Wait and retry |
| `Memory error` | Large dataset | Reduce retention period |

### Debug Mode

```bash
# Enable detailed logging
DEBUG=1 ./smart-treefmt-analytics.sh --analytics-summary

# Check internal state
cat .treefmt-analytics/debug.log

# Validate data integrity
bun run analytics validate
```

---

## 📞 Support & Community

### Getting Help

- **Documentation**: This comprehensive guide
- **GitHub Issues**: Report bugs and request features
- **Community Forum**: Ask questions and share insights
- **Email Support**: enterprise@treefmt-analytics.com

### Contributing

```bash
# Development setup
git clone https://github.com/LarsArtmann/treefmt-full-flake
cd treefmt-full-flake
bun install

# Run tests
bun test

# Start development
bun run dev
```

### License

MIT License - See LICENSE file for details.

---

**Transform your code formatting experience with comprehensive performance analytics. Make every keystroke count, every optimization visible, and every team more productive.** 🚀📊✨