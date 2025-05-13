//
//  SmartBreakWidget.swift
//  SmartBreakWidget
//
//  Created by Hugo Peyron on 13/05/2025.
//

import WidgetKit
import SwiftUI

struct SmartBreakWidget: Widget {
    let kind: String = "SmartBreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmartBreakProvider()) { entry in
            SmartBreakWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Step Counter")
        .description("Shows your daily step count and progress toward your goal.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
