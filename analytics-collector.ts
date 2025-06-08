#!/usr/bin/env bun
/**
 * Performance Analytics Collector for treefmt
 * Collects, stores, and analyzes code formatting performance data
 */

import { Database } from "bun:sqlite";
import { createHash } from "crypto";
import { existsSync, mkdirSync, statSync } from "fs";
import { join } from "path";

// Types and Interfaces
interface PerformanceTelemetry {
  timestamp: Date;
  sessionId: string;
  userId?: string;
  projectId: string;
  
  // Performance Metrics
  formatTime: number;
  fileCount: number;
  totalLines: number;
  memoryUsage: number;
  cpuUsage: number;
  
  // Formatter Details
  formatters: FormatterMetrics[];
  
  // File Information
  files: FileMetrics[];
  
  // Environment
  environment: EnvironmentInfo;
  
  // Errors & Warnings
  errors: ErrorMetrics[];
  warnings: WarningMetrics[];
}

interface FormatterMetrics {
  name: string;
  version: string;
  executionTime: number;
  filesProcessed: number;
  linesProcessed: number;
  changes: number;
  errors: number;
}

interface FileMetrics {
  path: string;
  size: number;
  language: string;
  formatter: string;
  processingTime: number;
  changesCount: number;
  beforeChecksum: string;
  afterChecksum: string;
}

interface EnvironmentInfo {
  os: string;
  arch: string;
  nodeVersion: string;
  treefmtVersion: string;
  gitBranch?: string;
  gitCommit?: string;
  ciEnvironment?: string;
}

interface ErrorMetrics {
  formatter: string;
  file: string;
  errorType: string;
  message: string;
  stack?: string;
}

interface WarningMetrics {
  formatter: string;
  file: string;
  warningType: string;
  message: string;
}

interface PrivacyConfig {
  collectPersonalData: boolean;
  anonymizeUserIds: boolean;
  encryptLocalStorage: boolean;
  shareWithTeam: 'none' | 'aggregated' | 'full';
  retentionPeriod: number; // days
}

interface AggregatedMetrics {
  avgFormatTime: number;
  medianFormatTime: number;
  p95FormatTime: number;
  totalFiles: number;
  successRate: number;
  errorRate: number;
  topFormatters: Array<{ name: string; usage: number; avgTime: number }>;
  slowestFiles: Array<{ path: string; time: number; size: number }>;
  trends: {
    performanceChange: number; // percentage change
    qualityChange: number;
    usageChange: number;
  };
}

// Main Analytics Collector Class
export class AnalyticsCollector {
  private db: Database;
  private config: PrivacyConfig;
  private dataDir: string;

  constructor(dataDir: string = "./.treefmt-analytics", config?: Partial<PrivacyConfig>) {
    this.dataDir = dataDir;
    this.config = {
      collectPersonalData: false,
      anonymizeUserIds: true,
      encryptLocalStorage: true,
      shareWithTeam: 'aggregated',
      retentionPeriod: 30,
      ...config
    };

    this.initializeStorage();
    this.db = new Database(join(this.dataDir, "analytics.db"));
    this.setupDatabase();
  }

  private initializeStorage(): void {
    if (!existsSync(this.dataDir)) {
      mkdirSync(this.dataDir, { recursive: true });
    }
  }

  private setupDatabase(): void {
    // Performance Sessions Table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS performance_sessions (
        id TEXT PRIMARY KEY,
        timestamp DATETIME NOT NULL,
        user_id TEXT,
        project_id TEXT NOT NULL,
        total_time_ms INTEGER NOT NULL,
        file_count INTEGER NOT NULL,
        total_lines INTEGER NOT NULL,
        memory_mb REAL,
        cpu_percent REAL,
        success_rate REAL,
        error_count INTEGER,
        warning_count INTEGER
      )
    `);

    // Formatter Performance Table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS formatter_performance (
        session_id TEXT,
        formatter_name TEXT NOT NULL,
        formatter_version TEXT,
        execution_time_ms INTEGER NOT NULL,
        files_processed INTEGER NOT NULL,
        lines_processed INTEGER NOT NULL,
        changes_made INTEGER NOT NULL,
        error_count INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES performance_sessions(id)
      )
    `);

    // File Performance Table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS file_performance (
        session_id TEXT,
        file_path TEXT NOT NULL,
        file_size_bytes INTEGER NOT NULL,
        language TEXT NOT NULL,
        formatter TEXT NOT NULL,
        processing_time_ms INTEGER NOT NULL,
        changes_count INTEGER NOT NULL,
        before_checksum TEXT,
        after_checksum TEXT,
        FOREIGN KEY (session_id) REFERENCES performance_sessions(id)
      )
    `);

    // Errors Table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS errors (
        session_id TEXT,
        formatter TEXT NOT NULL,
        file_path TEXT NOT NULL,
        error_type TEXT NOT NULL,
        message TEXT NOT NULL,
        stack TEXT,
        timestamp DATETIME NOT NULL,
        FOREIGN KEY (session_id) REFERENCES performance_sessions(id)
      )
    `);

    // Create indexes for performance
    this.db.exec(`CREATE INDEX IF NOT EXISTS idx_sessions_timestamp ON performance_sessions(timestamp)`);
    this.db.exec(`CREATE INDEX IF NOT EXISTS idx_sessions_project ON performance_sessions(project_id)`);
    this.db.exec(`CREATE INDEX IF NOT EXISTS idx_formatter_name ON formatter_performance(formatter_name)`);
    this.db.exec(`CREATE INDEX IF NOT EXISTS idx_file_language ON file_performance(language)`);
  }

  async collectTelemetry(telemetry: PerformanceTelemetry): Promise<void> {
    // Apply privacy controls
    const sanitizedTelemetry = this.applyPrivacyControls(telemetry);

    // Store session data
    const sessionStmt = this.db.prepare(`
      INSERT INTO performance_sessions (
        id, timestamp, user_id, project_id, total_time_ms, file_count, 
        total_lines, memory_mb, cpu_percent, success_rate, error_count, warning_count
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    const successRate = (sanitizedTelemetry.fileCount - sanitizedTelemetry.errors.length) / sanitizedTelemetry.fileCount;

    sessionStmt.run(
      sanitizedTelemetry.sessionId,
      sanitizedTelemetry.timestamp.toISOString(),
      sanitizedTelemetry.userId,
      sanitizedTelemetry.projectId,
      sanitizedTelemetry.formatTime,
      sanitizedTelemetry.fileCount,
      sanitizedTelemetry.totalLines,
      sanitizedTelemetry.memoryUsage,
      sanitizedTelemetry.cpuUsage,
      successRate,
      sanitizedTelemetry.errors.length,
      sanitizedTelemetry.warnings.length
    );

    // Store formatter performance
    const formatterStmt = this.db.prepare(`
      INSERT INTO formatter_performance (
        session_id, formatter_name, formatter_version, execution_time_ms,
        files_processed, lines_processed, changes_made, error_count
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `);

    for (const formatter of sanitizedTelemetry.formatters) {
      formatterStmt.run(
        sanitizedTelemetry.sessionId,
        formatter.name,
        formatter.version,
        formatter.executionTime,
        formatter.filesProcessed,
        formatter.linesProcessed,
        formatter.changes,
        formatter.errors
      );
    }

    // Store file performance
    const fileStmt = this.db.prepare(`
      INSERT INTO file_performance (
        session_id, file_path, file_size_bytes, language, formatter,
        processing_time_ms, changes_count, before_checksum, after_checksum
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    for (const file of sanitizedTelemetry.files) {
      fileStmt.run(
        sanitizedTelemetry.sessionId,
        file.path,
        file.size,
        file.language,
        file.formatter,
        file.processingTime,
        file.changesCount,
        file.beforeChecksum,
        file.afterChecksum
      );
    }

    // Store errors
    const errorStmt = this.db.prepare(`
      INSERT INTO errors (
        session_id, formatter, file_path, error_type, message, stack, timestamp
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    for (const error of sanitizedTelemetry.errors) {
      errorStmt.run(
        sanitizedTelemetry.sessionId,
        error.formatter,
        error.file,
        error.errorType,
        error.message,
        error.stack,
        sanitizedTelemetry.timestamp.toISOString()
      );
    }

    // Clean up old data based on retention policy
    await this.cleanupOldData();
  }

  getAggregatedMetrics(projectId: string, days: number = 7): AggregatedMetrics {
    const since = new Date();
    since.setDate(since.getDate() - days);

    // Get basic performance metrics
    const perfQuery = this.db.prepare(`
      SELECT 
        AVG(total_time_ms) as avg_time,
        COUNT(*) as session_count,
        SUM(file_count) as total_files,
        AVG(success_rate) as avg_success_rate,
        AVG(error_count) as avg_errors
      FROM performance_sessions 
      WHERE project_id = ? AND timestamp > ?
    `);

    const perfResult = perfQuery.get(projectId, since.toISOString()) as any;

    // Get percentiles
    const percentileQuery = this.db.prepare(`
      SELECT total_time_ms 
      FROM performance_sessions 
      WHERE project_id = ? AND timestamp > ?
      ORDER BY total_time_ms
    `);

    const times = percentileQuery.all(projectId, since.toISOString()) as any[];
    const sortedTimes = times.map(t => t.total_time_ms).sort((a, b) => a - b);
    
    const p95Index = Math.floor(sortedTimes.length * 0.95);
    const medianIndex = Math.floor(sortedTimes.length * 0.5);

    // Get top formatters
    const formattersQuery = this.db.prepare(`
      SELECT 
        formatter_name,
        COUNT(*) as usage_count,
        AVG(execution_time_ms) as avg_time
      FROM formatter_performance fp
      JOIN performance_sessions ps ON fp.session_id = ps.id
      WHERE ps.project_id = ? AND ps.timestamp > ?
      GROUP BY formatter_name
      ORDER BY usage_count DESC
      LIMIT 5
    `);

    const topFormatters = formattersQuery.all(projectId, since.toISOString()) as any[];

    // Get slowest files
    const slowFilesQuery = this.db.prepare(`
      SELECT 
        file_path,
        AVG(processing_time_ms) as avg_time,
        MAX(file_size_bytes) as size
      FROM file_performance fp
      JOIN performance_sessions ps ON fp.session_id = ps.id
      WHERE ps.project_id = ? AND ps.timestamp > ?
      GROUP BY file_path
      ORDER BY avg_time DESC
      LIMIT 10
    `);

    const slowestFiles = slowFilesQuery.all(projectId, since.toISOString()) as any[];

    // Calculate trends (compare with previous period)
    const previousSince = new Date(since);
    previousSince.setDate(previousSince.getDate() - days);

    const prevPerfQuery = this.db.prepare(`
      SELECT AVG(total_time_ms) as avg_time
      FROM performance_sessions 
      WHERE project_id = ? AND timestamp BETWEEN ? AND ?
    `);

    const prevResult = prevPerfQuery.get(projectId, previousSince.toISOString(), since.toISOString()) as any;
    const performanceChange = prevResult?.avg_time ? 
      ((perfResult.avg_time - prevResult.avg_time) / prevResult.avg_time) * 100 : 0;

    return {
      avgFormatTime: perfResult.avg_time || 0,
      medianFormatTime: sortedTimes[medianIndex] || 0,
      p95FormatTime: sortedTimes[p95Index] || 0,
      totalFiles: perfResult.total_files || 0,
      successRate: perfResult.avg_success_rate || 0,
      errorRate: (perfResult.avg_errors || 0) / (perfResult.total_files || 1),
      topFormatters: topFormatters.map(f => ({
        name: f.formatter_name,
        usage: f.usage_count,
        avgTime: f.avg_time
      })),
      slowestFiles: slowestFiles.map(f => ({
        path: f.file_path,
        time: f.avg_time,
        size: f.size
      })),
      trends: {
        performanceChange,
        qualityChange: 0, // TODO: Calculate quality trends
        usageChange: 0    // TODO: Calculate usage trends
      }
    };
  }

  private applyPrivacyControls(telemetry: PerformanceTelemetry): PerformanceTelemetry {
    const sanitized = { ...telemetry };

    if (!this.config.collectPersonalData) {
      sanitized.userId = undefined;
    }

    if (this.config.anonymizeUserIds && sanitized.userId) {
      sanitized.userId = this.hashString(sanitized.userId);
    }

    // Anonymize file paths if needed
    if (!this.config.collectPersonalData) {
      sanitized.files = sanitized.files.map(file => ({
        ...file,
        path: this.anonymizePath(file.path)
      }));

      sanitized.errors = sanitized.errors.map(error => ({
        ...error,
        file: this.anonymizePath(error.file),
        stack: undefined // Remove stack traces for privacy
      }));
    }

    return sanitized;
  }

  private hashString(input: string): string {
    return createHash('sha256').update(input).digest('hex').substring(0, 16);
  }

  private anonymizePath(path: string): string {
    // Replace directory names with hashes but keep file extensions
    const parts = path.split('/');
    return parts.map((part, index) => {
      if (index === parts.length - 1) {
        // Last part (filename) - keep extension
        const [name, ...extensions] = part.split('.');
        if (extensions.length > 0) {
          return `file_${this.hashString(name).substring(0, 8)}.${extensions.join('.')}`;
        }
        return `file_${this.hashString(part).substring(0, 8)}`;
      }
      return index === 0 ? part : `dir_${this.hashString(part).substring(0, 4)}`;
    }).join('/');
  }

  private async cleanupOldData(): Promise<void> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - this.config.retentionPeriod);

    const deleteStmt = this.db.prepare(`
      DELETE FROM performance_sessions 
      WHERE timestamp < ?
    `);

    deleteStmt.run(cutoffDate.toISOString());
  }

  exportData(projectId: string, format: 'json' | 'csv' = 'json', days: number = 30): string {
    const since = new Date();
    since.setDate(since.getDate() - days);

    const query = this.db.prepare(`
      SELECT 
        ps.*,
        fp.formatter_name,
        fp.execution_time_ms as formatter_time,
        fp.files_processed as formatter_files
      FROM performance_sessions ps
      LEFT JOIN formatter_performance fp ON ps.id = fp.session_id
      WHERE ps.project_id = ? AND ps.timestamp > ?
      ORDER BY ps.timestamp DESC
    `);

    const data = query.all(projectId, since.toISOString());

    if (format === 'json') {
      return JSON.stringify(data, null, 2);
    } else {
      // CSV format
      if (data.length === 0) return '';
      
      const headers = Object.keys(data[0]);
      const csvRows = [
        headers.join(','),
        ...data.map(row => 
          headers.map(header => 
            JSON.stringify(row[header] ?? '')
          ).join(',')
        )
      ];
      
      return csvRows.join('\n');
    }
  }

  close(): void {
    this.db.close();
  }
}

// Utility function to detect file language
export function detectLanguage(filePath: string): string {
  const extension = filePath.split('.').pop()?.toLowerCase();
  
  const languageMap: Record<string, string> = {
    'js': 'javascript',
    'jsx': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescript',
    'py': 'python',
    'rs': 'rust',
    'go': 'go',
    'java': 'java',
    'cpp': 'cpp',
    'c': 'c',
    'css': 'css',
    'scss': 'scss',
    'html': 'html',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'md': 'markdown',
    'nix': 'nix'
  };

  return languageMap[extension || ''] || 'unknown';
}

// Performance monitor wrapper
export class PerformanceMonitor {
  private startTime: number;
  private sessionId: string;
  private collector: AnalyticsCollector;
  private telemetry: Partial<PerformanceTelemetry>;

  constructor(collector: AnalyticsCollector, projectId: string) {
    this.collector = collector;
    this.sessionId = crypto.randomUUID();
    this.startTime = performance.now();
    
    this.telemetry = {
      sessionId: this.sessionId,
      projectId,
      timestamp: new Date(),
      formatters: [],
      files: [],
      errors: [],
      warnings: []
    };
  }

  addFileMetrics(metrics: FileMetrics): void {
    this.telemetry.files?.push(metrics);
  }

  addFormatterMetrics(metrics: FormatterMetrics): void {
    this.telemetry.formatters?.push(metrics);
  }

  addError(error: ErrorMetrics): void {
    this.telemetry.errors?.push(error);
  }

  addWarning(warning: WarningMetrics): void {
    this.telemetry.warnings?.push(warning);
  }

  async finalize(): Promise<void> {
    const endTime = performance.now();
    
    this.telemetry.formatTime = endTime - this.startTime;
    this.telemetry.fileCount = this.telemetry.files?.length || 0;
    this.telemetry.totalLines = this.telemetry.files?.reduce((sum, f) => sum + (f.size / 50), 0) || 0; // Rough estimate
    
    // Get system metrics
    this.telemetry.memoryUsage = process.memoryUsage().heapUsed / 1024 / 1024; // MB
    this.telemetry.cpuUsage = process.cpuUsage().user / 1000; // ms
    
    // Environment info
    this.telemetry.environment = {
      os: process.platform,
      arch: process.arch,
      nodeVersion: process.version,
      treefmtVersion: '1.0.0' // TODO: Get actual version
    };

    await this.collector.collectTelemetry(this.telemetry as PerformanceTelemetry);
  }
}

// CLI interface for analytics
export async function runAnalyticsCLI(): Promise<void> {
  const args = process.argv.slice(2);
  const command = args[0];
  
  const collector = new AnalyticsCollector();
  
  try {
    switch (command) {
      case 'summary':
        const projectId = args[1] || 'default';
        const days = parseInt(args[2]) || 7;
        const metrics = collector.getAggregatedMetrics(projectId, days);
        
        console.log('📊 Treefmt Performance Summary\n');
        console.log(`Average Format Time: ${metrics.avgFormatTime.toFixed(0)}ms`);
        console.log(`Success Rate: ${(metrics.successRate * 100).toFixed(1)}%`);
        console.log(`Total Files: ${metrics.totalFiles}`);
        console.log(`Performance Change: ${metrics.trends.performanceChange.toFixed(1)}%`);
        
        if (metrics.topFormatters.length > 0) {
          console.log('\nTop Formatters:');
          metrics.topFormatters.forEach(f => {
            console.log(`  ${f.name}: ${f.usage} uses, ${f.avgTime.toFixed(0)}ms avg`);
          });
        }
        break;
        
      case 'export':
        const exportProjectId = args[1] || 'default';
        const format = (args[2] as 'json' | 'csv') || 'json';
        const exportDays = parseInt(args[3]) || 30;
        
        const exportData = collector.exportData(exportProjectId, format, exportDays);
        console.log(exportData);
        break;
        
      default:
        console.log('Usage: analytics-collector [summary|export] [projectId] [days]');
    }
  } finally {
    collector.close();
  }
}

// Run CLI if called directly
if (import.meta.main) {
  runAnalyticsCLI().catch(console.error);
}