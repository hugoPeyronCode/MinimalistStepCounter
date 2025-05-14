//
//  SmartBreakWidgetBundle.swift
//  SmartBreakWidget
//
//  Created by Hugo Peyron on 13/05/2025.
//

import WidgetKit
import SwiftUI

@main
struct SmartBreakWidgets: WidgetBundle {
    var body: some Widget {
      SmartBreakWidget()
      StatsWidget()
      GoalPercentageWidget()
      DetailedStepWidget()
    }
}

// MARK: - Stats Widget Previews
#Preview("Stats - Week", as: .systemMedium) {
    StatsWidget()
} timeline: {
    StatsEntry(
        date: Date(),
        weeklyAverage: 8500,
        monthlyAverage: 7800,
        yearlyAverage: 8200,
        currentPeriod: .week,
        stepGoal: 10000
    )
}

#Preview("Stats - Month", as: .systemMedium) {
    StatsWidget()
} timeline: {
    StatsEntry(
        date: Date(),
        weeklyAverage: 8500,
        monthlyAverage: 7800,
        yearlyAverage: 8200,
        currentPeriod: .month,
        stepGoal: 10000
    )
}

#Preview("Stats - Year", as: .systemMedium) {
    StatsWidget()
} timeline: {
    StatsEntry(
        date: Date(),
        weeklyAverage: 8500,
        monthlyAverage: 7800,
        yearlyAverage: 8200,
        currentPeriod: .year,
        stepGoal: 10000
    )
}

// MARK: - Goal Percentage Widget Previews
#Preview("Goal Progress - Small 75%", as: .systemSmall) {
    GoalPercentageWidget()
} timeline: {
    GoalPercentageEntry(
        date: Date(),
        currentSteps: 7500,
        stepGoal: 10000,
        percentage: 75,
        progress: 0.75
    )
}

#Preview("Goal Progress - Medium 45%", as: .systemMedium) {
    GoalPercentageWidget()
} timeline: {
    GoalPercentageEntry(
        date: Date(),
        currentSteps: 4500,
        stepGoal: 10000,
        percentage: 45,
        progress: 0.45
    )
}

#Preview("Goal Progress - Small 100%", as: .systemSmall) {
    GoalPercentageWidget()
} timeline: {
    GoalPercentageEntry(
        date: Date(),
        currentSteps: 10500,
        stepGoal: 10000,
        percentage: 100,
        progress: 1.05
    )
}

// MARK: - Detailed Step Widget Previews
#Preview("Detailed Steps - In Progress", as: .systemLarge) {
    DetailedStepWidget()
} timeline: {
    DetailedStepEntry(
        date: Date(),
        currentSteps: 8750,
        stepGoal: 10000,
        weeklyAverage: 8500,
        monthlyAverage: 7800,
        progress: 0.875,
        todayTarget: 1250
    )
}

#Preview("Detailed Steps - Goal Achieved", as: .systemLarge) {
    DetailedStepWidget()
} timeline: {
    DetailedStepEntry(
        date: Date(),
        currentSteps: 12500,
        stepGoal: 10000,
        weeklyAverage: 8500,
        monthlyAverage: 7800,
        progress: 1.25,
        todayTarget: 0
    )
}

#Preview("Detailed Steps - Morning", as: .systemLarge) {
    DetailedStepWidget()
} timeline: {
    DetailedStepEntry(
        date: Date(),
        currentSteps: 2500,
        stepGoal: 10000,
        weeklyAverage: 8500,
        monthlyAverage: 7800,
        progress: 0.25,
        todayTarget: 7500
    )
}
