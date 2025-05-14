//
//  StatsWidget.swift
//  SmartBreakWidget
//
//  Created by Hugo Peyron on 14/05/2025.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Stats Period Enum
enum StatsPeriod: String, CaseIterable, AppEnum {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Stats Period"
    static var caseDisplayRepresentations: [StatsPeriod: DisplayRepresentation] = [
        .week: "Week",
        .month: "Month",
        .year: "Year"
    ]
}

// MARK: - Stats Widget Entry
struct StatsEntry: TimelineEntry {
    let date: Date
    let weeklyAverage: Int
    let monthlyAverage: Int
    let yearlyAverage: Int
    let currentPeriod: StatsPeriod
    let stepGoal: Int

    static let mockData = StatsEntry(
        date: Date(),
        weeklyAverage: 8500,
        monthlyAverage: 7800,
        yearlyAverage: 8200,
        currentPeriod: .week,
        stepGoal: 10000
    )
}

// MARK: - Stats Widget Provider
struct StatsProvider: TimelineProvider {
    typealias Entry = StatsEntry

    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry.mockData
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> ()) {
        completion(StatsEntry.mockData)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> ()) {
        let entry = StatsEntry(
            date: Date(),
            weeklyAverage: SharedData.getWeeklyAverage(),
            monthlyAverage: SharedData.getMonthlyAverage(),
            yearlyAverage: SharedData.getYearlyAverage(),
            currentPeriod: SharedData.getCurrentStatsPeriod(),
            stepGoal: SharedData.getStepGoal()
        )

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Toggle Stats Period Intent
struct ToggleStatsPeriodIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Stats Period"
    static var description = IntentDescription("Switch between week, month, and year stats")

    @Parameter(title: "Period")
    var period: StatsPeriod

    init() {}

    init(period: StatsPeriod) {
        self.period = period
    }

    func perform() async throws -> some IntentResult {
        SharedData.setCurrentStatsPeriod(period)
        return .result()
    }
}

// MARK: - Stats Widget View
struct StatsWidgetView: View {
    var entry: StatsProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Steps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            // Current stats
            VStack(spacing: 4) {
                Text("\(currentAverageValue)")
                    .font(.system(size: 42, weight: .thin))
                    .monospacedDigit()

                Text("avg \(entry.currentPeriod.rawValue.lowercased())")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Period toggle buttons
            HStack(spacing: 8) {
                ForEach(StatsPeriod.allCases, id: \.self) { period in
                    Button(intent: ToggleStatsPeriodIntent(period: period)) {
                        Text(period.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                entry.currentPeriod == period
                                    ? Color.primary
                                    : Color.clear
                            )
                            .foregroundStyle(
                                entry.currentPeriod == period
                                    ? .primary
                                    : .secondary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .containerBackground(Color(.systemBackground), for: .widget)
    }

    private var currentAverageValue: Int {
        switch entry.currentPeriod {
        case .week: return entry.weeklyAverage
        case .month: return entry.monthlyAverage
        case .year: return entry.yearlyAverage
        }
    }
}

// MARK: - Stats Widget Definition
struct StatsWidget: Widget {
    let kind: String = "StatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            StatsWidgetView(entry: entry)
        }
        .configurationDisplayName("Step Stats")
        .description("View your step averages with weekly, monthly, and yearly breakdowns.")
        .supportedFamilies([.systemMedium])
    }
}

//
//  GoalPercentageWidget.swift
//  SmartBreakWidget
//
//  Created by Hugo Peyron on 14/05/2025.
//

// MARK: - Goal Percentage Entry
struct GoalPercentageEntry: TimelineEntry {
    let date: Date
    let currentSteps: Int
    let stepGoal: Int
    let percentage: Int
    let progress: Double

    static let mockData = GoalPercentageEntry(
        date: Date(),
        currentSteps: 7500,
        stepGoal: 10000,
        percentage: 75,
        progress: 0.75
    )
}

// MARK: - Goal Percentage Provider
struct GoalPercentageProvider: TimelineProvider {
    typealias Entry = GoalPercentageEntry

    func placeholder(in context: Context) -> GoalPercentageEntry {
        GoalPercentageEntry.mockData
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalPercentageEntry) -> ()) {
        completion(createEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalPercentageEntry>) -> ()) {
        let entry = createEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> GoalPercentageEntry {
        let currentSteps = SharedData.getStepCount()
        let stepGoal = SharedData.getStepGoal()
        let progress = SharedData.getProgress()
        let percentage = min(100, Int(progress * 100))

        return GoalPercentageEntry(
            date: Date(),
            currentSteps: currentSteps,
            stepGoal: stepGoal,
            percentage: percentage,
            progress: progress
        )
    }
}

// MARK: - Goal Percentage Widget View
struct GoalPercentageWidgetView: View {
    var entry: GoalPercentageProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Steps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Spacer()

            // Circular progress indicator
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: progressLineWidth)
                    .frame(width: circleSize, height: circleSize)

                // Progress circle
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        entry.progress >= 1.0 ? Color.green : Color.primary,
                        style: StrokeStyle(lineWidth: progressLineWidth, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: entry.progress)

                // Percentage text
                VStack(spacing: 2) {
                    Text("\(entry.percentage)")
                        .font(percentageFont)
                        .monospacedDigit()
                        .fontWeight(.thin)

                    Text("%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Goal text
            if widgetFamily == .systemMedium {
                Text("Goal: \(entry.stepGoal)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .containerBackground(Color(.systemBackground), for: .widget)
    }

    private var circleSize: CGFloat {
        widgetFamily == .systemSmall ? 80 : 100
    }

    private var progressLineWidth: CGFloat {
        widgetFamily == .systemSmall ? 8 : 10
    }

    private var percentageFont: Font {
        widgetFamily == .systemSmall
            ? .system(size: 28, weight: .thin)
            : .system(size: 36, weight: .thin)
    }
}

// MARK: - Goal Percentage Widget Definition
struct GoalPercentageWidget: Widget {
    let kind: String = "GoalPercentageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalPercentageProvider()) { entry in
            GoalPercentageWidgetView(entry: entry)
        }
        .configurationDisplayName("Goal Progress")
        .description("Shows your daily step goal completion as a percentage.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

//
//  DetailedStepWidget.swift
//  SmartBreakWidget
//
//  Created by Hugo Peyron on 14/05/2025.
//

// MARK: - Detailed Step Entry
struct DetailedStepEntry: TimelineEntry {
    let date: Date
    let currentSteps: Int
    let stepGoal: Int
    let weeklyAverage: Int
    let monthlyAverage: Int
    let progress: Double
    let todayTarget: Int

    static let mockData = DetailedStepEntry(
        date: Date(),
        currentSteps: 8750,
        stepGoal: 10000,
        weeklyAverage: 8500,
        monthlyAverage: 7800,
        progress: 0.875,
        todayTarget: 1250
    )
}

// MARK: - Detailed Step Provider
struct DetailedStepProvider: TimelineProvider {
    typealias Entry = DetailedStepEntry

    func placeholder(in context: Context) -> DetailedStepEntry {
        DetailedStepEntry.mockData
    }

    func getSnapshot(in context: Context, completion: @escaping (DetailedStepEntry) -> ()) {
        completion(createEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DetailedStepEntry>) -> ()) {
        let entry = createEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> DetailedStepEntry {
        let currentSteps = SharedData.getStepCount()
        let stepGoal = SharedData.getStepGoal()
        let progress = SharedData.getProgress()
        let todayTarget = max(0, stepGoal - currentSteps)

        return DetailedStepEntry(
            date: Date(),
            currentSteps: currentSteps,
            stepGoal: stepGoal,
            weeklyAverage: SharedData.getWeeklyAverage(),
            monthlyAverage: SharedData.getMonthlyAverage(),
            progress: progress,
            todayTarget: todayTarget
        )
    }
}

// MARK: - Detailed Step Widget View
struct DetailedStepWidgetView: View {
    var entry: DetailedStepProvider.Entry

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Steps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Current step count
            Text("\(entry.currentSteps)")
                .font(.system(size: 72, weight: .ultraLight))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Progress bar
            VStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(entry.progress >= 1.0 ? Color.green : Color.primary)
                        .frame(height: 6)
                        .containerRelativeFrame([.horizontal]) { length, _ in
                            max(length * CGFloat(entry.progress), 0)
                        }
                        .animation(.spring(duration: 1.0), value: entry.progress)
                }

                HStack {
                    Text("Goal: \(entry.stepGoal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if entry.todayTarget > 0 {
                        Text("\(entry.todayTarget) to go")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Goal achieved!")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            // Stats section
            VStack(spacing: 8) {
                HStack {
                    Text("Statistics")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                HStack(spacing: 20) {
                    StatItemView(
                        title: "Weekly Avg",
                        value: entry.weeklyAverage
                    )

                    Divider()
                        .frame(height: 30)

                    StatItemView(
                        title: "Monthly Avg",
                        value: entry.monthlyAverage
                    )

                    Spacer()
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .containerBackground(Color(.systemBackground), for: .widget)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }
}

// MARK: - Stat Item View
struct StatItemView: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 24, weight: .thin))
                .monospacedDigit()

            Text(title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Detailed Step Widget Definition
struct DetailedStepWidget: Widget {
    let kind: String = "DetailedStepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DetailedStepProvider()) { entry in
            DetailedStepWidgetView(entry: entry)
        }
        .configurationDisplayName("Detailed Steps")
        .description("Comprehensive view of your steps, goal progress, and statistics.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Extension to SharedData (mock implementation)
extension SharedData {
    static func getWeeklyAverage() -> Int { 8500 }
    static func getMonthlyAverage() -> Int { 7800 }
    static func getYearlyAverage() -> Int { 8200 }
    static func getCurrentStatsPeriod() -> StatsPeriod { .week }
    static func setCurrentStatsPeriod(_ period: StatsPeriod) {}
}
