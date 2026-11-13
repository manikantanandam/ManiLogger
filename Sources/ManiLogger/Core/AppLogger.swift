//
//  AppLogger.swift
//  ManiLogger
//

import Foundation
import os

/// Process-wide sink registry. Logging is cross-cutting (like `os.Logger`), so call sites use a
/// static/file-scope `AppLogger` instead of injection; the app's composition root builds and
/// registers the sinks once at launch.
public final class LogSinks: @unchecked Sendable {
    public static let shared = LogSinks()

    private let lock = NSLock()
    private var sinks: [LogSink] = []
    private var _minimumLevel: LogLevel = .debug

    /// Unique per launch; stamped on every entry.
    public let sessionId = UUID().uuidString

    public init() {}

    public var minimumLevel: LogLevel {
        get { lock.lock(); defer { lock.unlock() }; return _minimumLevel }
        set { lock.lock(); defer { lock.unlock() }; _minimumLevel = newValue }
    }

    public func configure(sinks: [LogSink], minimumLevel: LogLevel) {
        lock.lock(); defer { lock.unlock() }
        self.sinks = sinks
        self._minimumLevel = minimumLevel
    }

    public func add(_ sink: LogSink) {
        lock.lock(); defer { lock.unlock() }
        sinks.append(sink)
    }

    func dispatch(_ entry: LogEntry) {
        lock.lock()
        let current = sinks
        let minimum = _minimumLevel
        lock.unlock()
        guard entry.level >= minimum else { return }
        current.forEach { $0.write(entry) }
    }
}

/// Logs to the Xcode console via `os.Logger` and fans out to the registered `LogSinks`.
/// Callers must not log PII (names, phone numbers, emails, amounts) — log ids/counts.
public struct AppLogger: Sendable {
    public let category: LogCategory
    private let osLogger: Logger
    private let registry: LogSinks

    public init(category: LogCategory,
                subsystem: String = Bundle.main.bundleIdentifier ?? "ManiLogger",
                registry: LogSinks = .shared) {
        self.category = category
        self.registry = registry
        self.osLogger = Logger(subsystem: subsystem, category: category.rawValue)
    }

    public func debug(_ message: String) { log(.debug, message) }
    public func info(_ message: String) { log(.info, message) }
    public func warning(_ message: String) { log(.warning, message) }
    public func error(_ message: String) { log(.error, message) }

    public func log(_ level: LogLevel, _ message: String) {
        guard level >= registry.minimumLevel else { return }
        switch level {
        case .debug: osLogger.debug("\(message, privacy: .public)")
        case .info: osLogger.info("\(message, privacy: .public)")
        case .warning: osLogger.warning("\(message, privacy: .public)")
        case .error: osLogger.error("\(message, privacy: .public)")
        }
        registry.dispatch(LogEntry(level: level, category: category, message: message, sessionId: registry.sessionId))
    }
}
