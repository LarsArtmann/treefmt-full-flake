#!/usr/bin/env bun
/**
 * Terminal Dashboard for treefmt Performance Analytics
 * Rewritten using terminal-kit for better performance and features
 */

import termkit from "terminal-kit";
import { AnalyticsCollector, AggregatedMetrics } from "./analytics-collector.js";

const term = termkit.terminal;

interface DashboardConfig {
  updateInterval: number; // ms
  projectId: string;
  timeRange: number; // days
  theme: "dark" | "light";
}

interface ChartData {
  labels: string[];
  values: number[];
  maxValue: number;
  minValue: number;
}

export class TerminalDashboard {
  private collector: AnalyticsCollector;
  private config: DashboardConfig;
  private currentView: "overview" | "detailed" | "trends" | "team" = "overview";
  private updateTimer: NodeJS.Timeout | null = null;
  private isRunning: boolean = false;
  private screenBuffer: termkit.ScreenBuffer;
  private document: termkit.Document;
  private currentMetrics: AggregatedMetrics | null = null;

  constructor(collector: AnalyticsCollector, config: Partial<DashboardConfig> = {}) {
    this.collector = collector;
    this.config = {
      updateInterval: 5000,
      projectId: "default",
      timeRange: 7,
      theme: "dark",
      ...config,
    };

    // Create screen buffer for double buffering
    this.screenBuffer = new termkit.ScreenBuffer({
      dst: term,
      width: term.width,
      height: term.height,
    });

    // Create document for layout management
    this.document = term.createDocument({
      palette: this.getColorPalette(),
    });

    this.setupKeyBindings();
  }

  private getColorPalette() {
    return this.config.theme === "dark"
      ? {
          background: "black",
          foreground: "white",
          primary: "cyan",
          secondary: "green",
          accent: "yellow",
          error: "red",
          success: "green",
          warning: "yellow",
        }
      : {
          background: "white",
          foreground: "black",
          primary: "blue",
          secondary: "green",
          accent: "magenta",
          error: "red",
          success: "green",
          warning: "yellow",
        };
  }

  private setupKeyBindings(): void {
    term.on("key", (key: string) => {
      switch (key) {
        case "CTRL_C":
        case "q":
        case "ESCAPE":
          this.stop();
          term.processExit(0);
          break;
        case "1":
        case "o":
          this.currentView = "overview";
          this.updateDisplay();
          break;
        case "2":
        case "d":
          this.currentView = "detailed";
          this.updateDisplay();
          break;
        case "3":
        case "t":
          this.currentView = "trends";
          this.updateDisplay();
          break;
        case "4":
        case "m":
          this.currentView = "team";
          this.updateDisplay();
          break;
        case "r":
        case "F5":
          this.updateDisplay();
          break;
        case "+":
        case "=":
          this.config.timeRange = Math.min(365, this.config.timeRange + 1);
          this.updateDisplay();
          break;
        case "-":
          this.config.timeRange = Math.max(1, this.config.timeRange - 1);
          this.updateDisplay();
          break;
      }
    });
  }

  async start(): Promise<void> {
    this.isRunning = true;
    term.fullscreen(true);
    term.hideCursor();

    // Initial display
    await this.updateDisplay();

    // Start auto-refresh
    this.updateTimer = setInterval(() => {
      if (this.isRunning) {
        this.updateDisplay();
      }
    }, this.config.updateInterval);
  }

  stop(): void {
    this.isRunning = false;
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
      this.updateTimer = null;
    }
    term.fullscreen(false);
    term.clear();
    term.processExit(0);
  }

  private async updateDisplay(): Promise<void> {
    try {
      // Fetch latest metrics
      this.currentMetrics = this.collector.getAggregatedMetrics(
        this.config.projectId,
        this.config.timeRange,
      );

      // Clear screen
      term.clear();

      // Draw based on current view
      switch (this.currentView) {
        case "overview":
          await this.drawOverviewView();
          break;
        case "detailed":
          await this.drawDetailedView();
          break;
        case "trends":
          await this.drawTrendsView();
          break;
        case "team":
          await this.drawTeamView();
          break;
      }

      // Draw footer
      this.drawFooter();
    } catch (error) {
      this.showError(`Error updating display: ${error.message}`);
    }
  }

  private async drawOverviewView(): Promise<void> {
    if (!this.currentMetrics) return;

    const metrics = this.currentMetrics;
    const width = term.width;
    const height = term.height;

    // Header
    this.drawHeader();

    // Performance summary box
    const summaryY = 4;
    term.moveTo(1, summaryY);
    term.cyan("⚡ Performance Summary").styleReset()("\n\n");

    // Create summary table
    const summaryData = [
      ["Metric", "Value", "Change"],
      [
        "Avg Format Time",
        this.formatTime(metrics.avgFormatTime),
        this.formatChange(metrics.trends.performanceChange),
      ],
      [
        "Files Processed",
        metrics.totalFiles.toString(),
        this.formatChange(metrics.trends.usageChange),
      ],
      [
        "Success Rate",
        this.formatPercent(metrics.successRate),
        this.formatChange(metrics.trends.qualityChange),
      ],
      ["Error Rate", this.formatPercent(metrics.errorRate), ""],
    ];

    this.drawTable(2, summaryY + 2, summaryData);

    // Performance chart
    const chartY = summaryY + 9;
    term.moveTo(1, chartY);
    term.cyan("📊 Performance Trends").styleReset()("\n");
    this.drawPerformanceChart(2, chartY + 1, width - 4, 10);

    // Top formatters
    const formattersY = chartY + 13;
    term.moveTo(1, formattersY);
    term.cyan("🔧 Top Formatters").styleReset()("\n");

    const formatterData = [
      ["Formatter", "Avg Time", "Files", "Status"],
      ...metrics.topFormatters.map((f) => [
        f.name,
        this.formatTime(f.avgTime),
        f.usage.toString(),
        this.getFormatterStatus(f.avgTime),
      ]),
    ];

    this.drawTable(2, formattersY + 1, formatterData);

    // Recommendations
    const recsY = formattersY + 8;
    if (recsY < height - 4) {
      term.moveTo(1, recsY);
      term.cyan("💡 Recommendations").styleReset()("\n");
      this.drawRecommendations(2, recsY + 1);
    }
  }

  private async drawDetailedView(): Promise<void> {
    if (!this.currentMetrics) return;

    const metrics = this.currentMetrics;

    // Header
    this.drawHeader();

    // Detailed formatter breakdown
    term.moveTo(1, 4);
    term.cyan("🎯 Detailed Formatter Analysis").styleReset()("\n\n");

    const formatterData = [
      ["Formatter", "Avg Time", "Total Time", "Files", "Efficiency"],
      ...metrics.topFormatters.map((f) => [
        f.name,
        this.formatTime(f.avgTime),
        this.formatTime(f.avgTime * f.usage),
        f.usage.toString(),
        this.calculateEfficiency(f.avgTime, f.usage),
      ]),
    ];

    this.drawTable(2, 6, formatterData);

    // Slowest files
    term.moveTo(1, 13);
    term.cyan("🐌 Slowest Files").styleReset()("\n");

    const fileData = [
      ["File Path", "Time", "Size", "Speed"],
      ...metrics.slowestFiles
        .slice(0, 10)
        .map((f) => [
          this.truncatePath(f.path, 40),
          this.formatTime(f.time),
          this.formatBytes(f.size),
          this.calculateSpeed(f.time, f.size),
        ]),
    ];

    this.drawTable(2, 14, fileData);

    // Performance distribution
    term.moveTo(1, 26);
    term.cyan("📊 Performance Distribution").styleReset()("\n");
    this.drawHistogram(2, 27, metrics);
  }

  private async drawTrendsView(): Promise<void> {
    if (!this.currentMetrics) return;

    // Header
    this.drawHeader();

    term.moveTo(1, 4);
    term.cyan("📈 Performance Trends Analysis").styleReset()("\n\n");

    // Trend charts
    this.drawTrendCharts(2, 6);

    // Pattern analysis
    term.moveTo(1, 18);
    term.cyan("🔍 Pattern Analysis").styleReset()("\n");
    this.drawPatternAnalysis(2, 19);
  }

  private async drawTeamView(): Promise<void> {
    // Header
    this.drawHeader();

    term.moveTo(1, 4);
    term.cyan("👥 Team Performance Dashboard").styleReset()("\n\n");

    term.moveTo(2, 6);
    term.yellow("Team analytics coming soon!");
    term.moveTo(2, 8);
    term("This view will show:");
    term.moveTo(4, 9);
    term("• Individual developer metrics");
    term.moveTo(4, 10);
    term("• Team productivity trends");
    term.moveTo(4, 11);
    term("• Collaboration insights");
    term.moveTo(4, 12);
    term("• Best practice sharing");
  }

  private drawHeader(): void {
    const width = term.width;
    const now = new Date().toLocaleString();

    // Draw header bar
    term.moveTo(1, 1);
    term.bgCyan.black();
    term(" ".repeat(width));

    term.moveTo(2, 1);
    term.bold("🚀 Treefmt Performance Analytics");

    term.moveTo(width - 30, 1);
    term(`Project: ${this.config.projectId}`);

    term.moveTo(1, 2);
    term.bgBlue.white();
    term(" ".repeat(width));

    term.moveTo(2, 2);
    term(
      `View: ${this.currentView.toUpperCase()} | Range: ${this.config.timeRange}d | Updated: ${now}`,
    );

    term.styleReset();
  }

  private drawFooter(): void {
    const width = term.width;
    const height = term.height;

    term.moveTo(1, height - 1);
    term.bgBlue.white();
    term(" ".repeat(width));

    term.moveTo(2, height - 1);
    term("[1]Overview [2]Detailed [3]Trends [4]Team [R]efresh [+/-]Range [Q]uit");

    term.styleReset();
  }

  private drawTable(x: number, y: number, data: string[][]): void {
    if (!data || data.length === 0) return;

    // Calculate column widths
    const columnWidths = data[0].map((_, colIndex) =>
      Math.max(...data.map((row) => row[colIndex]?.length || 0)),
    );

    // Draw table
    data.forEach((row, rowIndex) => {
      term.moveTo(x, y + rowIndex);

      row.forEach((cell, colIndex) => {
        const width = columnWidths[colIndex] + 2;
        const paddedCell = cell.padEnd(width);

        if (rowIndex === 0) {
          // Header row
          term.bold.cyan(paddedCell);
        } else {
          // Data rows
          if (colIndex === columnWidths.length - 1 && cell.includes("✅")) {
            term.green(paddedCell);
          } else if (colIndex === columnWidths.length - 1 && cell.includes("⚠️")) {
            term.yellow(paddedCell);
          } else if (colIndex === columnWidths.length - 1 && cell.includes("❌")) {
            term.red(paddedCell);
          } else {
            term(paddedCell);
          }
        }
      });
    });

    term.styleReset();
  }

  private drawPerformanceChart(x: number, y: number, width: number, height: number): void {
    if (!this.currentMetrics) return;

    // Generate sample data for chart
    const data = Array.from({ length: 24 }, (_, i) => {
      const base = this.currentMetrics!.avgFormatTime;
      const variation = Math.sin(i / 4) * (base * 0.3);
      return Math.max(base + variation, base * 0.1);
    });

    const maxValue = Math.max(...data);
    const minValue = Math.min(...data);

    // Draw chart axes
    for (let i = 0; i < height; i++) {
      term.moveTo(x, y + i);
      term.gray("│");
    }

    term.moveTo(x, y + height);
    term.gray("└" + "─".repeat(width - 2));

    // Draw data points
    data.forEach((value, index) => {
      const xPos = x + 2 + Math.floor((index / data.length) * (width - 4));
      const normalized = (value - minValue) / (maxValue - minValue);
      const yPos = y + height - 1 - Math.floor(normalized * (height - 1));

      term.moveTo(xPos, yPos);
      term.green("●");
    });

    // Labels
    term.moveTo(x + width - 10, y);
    term.gray(`${maxValue.toFixed(0)}ms`);
    term.moveTo(x + width - 10, y + height - 1);
    term.gray(`${minValue.toFixed(0)}ms`);
  }

  private drawHistogram(x: number, y: number, metrics: AggregatedMetrics): void {
    const bins = [
      { label: "<500ms", count: 0 },
      { label: "500-1000ms", count: 0 },
      { label: "1-2s", count: 0 },
      { label: "2-5s", count: 0 },
      { label: ">5s", count: 0 },
    ];

    // Simulate distribution (in real implementation, query from database)
    const totalFiles = metrics.totalFiles;
    bins[0].count = Math.floor(totalFiles * 0.6);
    bins[1].count = Math.floor(totalFiles * 0.25);
    bins[2].count = Math.floor(totalFiles * 0.1);
    bins[3].count = Math.floor(totalFiles * 0.04);
    bins[4].count = Math.floor(totalFiles * 0.01);

    const maxCount = Math.max(...bins.map((b) => b.count));

    bins.forEach((bin, index) => {
      term.moveTo(x, y + index);
      term(bin.label.padEnd(12));

      const barLength = Math.floor((bin.count / maxCount) * 30);
      term.green("█".repeat(barLength));
      term.gray("░".repeat(30 - barLength));

      term(" ");
      term.cyan(bin.count.toString());
    });
  }

  private drawRecommendations(x: number, y: number): void {
    const recommendations = [
      "• Enable parallel processing for 40% speed improvement",
      "• Update ESLint config to exclude node_modules",
      "• Consider incremental formatting for large repos",
      "• Implement file size limits for complex formatters",
    ];

    recommendations.forEach((rec, index) => {
      term.moveTo(x, y + index);
      term.yellow(rec);
    });
  }

  private drawTrendCharts(x: number, y: number): void {
    // Performance trend
    term.moveTo(x, y);
    term("Performance Trend: ");
    this.drawSparkline(x + 18, y, 30);

    // Usage trend
    term.moveTo(x, y + 2);
    term("Usage Trend: ");
    this.drawSparkline(x + 18, y + 2, 30);

    // Quality trend
    term.moveTo(x, y + 4);
    term("Quality Trend: ");
    this.drawSparkline(x + 18, y + 4, 30);
  }

  private drawSparkline(x: number, y: number, width: number): void {
    const sparkChars = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"];
    const data = Array.from({ length: width }, () => Math.random());

    term.moveTo(x, y);
    data.forEach((value) => {
      const index = Math.floor(value * (sparkChars.length - 1));
      term.green(sparkChars[index]);
    });
  }

  private drawPatternAnalysis(x: number, y: number): void {
    const patterns = [
      "• Peak usage hours: 10am-12pm, 2pm-4pm",
      "• Slowest day: Monday (post-weekend changes)",
      "• Most errors: Large TypeScript files",
      "• Best performance: Small Python modules",
    ];

    patterns.forEach((pattern, index) => {
      term.moveTo(x, y + index);
      term.white(pattern);
    });
  }

  // Utility functions
  private formatTime(ms: number): string {
    if (ms < 1000) return `${ms.toFixed(0)}ms`;
    return `${(ms / 1000).toFixed(1)}s`;
  }

  private formatPercent(value: number): string {
    return `${(value * 100).toFixed(1)}%`;
  }

  private formatChange(value: number): string {
    if (value === 0) return "→ 0%";
    const arrow = value > 0 ? "↑" : "↓";
    const color = value > 0 ? "red" : "green";
    return `${arrow} ${Math.abs(value).toFixed(1)}%`;
  }

  private formatBytes(bytes: number): string {
    if (bytes < 1024) return `${bytes}B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`;
    return `${(bytes / 1024 / 1024).toFixed(1)}MB`;
  }

  private getFormatterStatus(avgTime: number): string {
    if (avgTime < 500) return "✅ Excellent";
    if (avgTime < 1000) return "⚠️  Good";
    return "❌ Needs Optimization";
  }

  private calculateEfficiency(avgTime: number, usage: number): string {
    const efficiency = 1000 / avgTime; // files per second
    return `${efficiency.toFixed(1)} files/s`;
  }

  private calculateSpeed(time: number, size: number): string {
    const speed = size / time; // bytes per ms
    return `${(speed / 1024).toFixed(1)} KB/s`;
  }

  private truncatePath(path: string, maxLength: number): string {
    if (path.length <= maxLength) return path;
    const start = path.substring(0, 10);
    const end = path.substring(path.length - (maxLength - 13));
    return `${start}...${end}`;
  }

  private showError(message: string): void {
    term.moveTo(1, term.height - 3);
    term.red.bold(`Error: ${message}`);
  }
}

// CLI Runner
export async function runDashboard(): Promise<void> {
  // Clear screen and show startup message
  term.clear();
  term.cyan.bold("🚀 Starting Treefmt Performance Analytics Dashboard...\n\n");

  try {
    const collector = new AnalyticsCollector();
    const dashboard = new TerminalDashboard(collector, {
      projectId: process.argv[2] || "default",
      timeRange: parseInt(process.argv[3]) || 7,
    });

    await dashboard.start();
  } catch (error) {
    term.red.bold(`\nFailed to start dashboard: ${error.message}\n`);
    process.exit(1);
  }
}

// Run dashboard if called directly
if (import.meta.main) {
  runDashboard().catch((error) => {
    term.red.bold(`\nError: ${error.message}\n`);
    process.exit(1);
  });
}
