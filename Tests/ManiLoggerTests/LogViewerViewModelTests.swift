//
//  LogViewerViewModelTests.swift
//  ManiLogger
//

import Foundation
import Testing
@testable import ManiLogger

@MainActor
struct LogViewerViewModelTests {
    private func entry(_ message: String, level: LogLevel = .info, category: LogCategory = .app,
                       date: Date = Date()) -> LogEntry {
        LogEntry(date: date, level: level, category: category, message: message, sessionId: "s")
    }

    @Test func levelAndSearchFilterNewestFirst() {
        let buffer = LogBuffer()
        buffer.write(entry("pull started", level: .debug, category: .sync))
        buffer.write(entry("pull failed", level: .error, category: .sync))
        buffer.write(entry("token expired", level: .error, category: .auth))
        let viewModel = LogViewerViewModel(logBuffer: buffer)

        viewModel.logLevelFilter = .warning
        #expect(viewModel.filteredLogEntries.map(\.message) == ["token expired", "pull failed"])

        viewModel.logSearchText = "sync"
        #expect(viewModel.filteredLogEntries.map(\.message) == ["pull failed"])
    }

    @Test func clearLogsEmptiesBufferAndEntries() {
        let buffer = LogBuffer()
        buffer.write(entry("x"))
        let viewModel = LogViewerViewModel(logBuffer: buffer)

        viewModel.clearLogs()
        #expect(viewModel.logEntries.isEmpty)
        #expect(buffer.entries.isEmpty)
    }

    @Test func categoryFilterEmptyMeansAllAndSupportsMultipleSelection() {
        let buffer = LogBuffer()
        buffer.write(entry("a", category: .sync))
        buffer.write(entry("b", category: .auth))
        buffer.write(entry("c", category: .ui))
        let viewModel = LogViewerViewModel(logBuffer: buffer)

        #expect(viewModel.filteredLogEntries.count == 3)
        viewModel.toggleLogCategory(.sync)
        #expect(viewModel.filteredLogEntries.map(\.message) == ["a"])
        viewModel.toggleLogCategory(.auth)
        #expect(viewModel.filteredLogEntries.map(\.message) == ["b", "a"])
        viewModel.toggleLogCategory(.sync)
        #expect(viewModel.filteredLogEntries.map(\.message) == ["b"])
        viewModel.clearLogCategories()
        #expect(viewModel.filteredLogEntries.count == 3)
    }

    @Test func timeRangeKeepsOnlyRecentEntries() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let buffer = LogBuffer()
        buffer.write(entry("2h", date: now.addingTimeInterval(-7_200)))
        buffer.write(entry("10m", date: now.addingTimeInterval(-600)))
        buffer.write(entry("2m", date: now.addingTimeInterval(-120)))
        let viewModel = LogViewerViewModel(logBuffer: buffer, now: { now })

        viewModel.logTimeRange = .last5m
        #expect(viewModel.filteredLogEntries.map(\.message) == ["2m"])
        viewModel.logTimeRange = .last15m
        #expect(viewModel.filteredLogEntries.map(\.message) == ["2m", "10m"])
        viewModel.logTimeRange = .all
        #expect(viewModel.filteredLogEntries.count == 3)
    }

    @Test func categoryCountsIgnoreCategorySelectionButRespectOtherFilters() {
        let buffer = LogBuffer()
        buffer.write(entry("pull ok", category: .sync))
        buffer.write(entry("pull failed", level: .error, category: .sync))
        buffer.write(entry("login failed", level: .error, category: .auth))
        let viewModel = LogViewerViewModel(logBuffer: buffer)

        viewModel.toggleLogCategory(.auth)
        #expect(viewModel.logCategoryCounts == [.sync: 2, .auth: 1])
        viewModel.logLevelFilter = .error
        viewModel.logSearchText = "pull"
        #expect(viewModel.logCategoryCounts == [.sync: 1])
        #expect(viewModel.visibleLogCategories == [.auth, .sync])
        #expect(viewModel.filteredLogEntries.isEmpty)
    }

    @Test func resultSummaryAndResetFilters() {
        let buffer = LogBuffer()
        buffer.write(entry("x", category: .sync))
        buffer.write(entry("y", category: .ui))
        let viewModel = LogViewerViewModel(logBuffer: buffer)

        #expect(viewModel.hasActiveLogFilters == false)
        viewModel.toggleLogCategory(.sync)
        viewModel.logTimeRange = .last1h
        #expect(viewModel.logResultSummary == "1 of 2")
        #expect(viewModel.hasActiveLogFilters)

        viewModel.resetLogFilters()
        #expect(viewModel.logResultSummary == "2 of 2")
        #expect(viewModel.hasActiveLogFilters == false)
    }
}
