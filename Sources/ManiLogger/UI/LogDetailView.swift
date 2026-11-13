//
//  LogDetailView.swift
//  ManiLogger
//

import SwiftUI
import ManiSwiftUIComponents

/// Full view of one log entry, opened from a (line-capped) row in `LogViewerView`.
public struct LogDetailView: View {
    @Environment(\.maniTheme) private var theme
    let entry: LogEntry
    let searchQuery: String

    public init(entry: LogEntry, searchQuery: String = "") {
        self.entry = entry
        self.searchQuery = searchQuery
    }

    public var body: some View {
        List {
            Section("Details") {
                ManiListRow(title: "Time", value: entry.date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: true)))
                HStack {
                    Text("Level")
                    Spacer()
                    Text(entry.level.label)
                        .font(.body.monospaced())
                        .foregroundStyle(LogEntryStyle.color(for: entry.level))
                }
                ManiListRow(title: "Category", value: entry.category.rawValue)
                ManiListRow(title: "Session", value: entry.sessionId)
            }
            Section("Message") {
                Text(LogEntryStyle.highlighted(entry.message, query: searchQuery, accent: theme.accent.accent))
                    .font(.caption.monospaced())
                    .foregroundStyle(theme.base.text)
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Log detail")
        .toolbar {
            // The share sheet also offers Copy; no UIKit pasteboard, to stay Skip-portable.
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: entry.formatted)
            }
        }
    }
}

/// Styling shared by the log list rows and the detail screen.
public enum LogEntryStyle {
    public static func color(for level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }

    /// Bolds and tints every case-insensitive occurrence of `query`.
    public static func highlighted(_ message: String, query: String, accent: Color) -> AttributedString {
        var attributed = AttributedString(message)
        guard !query.isEmpty else { return attributed }
        var searchStart = attributed.startIndex
        while searchStart < attributed.endIndex,
              let range = attributed[searchStart...].range(of: query, options: .caseInsensitive) {
            attributed[range].font = .caption.monospaced().bold()
            attributed[range].backgroundColor = accent.opacity(0.25)
            searchStart = range.upperBound
        }
        return attributed
    }
}
