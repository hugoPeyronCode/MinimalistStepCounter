//
//  WidgetEntry.swift
//  SmartBreak
//
//  Created by Hugo Peyron on 13/05/2025.
//

import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let stepCount: Int
    let stepGoal: Int
    let progress: Double

    // For preview data
    static let previewData = SimpleEntry(
        date: Date(),
        stepCount: 7342,
        stepGoal: 10000,
        progress: 0.73
    )

    // For placeholder
    static let placeholderData = SimpleEntry(
        date: Date(),
        stepCount: 0,
        stepGoal: 10000,
        progress: 0.0
    )
}
