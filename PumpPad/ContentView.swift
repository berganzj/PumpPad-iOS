import SwiftUI

// NOTE: This view is not used in the app - MainTabView is the main interface
// This file exists for reference/legacy purposes
struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .imageScale(.large)
                .foregroundStyle(.orange)
            Text("ContentView - Not Used")
                .font(.title2)
            Text("The app uses MainTabView instead")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    // Show the actual app instead of ContentView
    MainTabView()
        .environmentObject(WorkoutDataManager())
}