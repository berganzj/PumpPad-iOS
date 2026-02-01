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
    
    private var gradientBackground: some View {
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
    }
    
    private var headerSection: some View {
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
    }
    
    private var notesSection: some View {
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
    }
    
    private var exercisesList: some View {
        ForEach(workoutExercises.indices, id: \.self) { exerciseIndex in
            exerciseView(at: exerciseIndex)
        }
    }
    
    @ViewBuilder
    private func exerciseView(at index: Int) -> some View {
        GlassContainer(cornerRadius: 16, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                exerciseHeader(at: index)
                
                if !workoutExercises[index].isSkipped {
                    exerciseSets(at: index)
                } else {
                    Text("Exercise skipped - machine unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
    }
    
    private func exerciseHeader(at index: Int) -> some View {
        HStack {
            Text("\(index + 1). \(workoutExercises[index].name)")
                .font(.headline)
                .foregroundColor(workoutExercises[index].isSkipped ? .secondary : .primary)
            
            Spacer()
            
            if workoutExercises[index].isSkipped {
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
                toggleSkipExercise(at: index)
            }) {
                Image(systemName: workoutExercises[index].isSkipped ? "arrow.uturn.backward" : "xmark.circle")
                    .foregroundColor(workoutExercises[index].isSkipped ? .blue : .orange)
            }
        }
    }
    
    private func exerciseSets(at index: Int) -> some View {
        ForEach(workoutExercises[index].sets.indices, id: \.self) { setIndex in
            ActiveSetRowView(
                set: $workoutExercises[index].sets[setIndex],
                setNumber: setIndex + 1
            )
            .onChange(of: workoutExercises[index].sets[setIndex].actualReps) { _, _ in
                saveProgress()
            }
            .onChange(of: workoutExercises[index].sets[setIndex].weight) { _, _ in
                saveProgress()
            }
        }
    }
    
    var body: some View {
        ZStack {
            gradientBackground
            
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    notesSection
                    exercisesList
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