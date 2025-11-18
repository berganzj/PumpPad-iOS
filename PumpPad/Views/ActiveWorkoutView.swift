import SwiftUI

struct ActiveWorkoutView: View {
    let preset: WorkoutPreset
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var workoutExercises: [Exercise]
    @State private var showingCompleteAlert = false
    @State private var showingCancelAlert = false
    @State private var startTime: Date
    
    init(preset: WorkoutPreset) {
        self.preset = preset
        self._workoutExercises = State(initialValue: preset.exercises)
        self._startTime = State(initialValue: Date())
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(preset.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Started: \(startTime, formatter: timeFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !preset.notes.isEmpty {
                        Text(preset.notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            ForEach(workoutExercises.indices, id: \.self) { exerciseIndex in
                Section("\(exerciseIndex + 1). \(workoutExercises[exerciseIndex].name)") {
                    ForEach(workoutExercises[exerciseIndex].sets.indices, id: \.self) { setIndex in
                        ActiveSetRowView(
                            set: $workoutExercises[exerciseIndex].sets[setIndex],
                            setNumber: setIndex + 1
                        )
                    }
                }
            }
        }
        .navigationTitle("Active Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    showingCancelAlert = true
                }
                .foregroundColor(.red)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Complete") {
                    showingCompleteAlert = true
                }
                .foregroundColor(.blue)
                .fontWeight(.semibold)
            }
        }
        .alert("Complete Workout?", isPresented: $showingCompleteAlert) {
            Button("Complete") {
                completeWorkout()
            }
            Button("Continue", role: .cancel) { }
        } message: {
            Text("Are you sure you want to complete this workout?")
        }
        .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
            Button("Cancel Workout", role: .destructive) {
                dataManager.cancelCurrentWorkout()
            }
            Button("Continue", role: .cancel) { }
        } message: {
            Text("Are you sure you want to cancel this workout? Your progress will be lost.")
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func completeWorkout() {
        let duration = Date().timeIntervalSince(startTime)
        let completedWorkout = CompletedWorkout(
            from: preset,
            exercises: workoutExercises,
            duration: duration
        )
        dataManager.completeWorkout(completedWorkout)
    }
}

struct ActiveSetRowView: View {
    @Binding var set: WorkoutSet
    let setNumber: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Set \(setNumber)")
                    .font(.headline)
                Spacer()
                Text("Target: \(set.targetReps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Actual Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Reps", value: $set.actualReps, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                VStack(alignment: .leading) {
                    Text("Weight (lbs)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Weight", value: $set.weight, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                }
                
                Spacer()
                
                // Completion indicator
                if set.actualReps != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(set.actualReps != nil ? Color.green.opacity(0.1) : Color.clear)
        )
    }
}

#Preview {
    NavigationView {
        ActiveWorkoutView(preset: WorkoutPreset(
            name: "Push Day",
            exercises: [
                Exercise(name: "Bench Press", sets: [
                    WorkoutSet(targetReps: "8-10", weight: 135),
                    WorkoutSet(targetReps: "8-10", weight: 135)
                ])
            ],
            notes: "Focus on form"
        ))
        .environmentObject(WorkoutDataManager())
    }
}