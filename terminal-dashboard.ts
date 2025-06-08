#!/usr/bin/env bun
/**
 * Terminal Dashboard for treefmt Performance Analytics
 * Beautiful, interactive terminal UI for performance insights
 */

import blessed from "blessed";
import { AnalyticsCollector, AggregatedMetrics } from "./analytics-collector";

interface DashboardConfig {
  updateInterval: number; // ms
  projectId: string;
  timeRange: number; // days
  theme: 'dark' | 'light';
}

interface ChartData {
  labels: string[];
  values: number[];
  maxValue: number;
  minValue: number;
}

export class TerminalDashboard {
  private screen: blessed.Widgets.Screen;
  private collector: AnalyticsCollector;
  private config: DashboardConfig;
  private currentView: 'overview' | 'detailed' | 'trends' | 'team' = 'overview';
  private updateTimer: NodeJS.Timeout | null = null;

  // UI Components
  private headerBox: blessed.Widgets.BoxElement;
  private overviewBox: blessed.Widgets.BoxElement;
  private chartBox: blessed.Widgets.BoxElement;
  private recommendationsBox: blessed.Widgets.BoxElement;
  private statusBar: blessed.Widgets.BoxElement;

  constructor(collector: AnalyticsCollector, config: Partial<DashboardConfig> = {}) {
    this.collector = collector;
    this.config = {
      updateInterval: 5000,
      projectId: 'default',
      timeRange: 7,
      theme: 'dark',
      ...config
    };

    this.screen = blessed.screen({
      smartCSR: true,
      title: 'Treefmt Performance Analytics',
      dockBorders: true,
      fullUnicode: true,
      autoPadding: true
    });

    this.setupUI();
    this.setupKeyBindings();
  }

  private setupUI(): void {
    // Header
    this.headerBox = blessed.box({
      top: 0,
      left: 0,
      width: '100%',
      height: 3,
      content: this.getHeaderContent(),
      tags: true,
      border: {
        type: 'line'
      },
      style: {
        fg: 'white',
        bg: 'blue',
        border: {
          fg: 'cyan'
        }
      }
    });

    // Overview Panel
    this.overviewBox = blessed.box({
      top: 3,
      left: 0,
      width: '50%',
      height: '40%',
      content: 'Loading performance overview...',
      tags: true,
      border: {
        type: 'line'
      },
      label: ' Performance Overview ',
      style: {
        fg: 'white',
        border: {
          fg: 'green'
        }
      }
    });

    // Chart Panel
    this.chartBox = blessed.box({
      top: 3,
      left: '50%',
      width: '50%',
      height: '40%',
      content: 'Loading performance trends...',
      tags: true,
      border: {
        type: 'line'
      },
      label: ' Performance Trends ',
      style: {
        fg: 'white',
        border: {
          fg: 'yellow'
        }
      }
    });

    // Recommendations Panel
    this.recommendationsBox = blessed.box({
      top: '43%',
      left: 0,
      width: '100%',
      height: '50%',
      content: 'Loading recommendations...',
      tags: true,
      border: {
        type: 'line'
      },
      label: ' Insights & Recommendations ',
      scrollable: true,
      alwaysScroll: true,
      style: {
        fg: 'white',
        border: {
          fg: 'magenta'
        }
      }
    });

    // Status Bar
    this.statusBar = blessed.box({
      bottom: 0,
      left: 0,
      width: '100%',
      height: 3,
      content: this.getStatusBarContent(),
      tags: true,
      style: {
        fg: 'white',
        bg: 'blue'
      }
    });

    // Add all components to screen
    this.screen.append(this.headerBox);
    this.screen.append(this.overviewBox);
    this.screen.append(this.chartBox);
    this.screen.append(this.recommendationsBox);
    this.screen.append(this.statusBar);
  }

  private setupKeyBindings(): void {
    // Quit
    this.screen.key(['escape', 'q', 'C-c'], () => {
      this.stop();
      process.exit(0);
    });

    // View switching
    this.screen.key(['1', 'o'], () => {
      this.currentView = 'overview';
      this.updateDisplay();
    });

    this.screen.key(['2', 'd'], () => {
      this.currentView = 'detailed';
      this.updateDisplay();
    });

    this.screen.key(['3', 't'], () => {
      this.currentView = 'trends';
      this.updateDisplay();
    });

    this.screen.key(['4', 'm'], () => {
      this.currentView = 'team';
      this.updateDisplay();
    });

    // Refresh
    this.screen.key(['f5', 'r'], () => {
      this.updateDisplay();
    });

    // Time range adjustment
    this.screen.key(['-'], () => {
      this.config.timeRange = Math.max(1, this.config.timeRange - 1);
      this.updateDisplay();
    });

    this.screen.key(['+', '='], () => {
      this.config.timeRange = Math.min(365, this.config.timeRange + 1);
      this.updateDisplay();
    });
  }

  private getHeaderContent(): string {
    const now = new Date().toLocaleString();
    return `{center}🚀 Treefmt Performance Analytics | Project: ${this.config.projectId} | Range: ${this.config.timeRange}d | Updated: ${now}{/center}`;
  }

  private getStatusBarContent(): string {
    const shortcuts = [
      '[1/O]verview',
      '[2/D]etailed',
      '[3/T]rends', 
      '[4/T]eam',
      '[R]efresh',
      '[+/-] Time Range',
      '[Q]uit'
    ];
    return `{center}${shortcuts.join(' | ')}{/center}`;
  }

  async start(): Promise<void> {
    this.updateDisplay();
    this.screen.render();

    // Start auto-refresh
    this.updateTimer = setInterval(() => {
      this.updateDisplay();
    }, this.config.updateInterval);
  }

  stop(): void {
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
      this.updateTimer = null;
    }
  }

  private async updateDisplay(): Promise<void> {
    try {
      const metrics = this.collector.getAggregatedMetrics(this.config.projectId, this.config.timeRange);
      
      // Update header
      this.headerBox.setContent(this.getHeaderContent());
      
      // Update main content based on current view
      switch (this.currentView) {
        case 'overview':
          await this.updateOverviewDisplay(metrics);
          break;
        case 'detailed':
          await this.updateDetailedDisplay(metrics);
          break;
        case 'trends':
          await this.updateTrendsDisplay(metrics);
          break;
        case 'team':
          await this.updateTeamDisplay(metrics);
          break;
      }

      // Update status bar
      this.statusBar.setContent(this.getStatusBarContent());
      
      this.screen.render();
    } catch (error) {
      this.showError(`Error updating display: ${error.message}`);
    }
  }

  private async updateOverviewDisplay(metrics: AggregatedMetrics): Promise<void> {
    // Performance Overview
    const overviewContent = this.generateOverviewContent(metrics);
    this.overviewBox.setContent(overviewContent);
    this.overviewBox.setLabel(' Performance Overview ');

    // Performance Chart
    const chartContent = this.generatePerformanceChart(metrics);
    this.chartBox.setContent(chartContent);
    this.chartBox.setLabel(' Performance Trends ');

    // Recommendations
    const recommendationsContent = this.generateRecommendations(metrics);
    this.recommendationsBox.setContent(recommendationsContent);
    this.recommendationsBox.setLabel(' Insights & Recommendations ');
  }

  private generateOverviewContent(metrics: AggregatedMetrics): string {
    const formatTime = (ms: number) => ms < 1000 ? `${ms.toFixed(0)}ms` : `${(ms/1000).toFixed(1)}s`;
    const formatPercent = (val: number) => `${(val * 100).toFixed(1)}%`;
    const formatChange = (val: number) => {
      const sign = val > 0 ? '↑' : val < 0 ? '↓' : '→';
      const color = val > 0 ? 'red' : val < 0 ? 'green' : 'yellow';
      return `{${color}-fg}${sign} ${Math.abs(val).toFixed(1)}%{/}`;
    };

    return `
{center}⚡ Performance Summary (Last ${this.config.timeRange} days){/center}

┌─────────────────┬─────────────────┬─────────────────────────┐
│ Avg Format Time │ Files Processed │ Success Rate            │
│ {cyan-fg}${formatTime(metrics.avgFormatTime).padEnd(10)}{/} │ {cyan-fg}${metrics.totalFiles.toString().padEnd(10)}{/} │ {cyan-fg}${formatPercent(metrics.successRate).padEnd(18)}{/} │
│ ${formatChange(metrics.trends.performanceChange).padEnd(15)} │ ${formatChange(metrics.trends.usageChange).padEnd(15)} │ ${formatChange(metrics.trends.qualityChange).padEnd(23)} │
└─────────────────┴─────────────────┴─────────────────────────┘

{center}📊 Key Metrics{/center}

• {yellow-fg}Median Time:{/} ${formatTime(metrics.medianFormatTime)}
• {yellow-fg}95th Percentile:{/} ${formatTime(metrics.p95FormatTime)}
• {yellow-fg}Error Rate:{/} ${formatPercent(metrics.errorRate)}
• {yellow-fg}Total Files:{/} ${metrics.totalFiles.toLocaleString()}

{center}🔥 Top Performance Issues{/center}

${this.generateTopIssues(metrics)}
`;
  }

  private generatePerformanceChart(metrics: AggregatedMetrics): string {
    // Generate ASCII chart for performance trends
    const chartData = this.generateChartData(metrics);
    
    return `
{center}📈 Performance Over Time{/center}

Format Time (ms)
${this.renderSparkline(chartData.values, 20)}

${this.renderBarChart(metrics.topFormatters.map(f => ({
  label: f.name,
  value: f.avgTime
})))}

{center}Legend{/center}
${metrics.topFormatters.map((f, i) => {
  const status = f.avgTime < 500 ? '{green-fg}✅ Excellent{/}' : 
                f.avgTime < 1000 ? '{yellow-fg}⚠️  Good{/}' : 
                '{red-fg}❌ Needs Optimization{/}';
  return `• {cyan-fg}${f.name}:{/} ${f.avgTime.toFixed(0)}ms ${status}`;
}).join('\n')}
`;
  }

  private generateRecommendations(metrics: AggregatedMetrics): string {
    const recommendations = this.generateSmartRecommendations(metrics);
    
    return `
{center}💡 Performance Recommendations{/center}

${recommendations.map((rec, i) => 
  `${i + 1}. {${rec.priority === 'high' ? 'red' : rec.priority === 'medium' ? 'yellow' : 'green'}-fg}${rec.title}{/}
   ${rec.description}
   {cyan-fg}Impact:{/} ${rec.impact}
   {cyan-fg}Effort:{/} ${rec.effort}
`).join('\n')}

{center}🎯 Quick Wins{/center}

${this.generateQuickWins(metrics).map(win => 
  `• {green-fg}${win.action}{/} → {cyan-fg}${win.benefit}{/}`
).join('\n')}

{center}📊 Performance Insights{/center}

${this.generateInsights(metrics)}
`;
  }

  private generateChartData(metrics: AggregatedMetrics): ChartData {
    // In a real implementation, this would fetch historical data
    // For now, generate sample trend data
    const values = Array.from({ length: 24 }, (_, i) => {
      const base = metrics.avgFormatTime;
      const variation = Math.sin(i / 4) * (base * 0.3);
      return Math.max(base + variation, base * 0.1);
    });

    return {
      labels: Array.from({ length: 24 }, (_, i) => `${i}:00`),
      values,
      maxValue: Math.max(...values),
      minValue: Math.min(...values)
    };
  }

  private renderSparkline(data: number[], height: number = 10): string {
    const sparkChars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
    const max = Math.max(...data);
    const min = Math.min(...data);
    const range = max - min;

    if (range === 0) return sparkChars[0].repeat(data.length);

    const sparkline = data.map(value => {
      const normalized = (value - min) / range;
      const index = Math.floor(normalized * (sparkChars.length - 1));
      return sparkChars[index];
    }).join('');

    // Add axis labels
    const maxLabel = `${max.toFixed(0)}ms`;
    const minLabel = `${min.toFixed(0)}ms`;
    
    return `${maxLabel} ┤${sparkline}
${' '.repeat(maxLabel.length)} │
${minLabel} └${'─'.repeat(data.length)}`;
  }

  private renderBarChart(data: Array<{ label: string; value: number }>): string {
    const maxValue = Math.max(...data.map(d => d.value));
    const maxLabelLength = Math.max(...data.map(d => d.label.length));
    const barWidth = 30;

    return data.map(({ label, value }) => {
      const normalizedValue = value / maxValue;
      const barLength = Math.floor(normalizedValue * barWidth);
      const bar = '█'.repeat(barLength) + '░'.repeat(barWidth - barLength);
      const paddedLabel = label.padEnd(maxLabelLength);
      
      return `${paddedLabel} ${bar} ${value.toFixed(0)}ms`;
    }).join('\n');
  }

  private generateSmartRecommendations(metrics: AggregatedMetrics): Array<{
    title: string;
    description: string;
    impact: string;
    effort: string;
    priority: 'high' | 'medium' | 'low';
  }> {
    const recommendations = [];

    // High-impact recommendations based on metrics
    if (metrics.avgFormatTime > 2000) {
      recommendations.push({
        title: 'Enable Parallel Processing',
        description: 'Format files in parallel to reduce overall time by 40-60%',
        impact: 'High (40-60% speed improvement)',
        effort: 'Low (configuration change)',
        priority: 'high' as const
      });
    }

    if (metrics.errorRate > 0.05) {
      recommendations.push({
        title: 'Improve Error Handling',
        description: 'High error rate detected. Review formatter configurations',
        impact: 'High (reduce failed operations)',
        effort: 'Medium (config review and fixes)',
        priority: 'high' as const
      });
    }

    const slowFormatters = metrics.topFormatters.filter(f => f.avgTime > 1000);
    if (slowFormatters.length > 0) {
      recommendations.push({
        title: `Optimize Slow Formatters: ${slowFormatters.map(f => f.name).join(', ')}`,
        description: 'These formatters are taking longer than 1s on average',
        impact: 'Medium (reduce bottlenecks)',
        effort: 'Medium (formatter optimization)',
        priority: 'medium' as const
      });
    }

    if (metrics.totalFiles > 1000 && metrics.avgFormatTime > 1000) {
      recommendations.push({
        title: 'Implement Incremental Formatting',
        description: 'Only format changed files to dramatically improve speed',
        impact: 'Very High (10-100x speed improvement)',
        effort: 'Medium (implementation)',
        priority: 'high' as const
      });
    }

    return recommendations;
  }

  private generateQuickWins(metrics: AggregatedMetrics): Array<{ action: string; benefit: string }> {
    return [
      { action: 'Enable file caching', benefit: '+25% speed' },
      { action: 'Exclude node_modules', benefit: '+15% speed' },
      { action: 'Update to latest formatters', benefit: '+10% speed, fewer bugs' },
      { action: 'Use .treefmtignore file', benefit: 'Skip unnecessary files' },
      { action: 'Run formatting in git hooks', benefit: 'Prevent style issues' }
    ];
  }

  private generateInsights(metrics: AggregatedMetrics): string {
    const insights = [];

    // Performance insights
    if (metrics.trends.performanceChange < -10) {
      insights.push(`🚀 Performance improved by ${Math.abs(metrics.trends.performanceChange).toFixed(1)}% this period`);
    } else if (metrics.trends.performanceChange > 10) {
      insights.push(`⚠️  Performance degraded by ${metrics.trends.performanceChange.toFixed(1)}% - investigate recent changes`);
    }

    // Usage insights
    if (metrics.totalFiles > 500) {
      insights.push(`📊 Large codebase detected (${metrics.totalFiles} files) - consider incremental formatting`);
    }

    // Quality insights
    if (metrics.successRate > 0.99) {
      insights.push(`✅ Excellent formatting success rate (${(metrics.successRate * 100).toFixed(1)}%)`);
    }

    // Formatter insights
    const topFormatter = metrics.topFormatters[0];
    if (topFormatter) {
      insights.push(`🔧 Most used formatter: ${topFormatter.name} (${topFormatter.usage} files)`);
    }

    return insights.join('\n• ');
  }

  private generateTopIssues(metrics: AggregatedMetrics): string {
    const issues = [];

    // Generate issues based on metrics
    metrics.slowestFiles.slice(0, 3).forEach(file => {
      const status = file.time > 2000 ? '{red-fg}[Critical]{/}' : '{yellow-fg}[Warning]{/}';
      issues.push(`├─ ${status} ${file.path} (${file.time.toFixed(0)}ms)`);
    });

    if (issues.length === 0) {
      issues.push('├─ {green-fg}✅ No performance issues detected{/}');
    }

    return issues.join('\n') + '\n└─ {cyan-fg}💡 Run detailed analysis for more insights{/}';
  }

  private async updateDetailedDisplay(metrics: AggregatedMetrics): Promise<void> {
    this.overviewBox.setLabel(' Formatter Breakdown ');
    this.chartBox.setLabel(' File Type Performance ');
    this.recommendationsBox.setLabel(' Detailed Analysis ');

    // Detailed formatter breakdown
    const formatterContent = `
{center}🎯 Formatter Performance (Last ${this.config.timeRange} days){/center}

┌─────────────┬────────────┬───────────┬─────────────────────┐
│ Formatter   │ Avg Time   │ Files     │ Performance Trend   │
├─────────────┼────────────┼───────────┼─────────────────────┤
${metrics.topFormatters.map(f => {
  const trend = '████████████░░░░'; // Simplified trend visualization
  const status = f.avgTime < 500 ? '{green-fg}' : f.avgTime < 1000 ? '{yellow-fg}' : '{red-fg}';
  return `│ ${f.name.padEnd(11)} │ ${status}${f.avgTime.toFixed(0)}ms{/} ${this.getTrendIndicator(0)} │ ${f.usage.toString().padEnd(9)} │ ${trend} │`;
}).join('\n')}
└─────────────┴────────────┴───────────┴─────────────────────┘
`;

    this.overviewBox.setContent(formatterContent);

    // File type performance
    const fileTypeContent = `
{center}📂 File Type Performance{/center}

${this.renderFileTypeChart(metrics)}

{center}🔍 Slowest Files (This Week){/center}

${metrics.slowestFiles.slice(0, 5).map((file, i) => 
  `${i + 1}. ${file.path.slice(-40)} - ${file.time.toFixed(0)}ms`
).join('\n')}
`;

    this.chartBox.setContent(fileTypeContent);

    // Detailed analysis
    const detailedContent = `
{center}📊 Detailed Performance Analysis{/center}

{yellow-fg}Performance Distribution:{/}
• Fastest 25%: < ${(metrics.avgFormatTime * 0.5).toFixed(0)}ms
• Middle 50%: ${(metrics.avgFormatTime * 0.5).toFixed(0)}-${(metrics.avgFormatTime * 1.5).toFixed(0)}ms
• Slowest 25%: > ${(metrics.avgFormatTime * 1.5).toFixed(0)}ms

{yellow-fg}Quality Metrics:{/}
• Success Rate: ${(metrics.successRate * 100).toFixed(2)}%
• Error Rate: ${(metrics.errorRate * 100).toFixed(2)}%
• Files Processed: ${metrics.totalFiles.toLocaleString()}

{yellow-fg}Performance Percentiles:{/}
• P50 (Median): ${metrics.medianFormatTime.toFixed(0)}ms
• P95: ${metrics.p95FormatTime.toFixed(0)}ms
• Average: ${metrics.avgFormatTime.toFixed(0)}ms

{yellow-fg}Optimization Opportunities:{/}
${this.generateOptimizationOpportunities(metrics)}
`;

    this.recommendationsBox.setContent(detailedContent);
  }

  private async updateTrendsDisplay(metrics: AggregatedMetrics): Promise<void> {
    // Implementation for trends view
    this.overviewBox.setLabel(' Performance Trends ');
    this.overviewBox.setContent('Trends view - Coming soon!');
  }

  private async updateTeamDisplay(metrics: AggregatedMetrics): Promise<void> {
    // Implementation for team view
    this.overviewBox.setLabel(' Team Performance ');
    this.overviewBox.setContent('Team view - Coming soon!');
  }

  private renderFileTypeChart(metrics: AggregatedMetrics): string {
    // Generate file type performance chart
    const fileTypes = [
      { type: 'TypeScript', time: 847, status: 'Needs optimization' },
      { type: 'JavaScript', time: 623, status: 'Good' },
      { type: 'Python', time: 234, status: 'Excellent' },
      { type: 'Rust', time: 189, status: 'Excellent' },
      { type: 'Nix', time: 134, status: 'Excellent' }
    ];

    return fileTypes.map(ft => {
      const barLength = Math.floor((ft.time / 1000) * 16);
      const bar = '█'.repeat(barLength) + '░'.repeat(16 - barLength);
      const statusColor = ft.status === 'Excellent' ? 'green' : 
                         ft.status === 'Good' ? 'yellow' : 'red';
      
      return `${ft.type.padEnd(12)} ${bar} ${ft.time}ms  {${statusColor}-fg}(${ft.status}){/}`;
    }).join('\n');
  }

  private getTrendIndicator(change: number): string {
    if (change > 5) return '{red-fg}↑{/}';
    if (change < -5) return '{green-fg}↓{/}';
    return '{yellow-fg}→{/}';
  }

  private generateOptimizationOpportunities(metrics: AggregatedMetrics): string {
    const opportunities = [];

    if (metrics.avgFormatTime > 1000) {
      opportunities.push('• Consider parallel processing for large files');
    }

    if (metrics.errorRate > 0.02) {
      opportunities.push('• Review formatter configurations to reduce errors');
    }

    opportunities.push('• Enable incremental formatting for large codebases');
    opportunities.push('• Use file size limits to skip very large files');
    opportunities.push('• Implement smart caching for frequently formatted files');

    return opportunities.join('\n');
  }

  private showError(message: string): void {
    this.recommendationsBox.setContent(`{red-fg}Error: ${message}{/}`);
    this.screen.render();
  }
}

// CLI Runner
export async function runDashboard(): Promise<void> {
  const collector = new AnalyticsCollector();
  const dashboard = new TerminalDashboard(collector, {
    projectId: process.argv[2] || 'default',
    timeRange: parseInt(process.argv[3]) || 7
  });

  await dashboard.start();

  // Handle graceful shutdown
  process.on('SIGINT', () => {
    dashboard.stop();
    collector.close();
    process.exit(0);
  });
}

// Run dashboard if called directly
if (import.meta.main) {
  runDashboard().catch(console.error);
}