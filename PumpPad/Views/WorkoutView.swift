import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    var body: some View {
        NavigationView {
            Group {
                if let currentWorkout = dataManager.currentWorkout {
                    ActiveWorkoutView(preset: currentWorkout)
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
                LazyVStack(spacing: 12) {
                    ForEach(dataManager.presets) { preset in
                        Button(action: { dataManager.startWorkout(preset: preset) }) {
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
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            } else {
                Text("No presets available. Create one in the Presets tab.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    WorkoutView()
        .environmentObject(WorkoutDataManager())
}