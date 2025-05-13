//
//  WidgetProvider.swift
//  SmartBreak
//
//  Created by Hugo Peyron on 13/05/2025.
//
// 📄 WidgetProvider.swift
// 📍 SmartBreakWidget extension
// Remplace le contenu existant

import WidgetKit
import SwiftUI

// Define the entry structure first
struct SmartBreakEntry: TimelineEntry {
    let date: Date
    let stepCount: Int
    let stepGoal: Int
    let progress: Double

    // For preview data
    static let previewData = SmartBreakEntry(
        date: Date(),
        stepCount: 7342,
        stepGoal: 10000,
        progress: 0.73
    )

    // For placeholder
    static let placeholderData = SmartBreakEntry(
        date: Date(),
        stepCount: 0,
        stepGoal: 10000,
        progress: 0.0
    )
}

// Define the provider using the correct entry type
struct SmartBreakProvider: TimelineProvider {
    typealias Entry = SmartBreakEntry

    func placeholder(in context: Context) -> SmartBreakEntry {
        print("📱 Widget: Generating placeholder")
        return SmartBreakEntry.placeholderData
    }

    func getSnapshot(in context: Context, completion: @escaping (SmartBreakEntry) -> ()) {
        print("📱 Widget: Generating snapshot")
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmartBreakEntry>) -> ()) {
        print("📱 Widget: Generating timeline")

        // Get current data
        let currentEntry = createEntry()

        // Create entries for the next 24 hours (updated every hour)
        var entries: [SmartBreakEntry] = [currentEntry]
        let calendar = Calendar.current
        let currentDate = Date()

        // Add entries every hour for the next 24 hours
        for hourOffset in 1...24 {
            if let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: currentDate) {
                let entry = SmartBreakEntry(
                    date: entryDate,
                    stepCount: SharedData.getStepCount(),
                    stepGoal: SharedData.getStepGoal(),
                    progress: SharedData.getProgress()
                )
                entries.append(entry)
            }
        }

        // Schedule next update in 1 hour
        let nextUpdate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))

        print("📱 Widget: Timeline created with \(entries.count) entries")
        completion(timeline)
    }

    private func createEntry() -> SmartBreakEntry {
        let stepCount = SharedData.getStepCount()
        let stepGoal = SharedData.getStepGoal()
        let progress = SharedData.getProgress()

        print("📱 Widget: Creating entry - \(stepCount)/\(stepGoal) steps (\(Int(progress * 100))%)")

        return SmartBreakEntry(
            date: Date(),
            stepCount: stepCount,
            stepGoal: stepGoal,
            progress: progress
        )
    }
}
