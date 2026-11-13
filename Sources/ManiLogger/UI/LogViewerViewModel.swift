//
//  LogViewerViewModel.swift
//  ManiLogger
//

import Foundation
import Observation

/// How far back the log viewer looks.
public enum LogTimeRange: CaseIterable, Sendable {
    case last5m, last15m, last1h, all

    public var title: String {
        switch self {
        case .last5m: return "5 min"
        case .last15m: return "15 min"
        case .last1h: return "1 hour"
        case .all: return "All"
        }
    }

    public var interval: TimeInterval? {
        switch self {
        case .last5m: return 5 * 60
        case .last15m: return 15 * 60
        case .last1h: return 60 * 60
        case .all: return nil
        }
    }
}

/// State for `LogViewerView`: entries from a `LogBuffer` plus level/category/time/search filters.
@MainActor @Observable
public final class LogViewerViewModel {
    private let logBuffer: LogBuffer
    private let fileLogSink: FileLogSink?
    private let now: () -> Date

    public init(logBuffer: LogBuffer, fileLogSink: FileLogSink? = nil, now: @escaping () -> Date = Date.init) {
        self.logBuffer = logBuffer
        self.fileLogSink = fileLogSink
        self.now = now
        self.logEntries = logBuffer.entries
    }

    /// Everything in the in-memory buffer, oldest first.
    public private(set) var logEntries: [LogEntry]
    /// Minimum level shown.
    public var logLevelFilter: LogLevel = .debug
    public var logSearchText = ""
    /// Categories shown; empty means all.
    public private(set) var selectedLogCategories: Set<LogCategory> = []
    public var logTimeRange: LogTimeRange = .all

    public var logSearchQuery: String { logSearchText.trimmingCharacters(in: .whitespaces) }

    public var hasActiveLogFilters: Bool {
        logLevelFilter != .debug || !selectedLogCategories.isEmpty || logTimeRange != .all || !logSearchQuery.isEmpty
    }

    /// Entries after level, category, time and search filtering, newest first.
    public var filteredLogEntries: [LogEntry] {
        entriesMatchingNonCategoryFilters.filter { selectedLogCategories.isEmpty || selectedLogCategories.contains($0.category) }
    }

    /// Per-category counts under the level/time/search filters (ignoring the category selection),
    /// so each option shows what selecting it would reveal.
    public var logCategoryCounts: [LogCategory: Int] {
        Dictionary(grouping: entriesMatchingNonCategoryFilters, by: \.category).mapValues(\.count)
    }

    /// Categories with matching entries plus any selected ones (so they can be deselected), sorted.
    public var visibleLogCategories: [LogCategory] {
        Set(logCategoryCounts.keys).union(selectedLogCategories).sorted()
    }

    /// "12 of 340"
    public var logResultSummary: String {
        "\(filteredLogEntries.count) of \(logEntries.count)"
    }

    /// Full on-disk log (both rotated files) when available, else the in-memory buffer.
    public var logText: String {
        let fileText = fileLogSink?.contents() ?? ""
        return fileText.isEmpty ? logBuffer.shareableText : fileText
    }

    public func reloadLogs() {
        logEntries = logBuffer.entries
    }

    public func clearLogs() {
        logBuffer.clear()
        fileLogSink?.clear()
        reloadLogs()
    }

    public func toggleLogCategory(_ category: LogCategory) {
        if selectedLogCategories.contains(category) {
            selectedLogCategories.remove(category)
        } else {
            selectedLogCategories.insert(category)
        }
    }

    public func clearLogCategories() {
        selectedLogCategories = []
    }

    public func resetLogFilters() {
        logLevelFilter = .debug
        selectedLogCategories = []
        logTimeRange = .all
        logSearchText = ""
    }

    private var entriesMatchingNonCategoryFilters: [LogEntry] {
        let query = logSearchQuery
        let cutoff = logTimeRange.interval.map { now().addingTimeInterval(-$0) }
        return logEntries.reversed().filter { entry in
            entry.level >= logLevelFilter
                && (cutoff.map { entry.date >= $0 } ?? true)
                && (query.isEmpty
                    || entry.message.localizedCaseInsensitiveContains(query)
                    || entry.category.rawValue.localizedCaseInsensitiveContains(query))
        }
    }
}
