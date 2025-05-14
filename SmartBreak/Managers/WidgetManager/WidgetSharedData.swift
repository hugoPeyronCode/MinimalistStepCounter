// 📄 SharedData.swift
// 📍 Créer dans: SmartBreak (projet principal)
// 🎯 Target: Cocher BOTH SmartBreak AND SmartBreakWidget

import Foundation

struct SharedData {
    static let appGroup = "group.smartbreak.data"
    static let userDefaults = UserDefaults(suiteName: appGroup)

    // Keys for UserDefaults
    static let todayStepsKey = "todaySteps"
    static let stepGoalKey = "stepGoal"
    static let lastUpdateKey = "lastUpdate"

    // Save step count to shared UserDefaults
    static func saveStepCount(_ stepCount: Int) {
        userDefaults?.set(stepCount, forKey: todayStepsKey)
        userDefaults?.set(Date(), forKey: lastUpdateKey)
        print("📱 Widget: Saved \(stepCount) steps")
    }

    // Save step goal to shared UserDefaults
    static func saveStepGoal(_ goal: Int) {
        userDefaults?.set(goal, forKey: stepGoalKey)
        print("📱 Widget: Saved goal \(goal)")
    }

    // Get step count from shared UserDefaults
    static func getStepCount() -> Int {
        let steps = userDefaults?.integer(forKey: todayStepsKey) ?? 0
        print("📱 Widget: Retrieved \(steps) steps")
        return steps
    }

    // Get step goal from shared UserDefaults
    static func getStepGoal() -> Int {
        let goal = userDefaults?.integer(forKey: stepGoalKey) ?? 10000
        print("📱 Widget: Retrieved goal \(goal)")
        return goal
    }

    // Get last update date
    static func getLastUpdate() -> Date {
        return userDefaults?.object(forKey: lastUpdateKey) as? Date ?? Date()
    }

    // Calculate progress percentage
    static func getProgress() -> Double {
        let steps = getStepCount()
        let goal = getStepGoal()
        let progress = goal > 0 ? min(Double(steps) / Double(goal), 1.0) : 0.0
        print("📱 Widget: Progress \(Int(progress * 100))%")
        return progress
    }
}
