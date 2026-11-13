//
//  LogViewerView.swift
//  ManiLogger
//

import SwiftUI
import ManiSwiftUIComponents

/// Searchable, filterable list of recent log entries. Push it inside a `NavigationStack`;
/// tapping a row opens `LogDetailView`.
public struct LogViewerView: View {
    @Environment(\.maniTheme) private var theme
    @State private var viewModel: LogViewerViewModel

    public init(viewModel: LogViewerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        List {
            if viewModel.filteredLogEntries.isEmpty {
                Text("No logs")
                    .foregroundStyle(theme.base.textSecondary)
            }
            ForEach(Array(viewModel.filteredLogEntries.enumerated()), id: \.offset) { _, entry in
                NavigationLink {
                    LogDetailView(entry: entry, searchQuery: viewModel.logSearchQuery)
                } label: {
                    VStack(alignment: .leading, spacing: ManiSpacing.xs) {
                        Text("\(entry.date.formatted(date: .omitted, time: .standard))  \(entry.level.label)  [\(entry.category.rawValue)]")
                            .font(.caption2.monospaced())
                            .foregroundStyle(LogEntryStyle.color(for: entry.level))
                        // Capped so long entries (e.g. config dumps) don't blow up row height; full text in detail.
                        Text(LogEntryStyle.highlighted(entry.message, query: viewModel.logSearchQuery, accent: theme.accent.accent))
                            .font(.caption.monospaced())
                            .foregroundStyle(theme.base.text)
                            .lineLimit(5)
                            .truncationMode(.tail)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) { header }
        .refreshable { viewModel.reloadLogs() }
        .onAppear { viewModel.reloadLogs() }
        .navigationTitle("Logs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: viewModel.logText)
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("Clear") { viewModel.clearLogs() }
            }
        }
    }

    /// Search + category dropdown, level segments, time chips and the result count.
    /// Pinned above the list (not inside a List row, where SwiftUI would fire every chip on one tap).
    private var header: some View {
        VStack(alignment: .leading, spacing: ManiSpacing.sm) {
            HStack(spacing: ManiSpacing.sm) {
                ManiSearchField(text: $viewModel.logSearchText, placeholder: "Search logs")
                filterMenu
            }
            Picker("Minimum level", selection: $viewModel.logLevelFilter) {
                ForEach(LogLevel.allCases, id: \.self) { level in
                    Text(level.label).tag(level)
                }
            }
            .pickerStyle(.segmented)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ManiSpacing.sm) {
                    ForEach(LogTimeRange.allCases, id: \.self) { range in
                        ManiChip(range.title, isSelected: viewModel.logTimeRange == range) { viewModel.logTimeRange = range }
                    }
                }
            }
            HStack {
                Text(viewModel.logResultSummary)
                    .font(.caption)
                    .foregroundStyle(theme.base.textSecondary)
                Spacer()
                if viewModel.hasActiveLogFilters {
                    Button("Reset") { viewModel.resetLogFilters() }
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, ManiSpacing.lg)
        .padding(.vertical, ManiSpacing.sm)
        .background(theme.base.background)
    }

    private var filterMenu: some View {
        Menu {
            Section("Categories") {
                Toggle("All categories", isOn: Binding(
                    get: { viewModel.selectedLogCategories.isEmpty },
                    set: { _ in viewModel.clearLogCategories() }
                ))
                ForEach(viewModel.visibleLogCategories, id: \.self) { category in
                    Toggle("\(category.rawValue) (\(viewModel.logCategoryCounts[category] ?? 0))", isOn: Binding(
                        get: { viewModel.selectedLogCategories.contains(category) },
                        set: { _ in viewModel.toggleLogCategory(category) }
                    ))
                }
            }
            #if os(iOS)
            // Keep the menu open while picking several categories.
            .menuActionDismissBehavior(.disabled)
            #endif

            if viewModel.hasActiveLogFilters {
                Button("Reset filters", role: .destructive) { viewModel.resetLogFilters() }
            }
        } label: {
            IconView(.filter, size: 20,
                     color: viewModel.hasActiveLogFilters ? theme.accent.accent : theme.base.text)
                .padding(ManiSpacing.xs)
        }
        .accessibilityLabel("Filter logs")
    }
}
