//
//  DailySteps.swift
//  SmartBreak
//
//  Created by Hugo Peyron on 09/05/2025.
//

import SwiftUI
import HealthKit

class DailySteps: Identifiable {
    var id = UUID()
    var date: Date
    var count: Int

    init(date: Date, count: Int) {
        self.date = date
        self.count = count
    }

    // Helper to get formatted date string
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
