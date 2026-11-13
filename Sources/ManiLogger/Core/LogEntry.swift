//
//  LogEntry.swift
//  ManiLogger
//

import Foundation

public enum LogLevel: Int, Sendable, CaseIterable, Comparable, Codable {
    case debug, info, warning, error

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    public var label: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        }
    }
}

/// Open set of log categories (also the `os.Logger` category). Apps add their own with
/// `extension LogCategory { static let billing: LogCategory = "billing" }`.
public struct LogCategory: RawRepresentable, Hashable, Comparable, Codable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    public static func < (lhs: LogCategory, rhs: LogCategory) -> Bool { lhs.rawValue < rhs.rawValue }

    public static let app: LogCategory = "app"
    public static let ui: LogCategory = "ui"
    public static let network: LogCategory = "network"
    public static let storage: LogCategory = "storage"
    public static let sync: LogCategory = "sync"
    public static let auth: LogCategory = "auth"
    public static let config: LogCategory = "config"
    public static let analytics: LogCategory = "analytics"
}

public struct LogEntry: Sendable, Equatable, Codable {
    public let date: Date
    public let level: LogLevel
    public let category: LogCategory
    public let message: String
    /// Per-launch id, so lines from one session can be correlated with analytics/crash reports.
    public let sessionId: String

    public init(date: Date = Date(), level: LogLevel, category: LogCategory, message: String, sessionId: String) {
        self.date = date
        self.level = level
        self.category = category
        self.message = message
        self.sessionId = sessionId
    }

    /// `2026-11-13T10:00:00.000Z ERROR [sync] message`
    public var formatted: String {
        "\(date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: true))) \(level.label) [\(category.rawValue)] \(message)"
    }
}

/// Destination for log entries (in-memory buffer, file, crash reporter, …).
public protocol LogSink: Sendable {
    func write(_ entry: LogEntry)
}
