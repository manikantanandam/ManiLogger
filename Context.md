# Context.md

Guidance for working in this repository. Keep it current as the package evolves.

## Quick Index

- **Purpose**: an app-agnostic logger plus an in-app log viewer for debug builds (iOS 17+/macOS 14+). The first consumer is apoorva-skip.
- **Layout**: `Core/` (logger, sinks, entries) and `UI/` (viewer view model and screens). One product, `ManiLogger`.
- **Commands**: `swift test` / `swift test --filter <Name>`.
- **Conventions**: no PII in log messages; sinks are registered by the app's composition root; UI stays Skip-portable (no UIKit).

## Purpose

`ManiLogger` gives an app one logging call that does three things:
- writes to the Xcode console through `os.Logger` (subsystem = bundle id, category = `LogCategory`);
- fans out to pluggable `LogSink`s (in-memory ring buffer, rotating file, or anything the app adds, such as a crash-reporter forwarder);
- ships a ready-made log viewer: a searchable list with a filter dropdown (level / time range / category) and a detail screen for each entry.

It depends on `ManiSwiftUIComponents` for theming and controls (`ManiSearchField`, `IconView`, `ManiListRow`).

## Layout

- `Sources/ManiLogger/Core/`
  - `LogEntry.swift`: `LogLevel`, the open `LogCategory` struct, `LogEntry` and the `LogSink` protocol.
  - `AppLogger.swift`: `AppLogger` (the call-site API) and the `LogSinks` registry (`shared`, `configure`, `add`, per-launch `sessionId`).
  - `LogBuffer.swift`: thread-safe in-memory ring buffer (default 500 entries).
  - `FileLogSink.swift`: `Application Support/Logs/current.log` + `previous.log`, rotated at 1 MB and written on a serial queue.
- `Sources/ManiLogger/UI/`
  - `LogViewerViewModel.swift`: filters, counts, summary, clear and share text; `now` is injectable for tests.
  - `LogViewerView.swift`: list with rows capped at 5 lines, a pinned search field and a filter `Menu`.
  - `LogDetailView.swift`: full entry, selectable text, share; also `LogEntryStyle` (level colours, search highlighting).
- `Tests/ManiLoggerTests/`: Swift Testing suites for the core and the view model.

## Usage

```swift
// Composition root, once at launch
let buffer = LogBuffer()
let file = FileLogSink(directory: FileLogSink.defaultDirectory())
LogSinks.shared.configure(sinks: [buffer, file], minimumLevel: isProduction ? .info : .debug)

// Any file
private let logger = AppLogger(category: .sync)
logger.info("Fetched \(count) items")

// Custom category
extension LogCategory { static let billing: LogCategory = "billing" }

// Debug screen (inside a NavigationStack)
LogViewerView(viewModel: LogViewerViewModel(logBuffer: buffer, fileLogSink: file))
```

## Conventions

- Never log PII (names, phone numbers, emails, amounts). Log ids and counts.
- Keep `Core/` free of SwiftUI and third-party dependencies, so it could later be split into its own product.
- The UI must stay plain, Skip-portable SwiftUI, following ManiSwiftUIComponents' rules: no UIKit, no `.onTapGesture`, icons only through `IconView`.
- Never put multiple buttons in a single `List` row. SwiftUI fires all of them on one tap, which is why the filters live in a `Menu`.
- Use Swift Testing (`import Testing`).

## Release

Tag `vX.Y.Z` on `main` and push the tag. Consumers pin an exact version. In apoorva-skip, bump `remoteVersion` in `scripts/library-registry.json`, then run `scripts/toggle-library.sh remote ManiLogger`.

## Commands

```bash
swift test
swift test --filter LogViewerViewModelTests
```
