import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    var body: some View {
        TabView {
            PresetsView()
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Presets")
                }
            
            WorkoutView()
                .tabItem {
                    Image(systemName: "dumbbell")
                    Text("Workout")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                }
        }
        .environmentObject(dataManager)
    }
}

#Preview {
    MainTabView()
        .environmentObject(WorkoutDataManager())
}