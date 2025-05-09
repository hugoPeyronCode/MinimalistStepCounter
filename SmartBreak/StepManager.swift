//
//  StepManager.swift
//  SmartBreak
//
//  Created by Hugo Peyron on 09/05/2025.
//

import SwiftUI
import HealthKit

@Observable
class StepManager {
    var todaySteps: Int = 0
    var previousSteps: Int = 0
    var weeklyData: [(date: Date, steps: Int)] = []
    var monthlyData: [(date: Date, steps: Int)] = []
    var yearlyData: [(date: Date, steps: Int)] = []
    var availableYears: [Int] = []
    var selectedYear: Int = Calendar.current.component(.year, from: Date())

    // Goal tracking
    var stepGoal: Int {
        didSet {
            UserDefaults.standard.set(stepGoal, forKey: "stepGoal")
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

    func requestAuthorization() {
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        healthStore.requestAuthorization(toShare: [], read: [stepCountType]) { success, error in
            if success {
                self.setupData()
            } else if let error = error {
                print("Authorization failed with error: \(error.localizedDescription)")
            }
        }
    }

    func fetchTodayStepCount() {
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
                return
            }

            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                self.previousSteps = self.todaySteps
                self.todaySteps = steps
            }
        }

        healthStore.execute(query)
    }

    // Fetch step data for a specific period (week or month)
    func fetchStepData(forDays days: Int) {
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current

        // Get current date and X days ago
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startDate = calendar.date(byAdding: .day, value: -(days-1), to: startOfToday) else { return }

        // Create the query
        let anchorDate = calendar.startOfDay(for: now)

        // Determine interval components
        let intervalComponents = DateComponents(day: 1)  // Always use daily intervals for week/month

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
                return
            }

            var data: [(date: Date, steps: Int)] = []
            var totalSteps = 0

            // Process statistics
            result.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                let date = statistics.startDate
                var steps = 0

                if let quantity = statistics.sumQuantity() {
                    steps = Int(quantity.doubleValue(for: HKUnit.count()))
                    totalSteps += steps
                }

                data.append((date: date, steps: steps))
            }

            // Calculate average
            let average = data.isEmpty ? 0 : totalSteps / data.count

            // Update the published properties on main thread
            DispatchQueue.main.async {
                let sortedData = data.sorted(by: { $0.date > $1.date }) // Most recent first

                // Update appropriate properties based on requested days
                if days <= 7 {
                    self.weeklyData = sortedData
                    self.weeklyAverage = average
                } else if days <= 30 {
                    self.monthlyData = sortedData
                    self.monthlyAverage = average
                }
            }
        }

        healthStore.execute(query)
    }

    // Fetch data for a specific year
    func fetchYearData(year: Int) {
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current

        // Create start and end dates for the year
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = 1
        dateComponents.day = 1
        guard let startDate = calendar.date(from: dateComponents) else { return }

        dateComponents.year = year + 1
        guard let endDate = calendar.date(from: dateComponents) else { return }

        // Create the query
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
            guard let result = result else { return }

            var data: [(date: Date, steps: Int)] = []
            var totalSteps = 0
            var daysCounted = 0

            // Process statistics
            result.enumerateStatistics(from: startDate, to: min(endDate, Date())) { statistics, _ in
                let date = statistics.startDate
                var steps = 0

                if let quantity = statistics.sumQuantity() {
                    steps = Int(quantity.doubleValue(for: HKUnit.count()))
                    totalSteps += steps

                    // Count days in this month with data
                    let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
                    daysCounted += daysInMonth
                }

                data.append((date: date, steps: steps))
            }

            // Calculate daily average (total steps / days in year with data)
            let dailyAverage = daysCounted > 0 ? totalSteps / daysCounted : 0

            DispatchQueue.main.async {
                self.yearlyData = data.sorted(by: { $0.date > $1.date })
                self.yearlyDailyAverage = dailyAverage
                self.selectedYear = year
            }
        }

        healthStore.execute(query)
    }

    // Fetch available years
    func fetchAvailableYears() {
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        // Query for the earliest and latest samples
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
                    self.availableYears = years.reversed() // Most recent first
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
        // Update every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.fetchTodayStepCount()
            self?.fetchStepData(forDays: 7)  // Update weekly
            self?.fetchStepData(forDays: 30) // Update monthly
            // Year doesn't need frequent updates
        }
    }

    // Initialize all data
    func setupData() {
        fetchTodayStepCount()
        fetchStepData(forDays: 7)    // Week
        fetchStepData(forDays: 30)   // Month
        fetchAvailableYears()        // Get year data
        startUpdates()               // Start periodic updates
    }

    // Check if steps crossed 100-step threshold for haptic feedback
    func shouldTriggerHaptic() -> Bool {
        let previousHundreds = previousSteps / 100
        let currentHundreds = todaySteps / 100
        return currentHundreds > previousHundreds
    }
}
