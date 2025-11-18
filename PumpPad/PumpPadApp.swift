import SwiftUI

@main
struct PumpPadApp: App {
    @StateObject private var dataManager = WorkoutDataManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dataManager)
        }
    }
}