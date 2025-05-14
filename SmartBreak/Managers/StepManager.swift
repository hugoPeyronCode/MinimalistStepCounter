//
//  StepManager.swift
//  SmartBreak
//
//  Created by Hugo Peyron on 09/05/2025.
//

import SwiftUI
import HealthKit
import WidgetKit

@Observable
class StepManager {
  var todaySteps: Int = 0
  var previousSteps: Int = 0
  var weeklyData: [(date: Date, steps: Int)] = []
  var monthlyData: [(date: Date, steps: Int)] = []
  var yearlyData: [(date: Date, steps: Int)] = []
  var availableYears: [Int] = []
  var selectedYear: Int = Calendar.current.component(.year, from: Date())
  var isRefreshing: Bool = false
  var lastRefreshTime: Date = Date()

  // Goal tracking
  var stepGoal: Int {
    didSet {
      UserDefaults.standard.set(stepGoal, forKey: "stepGoal")
      SharedData.saveStepGoal(stepGoal)
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  var weeklyAverage: Int = 0
  var monthlyAverage: Int = 0
  var yearlyDailyAverage: Int = 0

  let healthStore = HKHealthStore()

  init() {
    // Load saved goal or use default
    self.stepGoal = UserDefaults.standard.integer(forKey: "stepGoal")
    if self.stepGoal == 0 {
      self.stepGoal = 10000 // Default goal
    }

    SharedData.saveStepGoal(self.stepGoal)
    requestAuthorization()
  }

  // Calculate progress percentage toward goal
  var goalProgress: Double {
    guard stepGoal > 0 else { return 0 }
    return min(Double(todaySteps) / Double(stepGoal), 1.0)
  }

  // Check if goal was just reached
  var goalJustReached: Bool {
    previousSteps < stepGoal && todaySteps >= stepGoal
  }

  // Refresh all data using TaskGroup with minimum loading time
  @MainActor
  func refreshAllData() async {
    isRefreshing = true

    // Start tracking time
    let startTime = Date()

    await withTaskGroup(of: Void.self) { group in
      // Fetch today's steps
      group.addTask {
        await self.fetchTodayStepCountAsync()
      }

      // Fetch weekly data
      group.addTask {
        await self.fetchStepDataAsync(forDays: 7)
      }

      // Fetch monthly data
      group.addTask {
        await self.fetchStepDataAsync(forDays: 30)
      }

      // Fetch year data
      group.addTask {
        await self.fetchYearDataAsync(year: self.selectedYear)
      }

      // Wait for all tasks to complete
      await group.waitForAll()
    }

    // Ensure minimum loading time of 1 second
    let elapsedTime = Date().timeIntervalSince(startTime)
    if elapsedTime < 1.0 {
      try? await Task.sleep(nanoseconds: UInt64((1.0 - elapsedTime) * 1_000_000_000))
    }

    lastRefreshTime = Date()
    isRefreshing = false

    // Update widget after refresh
    SharedData.saveStepCount(todaySteps)
    WidgetCenter.shared.reloadAllTimelines()
  }

  func requestAuthorization() {
    print("⚠️ Requesting HealthKit authorization...")
    let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    healthStore.requestAuthorization(toShare: [], read: [stepCountType]) { success, error in
      if success {
        print("✅ HealthKit authorization successful")
        self.setupData()
      } else if let error = error {
        print("❌ HealthKit authorization failed: \(error.localizedDescription)")
      }
    }
  }

  // Async version of fetchTodayStepCount
  private func fetchTodayStepCountAsync() async {
    await withCheckedContinuation { continuation in
      self.fetchTodayStepCount {
        continuation.resume()
      }
    }
  }

  // Async version of fetchStepData
  private func fetchStepDataAsync(forDays days: Int) async {
    await withCheckedContinuation { continuation in
      self.fetchStepData(forDays: days) {
        continuation.resume()
      }
    }
  }

  // Async version of fetchYearData
  private func fetchYearDataAsync(year: Int) async {
    await withCheckedContinuation { continuation in
      self.fetchYearData(year: year) {
        continuation.resume()
      }
    }
  }

  // Original fetchTodayStepCount with completion handler
  func fetchTodayStepCount(completion: (() -> Void)? = nil) {
    let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    let now = Date()
    let startOfDay = Calendar.current.startOfDay(for: now)
    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

    let query = HKStatisticsQuery(
      quantityType: stepCountType,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum
    ) { _, result, error in
      guard let result = result, let sum = result.sumQuantity() else {
        if let error = error {
          print("Failed to fetch today's steps: \(error.localizedDescription)")
        }
        DispatchQueue.main.async {
          completion?()
        }
        return
      }

      let steps = Int(sum.doubleValue(for: HKUnit.count()))
      DispatchQueue.main.async {
        self.previousSteps = self.todaySteps
        self.todaySteps = steps

        // Update widget data
        SharedData.saveStepCount(self.todaySteps)
        WidgetCenter.shared.reloadAllTimelines()

        completion?()
      }
    }

    healthStore.execute(query)
  }

  // Original fetchStepData with completion handler
  func fetchStepData(forDays days: Int, completion: (() -> Void)? = nil) {
    let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let calendar = Calendar.current

    let now = Date()
    let startOfToday = calendar.startOfDay(for: now)
    guard let startDate = calendar.date(byAdding: .day, value: -(days-1), to: startOfToday) else {
      completion?()
      return
    }

    let anchorDate = calendar.startOfDay(for: now)
    let intervalComponents = DateComponents(day: 1)

    let query = HKStatisticsCollectionQuery(
      quantityType: stepCountType,
      quantitySamplePredicate: nil,
      options: .cumulativeSum,
      anchorDate: anchorDate,
      intervalComponents: intervalComponents
    )

    query.initialResultsHandler = { query, result, error in
      guard let result = result else {
        if let error = error {
          print("Failed to fetch data: \(error.localizedDescription)")
        }
        DispatchQueue.main.async {
          completion?()
        }
        return
      }

      var data: [(date: Date, steps: Int)] = []
      var totalSteps = 0

      result.enumerateStatistics(from: startDate, to: now) { statistics, _ in
        let date = statistics.startDate
        var steps = 0

        if let quantity = statistics.sumQuantity() {
          steps = Int(quantity.doubleValue(for: HKUnit.count()))
          totalSteps += steps
        }

        data.append((date: date, steps: steps))
      }

      let average = data.isEmpty ? 0 : totalSteps / data.count

      DispatchQueue.main.async {
        let sortedData = data.sorted(by: { $0.date > $1.date })

        if days <= 7 {
          self.weeklyData = sortedData
          self.weeklyAverage = average
        } else if days <= 30 {
          self.monthlyData = sortedData
          self.monthlyAverage = average
        }
        completion?()
      }
    }

    healthStore.execute(query)
  }

  // Original fetchYearData with completion handler
  func fetchYearData(year: Int, completion: (() -> Void)? = nil) {
    let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let calendar = Calendar.current

    var dateComponents = DateComponents()
    dateComponents.year = year
    dateComponents.month = 1
    dateComponents.day = 1
    guard let startDate = calendar.date(from: dateComponents) else {
      completion?()
      return
    }

    dateComponents.year = year + 1
    guard let endDate = calendar.date(from: dateComponents) else {
      completion?()
      return
    }

    let anchorDate = startDate
    let intervalComponents = DateComponents(month: 1)

    let query = HKStatisticsCollectionQuery(
      quantityType: stepCountType,
      quantitySamplePredicate: nil,
      options: .cumulativeSum,
      anchorDate: anchorDate,
      intervalComponents: intervalComponents
    )

    query.initialResultsHandler = { query, result, error in
      guard let result = result else {
        DispatchQueue.main.async {
          completion?()
        }
        return
      }

      var data: [(date: Date, steps: Int)] = []
      var totalSteps = 0
      var daysCounted = 0

      result.enumerateStatistics(from: startDate, to: min(endDate, Date())) { statistics, _ in
        let date = statistics.startDate
        var steps = 0

        if let quantity = statistics.sumQuantity() {
          steps = Int(quantity.doubleValue(for: HKUnit.count()))
          totalSteps += steps

          let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
          daysCounted += daysInMonth
        }

        data.append((date: date, steps: steps))
      }

      let dailyAverage = daysCounted > 0 ? totalSteps / daysCounted : 0

      DispatchQueue.main.async {
        self.yearlyData = data.sorted(by: { $0.date > $1.date })
        self.yearlyDailyAverage = dailyAverage
        self.selectedYear = year
        completion?()
      }
    }

    healthStore.execute(query)
  }

  // Fetch available years
  func fetchAvailableYears() {
    let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    let earliestSampleQuery = HKSampleQuery(
      sampleType: stepCountType,
      predicate: nil,
      limit: 1,
      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
    ) { _, samples, error in
      guard let earliestSample = samples?.first as? HKQuantitySample else { return }

      let latestSampleQuery = HKSampleQuery(
        sampleType: stepCountType,
        predicate: nil,
        limit: 1,
        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
      ) { _, samples, error in
        guard let latestSample = samples?.first as? HKQuantitySample else { return }

        let calendar = Calendar.current
        let earliestYear = calendar.component(.year, from: earliestSample.startDate)
        let latestYear = calendar.component(.year, from: latestSample.startDate)

        var years: [Int] = []
        for year in earliestYear...latestYear {
          years.append(year)
        }

        DispatchQueue.main.async {
          self.availableYears = years.reversed()
          if !years.isEmpty {
            self.fetchYearData(year: self.selectedYear)
          }
        }
      }

      self.healthStore.execute(latestSampleQuery)
    }

    healthStore.execute(earliestSampleQuery)
  }

  // Start periodic updates
  func startUpdates() {
    Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
      self?.fetchTodayStepCount()
      self?.fetchStepData(forDays: 7)
      self?.fetchStepData(forDays: 30)
    }
  }

  // Initialize all data
  func setupData() {
    fetchTodayStepCount()
    fetchStepData(forDays: 7)
    fetchStepData(forDays: 30)
    fetchAvailableYears()
    startUpdates()
    SharedData.saveStepGoal(stepGoal)
  }

  // Check if steps crossed 100-step threshold for haptic feedback
  func shouldTriggerHaptic() -> Bool {
    let previousHundreds = previousSteps / 100
    let currentHundreds = todaySteps / 100
    return currentHundreds > previousHundreds
  }
}
