import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    var body: some View {
        NavigationView {
            Group {
                if let currentWorkout = dataManager.currentWorkout {
                    ActiveWorkoutView(preset: currentWorkout)
                } else if let resumedWorkout = dataManager.resumeInProgressWorkout() {
                    ActiveWorkoutView(preset: resumedWorkout)
                } else {
                    WorkoutSelectionView()
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct WorkoutSelectionView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1),
                    Color.pink.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Select a Preset to Start")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose from your workout presets to begin a new session")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if !dataManager.presets.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(dataManager.presets) { preset in
                                Button(action: { dataManager.startWorkout(preset: preset) }) {
                                    GlassContainer(cornerRadius: 16, padding: 16) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(preset.name)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Text("\(preset.exercises.count) exercises")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "play.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        GlassContainer(cornerRadius: 20, padding: 24) {
                            VStack(spacing: 8) {
                                Text("No presets available")
                                    .font(.headline)
                                Text("Create one in the Presets tab")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    WorkoutView()
        .environmentObject(WorkoutDataManager())
}