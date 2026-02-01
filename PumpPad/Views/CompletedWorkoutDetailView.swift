import SwiftUI

struct CompletedWorkoutDetailView: View {
    let workout: CompletedWorkout
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }
    
    private var durationFormatter: String {
        guard let duration = workout.duration else { return "Unknown" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else {
            return "\(minutes)m \(seconds)s"
        }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(workout.presetName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(dateFormatter.string(from: workout.dateCompleted))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if let _ = workout.duration {
                        Text("Duration: \(durationFormatter)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    if !workout.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Workout Notes:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(workout.notes)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Exercises Completed") {
                ForEach(workout.exercises.indices, id: \.self) { exerciseIndex in
                    CompletedExerciseRowView(
                        exercise: workout.exercises[exerciseIndex],
                        exerciseNumber: exerciseIndex + 1
                    )
                }
            }
            
            Section("Workout Summary") {
                WorkoutSummaryView(workout: workout)
            }
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CompletedExerciseRowView: View {
    let exercise: Exercise
    let exerciseNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(exerciseNumber). \(exercise.name)")
                    .font(.headline)
                    .foregroundColor(exercise.isSkipped ? .secondary : .primary)
                
                if exercise.isSkipped {
                    Spacer()
                    Text("SKIPPED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            
            if exercise.isSkipped {
                Text("Exercise was skipped - machine unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(exercise.sets.indices, id: \.self) { setIndex in
                HStack {
                    Text("Set \(setIndex + 1):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    
                    if let actualReps = exercise.sets[setIndex].actualReps {
                        Text("\(actualReps) reps")
                            .font(.caption)
                    } else {
                        Text("\(exercise.sets[setIndex].targetReps) reps (target)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let weight = exercise.sets[setIndex].weight {
                        Text("@ \(weight, specifier: "%.1f") lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if exercise.sets[setIndex].actualReps != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            }
        }
        .padding(.vertical, 4)
    }
}

struct WorkoutSummaryView: View {
    let workout: CompletedWorkout
    
    private var completedSets: Int {
        workout.exercises.filter { !$0.isSkipped }.flatMap { $0.sets }.count { $0.actualReps != nil }
    }
    
    private var totalSets: Int {
        workout.exercises.filter { !$0.isSkipped }.flatMap { $0.sets }.count
    }
    
    private var skippedExercises: Int {
        workout.exercises.filter { $0.isSkipped }.count
    }
    
    private var totalReps: Int {
        workout.exercises.filter { !$0.isSkipped }.flatMap { $0.sets }.compactMap { $0.actualReps }.reduce(0, +)
    }
    
    private var totalWeight: Double {
        workout.exercises.filter { !$0.isSkipped }.flatMap { $0.sets }.compactMap { set in
            guard let reps = set.actualReps, let weight = set.weight else { return nil }
            return Double(reps) * weight
        }.reduce(0, +)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack {
                    Text("\(completedSets)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Sets Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(totalReps)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(totalWeight, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Volume (lbs)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: Double(completedSets), total: Double(totalSets))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            Text("\(completedSets) of \(totalSets) sets completed")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if skippedExercises > 0 {
                Text("\(skippedExercises) exercise\(skippedExercises == 1 ? "" : "s") skipped")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        CompletedWorkoutDetailView(workout: CompletedWorkout(
            from: WorkoutPreset(name: "Push Day", notes: "Great workout"),
            exercises: [
                Exercise(name: "Bench Press", sets: [
                    WorkoutSet(targetReps: "10", actualReps: 10, weight: 135),
                    WorkoutSet(targetReps: "10", actualReps: 8, weight: 135)
                ])
            ],
            notes: "Felt strong today",
            duration: 3600
        ))
    }
}