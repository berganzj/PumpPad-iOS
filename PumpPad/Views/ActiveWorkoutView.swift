import SwiftUI

struct ActiveWorkoutView: View {
    let preset: WorkoutPreset
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var workoutExercises: [Exercise]
    @State private var workoutNotes: String
    @State private var showingCompleteAlert = false
    @State private var showingCancelAlert = false
    @State private var showingSaveConfirmation = false
    @State private var startTime: Date
    
    init(preset: WorkoutPreset) {
        self.preset = preset
        self._workoutExercises = State(initialValue: preset.exercises)
        self._workoutNotes = State(initialValue: "")
        self._startTime = State(initialValue: Date())
    }
    
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
                    GlassContainer(cornerRadius: 20, padding: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(preset.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Started: \(startTime, formatter: timeFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !preset.notes.isEmpty {
                                Text("Preset Notes: \(preset.notes)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    GlassContainer(cornerRadius: 20, padding: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Workout Notes")
                                .font(.headline)
                            
                            TextField("Add notes about this workout session...", text: $workoutNotes, axis: .vertical)
                                .lineLimit(3...6)
                                .glassTextField()
                                .onChange(of: workoutNotes) { _, _ in
                                    saveProgress()
                                }
                        }
                    }
            
                    ForEach(workoutExercises.indices, id: \.self) { exerciseIndex in
                        GlassContainer(cornerRadius: 16, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("\(exerciseIndex + 1). \(workoutExercises[exerciseIndex].name)")
                                        .font(.headline)
                                        .foregroundColor(workoutExercises[exerciseIndex].isSkipped ? .secondary : .primary)
                                    
                                    Spacer()
                                    
                                    if workoutExercises[exerciseIndex].isSkipped {
                                        Text("SKIPPED")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.2))
                                            .cornerRadius(6)
                                    }
                                    
                                    Button(action: {
                                        toggleSkipExercise(at: exerciseIndex)
                                    }) {
                                        Image(systemName: workoutExercises[exerciseIndex].isSkipped ? "arrow.uturn.backward" : "xmark.circle")
                                            .foregroundColor(workoutExercises[exerciseIndex].isSkipped ? .blue : .orange)
                                    }
                                }
                                
                                if !workoutExercises[exerciseIndex].isSkipped {
                                    ForEach(workoutExercises[exerciseIndex].sets.indices, id: \.self) { setIndex in
                                        ActiveSetRowView(
                                            set: $workoutExercises[exerciseIndex].sets[setIndex],
                                            setNumber: setIndex + 1
                                        )
                                        .onChange(of: workoutExercises[exerciseIndex].sets[setIndex].actualReps) { _, _ in
                                            saveProgress()
                                        }
                                        .onChange(of: workoutExercises[exerciseIndex].sets[setIndex].weight) { _, _ in
                                            saveProgress()
                                        }
                                    }
                                } else {
                                    Text("Exercise skipped - machine unavailable")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                        }
                    }
                }
                .padding()
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
                HStack {
                    Button(action: {
                        saveProgress()
                        showingSaveConfirmation = true
                    }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .glassButton()
                    
                    Button("Complete") {
                        showingCompleteAlert = true
                    }
                    .glassButton()
                }
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
        .alert("Progress Saved", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your workout progress has been saved. You can safely switch apps.")
        }
        .onAppear {
            // Load from in-progress workout if available
            if let inProgress = dataManager.inProgressWorkout,
               inProgress.presetId == preset.id {
                workoutExercises = inProgress.exercises
                workoutNotes = inProgress.notes
                startTime = inProgress.startTime
            }
            saveProgress() // Auto-save on appear
        }
        .onChange(of: workoutExercises) { _, _ in
            saveProgress() // Auto-save when exercises change
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func saveProgress() {
        dataManager.updateInProgressWorkout(exercises: workoutExercises, notes: workoutNotes)
    }
    
    private func toggleSkipExercise(at index: Int) {
        workoutExercises[index].isSkipped.toggle()
        saveProgress()
    }
    
    private func completeWorkout() {
        let duration = Date().timeIntervalSince(startTime)
        let completedWorkout = CompletedWorkout(
            from: preset,
            exercises: workoutExercises,
            notes: workoutNotes,
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