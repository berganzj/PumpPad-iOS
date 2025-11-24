import SwiftUI

@main
struct PumpPadApp: App {
    let dataManager = WorkoutDataManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dataManager)
        }
    }
}