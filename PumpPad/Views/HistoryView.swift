import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    private var sortedWorkouts: [CompletedWorkout] {
        dataManager.completedWorkouts.sorted { $0.dateCompleted > $1.dateCompleted }
    }
    
    var body: some View {
        NavigationView {
            List {
                if sortedWorkouts.isEmpty {
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(sortedWorkouts) { workout in
                        NavigationLink(destination: CompletedWorkoutDetailView(workout: workout)) {
                            WorkoutHistoryRowView(workout: workout)
                        }
                    }
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