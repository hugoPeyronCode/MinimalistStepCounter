import SwiftUI
import HealthKit

struct DebugView: View {
    @State private var authStatus = "Checking..."
    @State private var updateTrigger = false

    var body: some View {
        VStack(spacing: 20) {
            Text("HealthKit Troubleshooter")
                .font(.title)

            Text("Status: \(authStatus)")
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)))

            Button("Request Authorization") {
                requestAuth()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .onAppear {
            checkStatus()
        }
        .onChange(of: updateTrigger) { _, _ in
            checkStatus()
        }
    }

    func checkStatus() {
        if HKHealthStore.isHealthDataAvailable() {
            if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
                let status = HKHealthStore().authorizationStatus(for: stepType)
                switch status {
                case .notDetermined: authStatus = "Not Determined"
                case .sharingDenied: authStatus = "Denied"
                case .sharingAuthorized: authStatus = "Authorized"
                @unknown default: authStatus = "Unknown"
                }
            } else {
                authStatus = "Step Count Type Not Available"
            }
        } else {
            authStatus = "HealthKit Not Available on this Device"
        }

        print("Current status: \(authStatus)")
    }

    func requestAuth() {
        print("🔍 Request auth button pressed")
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available")
            return
        }

        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("❌ Step count type not available")
            return
        }

        let healthStore = HKHealthStore()
        print("⏳ Requesting authorization...")

        healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
            print("🔔 Auth result: success=\(success), error=\(String(describing: error))")

            DispatchQueue.main.async {
                self.updateTrigger.toggle()
            }
        }
    }
}
