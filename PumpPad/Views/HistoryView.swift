import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    private var sortedWorkouts: [CompletedWorkout] {
        dataManager.completedWorkouts.sorted { $0.dateCompleted > $1.dateCompleted }
    }
    
    var body: some View {
        NavigationView {
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
                    VStack(spacing: 12) {
                        if sortedWorkouts.isEmpty {
                            GlassContainer(cornerRadius: 20, padding: 24) {
                                VStack(spacing: 16) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    
                                    Text("No Workout History")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Complete workouts to see them here")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.vertical, 40)
                        } else {
                            ForEach(sortedWorkouts) { workout in
                                NavigationLink(destination: CompletedWorkoutDetailView(workout: workout)) {
                                    GlassContainer(cornerRadius: 16, padding: 16) {
                                        WorkoutHistoryRowView(workout: workout)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct WorkoutHistoryRowView: View {
    let workout: CompletedWorkout
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(workout.presetName)
                    .font(.headline)
                Spacer()
                Text(dateFormatter.string(from: workout.dateCompleted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("\(workout.exercises.count) exercises completed")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let duration = workout.duration {
                Text("Duration: \(Int(duration / 60))m \(Int(duration.truncatingRemainder(dividingBy: 60)))s")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .environmentObject(WorkoutDataManager())
}