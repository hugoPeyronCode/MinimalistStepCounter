//
//  WidgetView.swift
//  SmartBreak
//
//  Created by Hugo Peyron on 13/05/2025.
//
// 📄 WidgetView.swift
// 📍 SmartBreakWidget extension
// Remplace le contenu existant

import WidgetKit
import SwiftUI

struct SmartBreakWidgetEntryView: View {
    var entry: SmartBreakProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        VStack(spacing: 8) {

            // Steps count - adapting size based on widget size
            Text("\(entry.stepCount)")
                .font(stepCountFont)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Steps label
            Text("steps")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Progress bar
            progressBar

            // Goal text - only show if there's space
            if widgetFamily != .systemSmall || entry.stepCount < 10000 {
                Text("Goal: \(entry.stepGoal)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(widgetPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .containerBackground(Color(.systemBackground), for: .widget)
    }

    private var stepCountFont: Font {
        switch widgetFamily {
        case .systemSmall:
            return .system(size: 48, weight: .thin)
        case .systemMedium:
            return .system(size: 56, weight: .thin)
        default:
            return .system(size: 64, weight: .thin)
        }
    }

    private var widgetPadding: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 12
        default:
            return 16
        }
    }

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 4)

            // Progress
            RoundedRectangle(cornerRadius: 2)
                .fill(entry.progress >= 1.0 ? Color.green : Color.primary)
                .frame(height: 4)
                .scaleEffect(x: entry.progress, y: 1.0, anchor: .leading)
                .animation(.easeInOut(duration: 0.5), value: entry.progress)
        }
        .frame(maxWidth: progressBarWidth)
    }

    private var progressBarWidth: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 80
        case .systemMedium:
            return 120
        default:
            return 160
        }
    }
} 
