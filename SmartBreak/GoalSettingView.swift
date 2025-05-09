//
//  GoalSettingView.swift
//  SmartBreak
//
//  Created by Hugo Peyron on 09/05/2025.
//

import SwiftUI

struct GoalSettingView: View {
  var stepManager: StepManager
  @Environment(\.dismiss) private var dismiss
  @State private var tempGoal: Double
  @State private var isEditing = false

  init(stepManager: StepManager) {
    self.stepManager = stepManager
    // Initialize the temporary goal with current value
    _tempGoal = State(initialValue: Double(stepManager.stepGoal))
  }

  // Calculate user's best average
  private var userAverage: Int {
    if stepManager.yearlyDailyAverage > 0 {
      return stepManager.yearlyDailyAverage
    } else if stepManager.monthlyAverage > 0 {
      return stepManager.monthlyAverage
    } else {
      return stepManager.weeklyAverage
    }
  }

  // Calculate goal vs average ratio
  private var goalRatio: Double {
    guard userAverage > 0 else { return 1.0 }
    return Double(tempGoal) / Double(userAverage)
  }

  // Get precise deviation from average
  private var deviation: String {
    guard userAverage > 0 else { return "N/A" }
    let percentage = (goalRatio - 1.0) * 100
    let sign = percentage >= 0 ? "+" : ""
    return "\(sign)\(Int(percentage.rounded()))%"
  }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 40) {
        VStack(alignment: .leading, spacing: 4) {
          Text("STEP GOAL")
            .font(.caption)
            .foregroundStyle(.secondary)

          Text("\(Int(tempGoal))")
            .font(.system(size: 64, weight: .ultraLight))
            .contentTransition(.numericText())
            .animation(.spring(duration: 0.5), value: Int(tempGoal))
            .padding(.bottom, 10)
        }

        // Scientific comparison section
        if userAverage > 0 {
          HStack(alignment: .top) {
            // Average column
            VStack(alignment: .leading, spacing: 4) {
              Text("AVG")
                .font(.caption)
                .foregroundStyle(.secondary)

              Text("\(userAverage)")
                .font(.system(size: 28, weight: .light))
            }

            Spacer()

            // Ratio column
            VStack(alignment: .trailing, spacing: 4) {
              Text("VARIANCE")
                .font(.caption)
                .foregroundStyle(.secondary)

              Text(deviation)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(goalRatio > 1.2 ? .primary : .secondary)
            }
          }
          .padding(.vertical, 12)
          .padding(.horizontal, 16)
          .background(
            Rectangle()
              .fill(Color.secondary.opacity(0.03))
          )
          .cornerRadius(4)
        }

        // Minimal slider
        VStack(spacing: 16) {
          Slider(
            value: $tempGoal,
            in: 1000...30000,
            step: 1000,
            onEditingChanged: { editing in
              isEditing = editing
            }
          )
          .tint(.primary)
          .sensoryFeedback(.selection, trigger: Int(tempGoal) / 1000)

          // Subtle labels for the slider range
          HStack {
            Text("1,000")
              .font(.caption2)
              .foregroundStyle(.secondary)
            Spacer()
            Text("30,000")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }

        // Common preset goals
        VStack(alignment: .leading, spacing: 8) {
          Text("PRESETS")
            .font(.caption)
            .foregroundStyle(.secondary)

          HStack(spacing: 12) {
            ForEach([5000, 10000, 15000], id: \.self) { preset in
              Button {
                tempGoal = Double(preset)
              } label: {
                Text("\(preset)")
                  .font(.system(.body))
                  .padding(.vertical, 8)
                  .padding(.horizontal, 12)
                  .background(
                    RoundedRectangle(cornerRadius: 4)
                      .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                      .background(
                        Int(tempGoal) == preset ?
                        Color.primary.opacity(0.05) :
                          Color.clear
                      )
                      .clipShape(RoundedRectangle(cornerRadius: 4))
                  )
              }
              .buttonStyle(.plain)
              .sensoryFeedback(.selection, trigger: Int(tempGoal) == preset)
            }
          }
        }

        Spacer()
      }
      .padding(30)
      .navigationTitle("Step Goal")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") {
            stepManager.stepGoal = Int(tempGoal)
            dismiss()
          }
          .sensoryFeedback(.success, trigger: UUID())
        }

        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") {
            dismiss()
          }
          .sensoryFeedback(.selection, trigger: UUID())
        }
      }
    }
  }
}

#Preview {
  GoalSettingView(stepManager: StepManager())
}
