//
//  ContentView.swift
//  SmartBreak
//
//  Created by Hugo Peyron on 09/05/2025.
//
import SwiftUI
import HealthKit
import Combine

struct ContentView: View {
  var stepManager = StepManager()
  @State private var showingStats = false
  @State private var showingGoalSetting = false
  @State private var animatedStepCount = 0
  @State private var targetStepCount = 0
  @State private var isFirstLoad = true
  @State private var animationTimer: AnyCancellable?
  @State private var lastHapticHundreds = 0
  @State private var refreshCompleted = false

  var body: some View {
    NavigationStack {
      VStack {

        Spacer()

        steps

        VStack(spacing: 8) {
          progressBar
          stepGoal
        }
        .padding(.horizontal)
        .padding(.bottom, 30)

        Spacer()

        buttons

      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.systemBackground))
      .navigationTitle("")
      .sheet(isPresented: $showingStats) {
        StatsView(stepManager: stepManager)
      }
      .sheet(isPresented: $showingGoalSetting) {
        GoalSettingView(stepManager: stepManager)
      }
      .onChange(of: stepManager.todaySteps) { oldValue, newValue in
        // Start the counting animation
        startCountingAnimation(to: newValue)
      }
      .onChange(of: animatedStepCount) { oldValue, newValue in
        // Check for crossing hundreds boundaries
        checkAndTriggerHaptics(oldValue: oldValue, newValue: newValue)
      }
      .onChange(of: stepManager.isRefreshing) { _, isRefreshing in
        if !isRefreshing && refreshCompleted {
          // Trigger haptic feedback when refresh completes
          let generator = UINotificationFeedbackGenerator()
          generator.notificationOccurred(.success)

          // Reset the completion flag after a delay
          DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            refreshCompleted = false
          }
        }
      }
      .sensoryFeedback(.success, trigger: stepManager.goalJustReached)
      .onAppear {
        stepManager.setupData()
      }
    }
  }

  @ViewBuilder
  private var steps: some View {
    Text("\(animatedStepCount)")
      .font(.system(size: 96, weight: .thin))
      .monospacedDigit()
      .contentTransition(.numericText())
      .animation(.spring(duration: 0.2), value: animatedStepCount)

    Text("steps today")
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(.bottom, 10)
  }

  @ViewBuilder
  private var statusMessage: some View {
    // Status message is now integrated in stepGoal
    EmptyView()
  }

  // Updated progress bar without GeometryReader
  private var progressBar: some View {
    VStack(spacing: 8) {
      ZStack(alignment: .leading) {
        // Background bar
        Capsule()
          .fill(Color.secondary.opacity(0.2))
          .frame(height: 4)

        // Progress bar
        Capsule()
          .fill(
            stepManager.goalProgress >= 1.0 ? Color.green : Color.primary
          )
          .frame(height: 4)
          .containerRelativeFrame([.horizontal]) { length, _ in
            max(length * CGFloat(stepManager.goalProgress), 0)
          }
          .animation(.spring(duration: 1.0), value: stepManager.goalProgress)
      }
    }
    .frame(height: 4)
  }

  private var stepGoal: some View {
    HStack {
      Text("Goal: \(String(stepManager.stepGoal))")
        .font(.caption)
        .foregroundStyle(.secondary)

      Spacer()

      // Discrete status message replacing "Last updated"
      if stepManager.isRefreshing {
        HStack(spacing: 4) {
          ProgressView()
            .controlSize(.mini)
            .scaleEffect(0.6)

          Text("Syncing...")
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
      } else if refreshCompleted {
        HStack(spacing: 4) {
          Image(systemName: "checkmark")
            .foregroundStyle(.green)
            .font(.caption2)

          Text("Updated")
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .transition(.opacity.combined(with: .scale))
      } else {
        Text("Last updated \(formatLastUpdate(stepManager.lastRefreshTime))")
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
    }
  }

  private var buttons: some View {
    VStack {
      // Refresh button with enhanced animation
      Button {
        Task {
          await stepManager.refreshAllData()
          refreshCompleted = true
        }
      } label: {
        Image(systemName: "arrow.2.circlepath")
          .symbolEffect(.rotate, isActive: stepManager.isRefreshing)
          .symbolEffect(.bounce, value: stepManager.isRefreshing)
          .frame(width: 24, height: 24)
          .padding()
          .clipShape(.capsule)
          .overlay {
            Capsule()
              .stroke(
                stepManager.isRefreshing ? Color.blue.opacity(0.5) : .gray,
                lineWidth: stepManager.isRefreshing ? 1.5 : 0.5
              )
              .animation(.bouncy, value: stepManager.isRefreshing)
          }
      }
      .background(.background)
      .disabled(stepManager.isRefreshing)
      .scaleEffect(stepManager.isRefreshing ? 0.95 : 1.0)
      .animation(.bouncy, value: stepManager.isRefreshing)
      .sensoryFeedback(.impact(weight: .light), trigger: stepManager.isRefreshing)

      HStack(spacing: 20) {
        Spacer()

        // Stats button
        Button {
          showingStats = true
        } label: {
          Image(systemName: "chart.line.uptrend.xyaxis")
            .frame(width: 24, height: 24)
            .padding()
            .background(.background)
            .clipShape(.capsule)
            .overlay {
              Capsule()
                .stroke(lineWidth: 0.5)
            }
        }
        .sensoryFeedback(.selection, trigger: showingStats)

        // Goal button
        Button {
          showingGoalSetting = true
        } label: {
          Image(systemName: "target")
            .frame(width: 24, height: 24)
            .padding()
            .background(.background)
            .clipShape(.capsule)
            .overlay {
              Capsule()
                .stroke(lineWidth: 0.5)
            }
        }
        .sensoryFeedback(.selection, trigger: showingGoalSetting)

        Spacer()
      }
      .padding(.bottom, 10)
    }
    .foregroundStyle(.foreground)
  }

  private func checkAndTriggerHaptics(oldValue: Int, newValue: Int) {
    let oldHundreds = oldValue / 100
    let newHundreds = newValue / 100

    if newHundreds > oldHundreds {
      // Cross-hundreds haptic
      let generator = UIImpactFeedbackGenerator(style: .light)
      generator.impactOccurred()

      // For milestone hundreds, use stronger feedback
      if newValue % 1000 == 0 {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
      }
    }
  }

  private func startCountingAnimation(to targetValue: Int) {
    // Cancel any existing animation
    animationTimer?.cancel()

    // Set the target value
    targetStepCount = targetValue

    // If it's the first load, start from 0
    let startValue = isFirstLoad ? 0 : animatedStepCount

    // Calculate the step size
    let totalDifference = targetValue - startValue

    // Don't animate if there's no change or very small change
    if totalDifference == 0 {
      return
    }

    // Choose animation duration and steps based on difference magnitude
    let duration: Double
    let numberOfSteps: Int

    if abs(totalDifference) > 1000 {
      // For large differences, use more steps over longer duration
      duration = isFirstLoad ? 2.0 : 1.2
      numberOfSteps = 100
    } else {
      // For smaller differences, use fewer steps
      duration = isFirstLoad ? 1.5 : 0.8
      numberOfSteps = min(60, max(20, abs(totalDifference)))
    }

    // Ensure we have at least one step
    let actualSteps = min(numberOfSteps, abs(totalDifference))

    // Calculate interval between updates
    let interval = duration / Double(actualSteps)

    // Create exponential ease-out increments for smoother animation
    let incrementsArray = createEaseOutIncrements(start: startValue, end: targetValue, steps: actualSteps)
    var currentIndex = 0

    // Create timer with fixed small interval for smooth transitions
    animationTimer = Timer.publish(every: interval, on: .main, in: .common)
      .autoconnect()
      .sink { _ in
        if currentIndex < incrementsArray.count {
          // Update with the pre-calculated increment
          animatedStepCount = incrementsArray[currentIndex]
          currentIndex += 1
        } else {
          // Ensure we end exactly on the target
          animatedStepCount = targetStepCount
          animationTimer?.cancel()
          isFirstLoad = false
        }
      }
  }

  // Creates an array of values with exponential ease-out for smoother animation
  private func createEaseOutIncrements(start: Int, end: Int, steps: Int) -> [Int] {
    var result: [Int] = []
    let difference = Double(end - start)

    for i in 0..<steps {
      let progress = Double(i) / Double(steps - 1)
      // Ease out function: 1 - pow(1 - t, 3)
      let easeOut = 1.0 - pow(1.0 - progress, 3.0)
      let value = start + Int(difference * easeOut)
      result.append(value)
    }

    // Ensure the last value is exactly the end value
    if let last = result.last, last != end {
      result[result.count - 1] = end
    }

    return result
  }

  // Format the last update time
  private func formatLastUpdate(_ date: Date) -> String {
    let now = Date()
    let timeInterval = now.timeIntervalSince(date)

    if timeInterval < 60 {
      return "just now"
    } else if timeInterval < 3600 {
      let minutes = Int(timeInterval / 60)
      return "\(minutes)m ago"
    } else {
      let hours = Int(timeInterval / 3600)
      return "\(hours)h ago"
    }
  }
}

#Preview {
  ContentView()
}
