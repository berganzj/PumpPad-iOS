import SwiftUI

struct EditPresetView: View {
    let preset: WorkoutPreset
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var presetName: String
    @State private var presetNotes: String
    @State private var exercises: [Exercise]
    
    init(preset: WorkoutPreset) {
        self.preset = preset
        self._presetName = State(initialValue: preset.name)
        self._presetNotes = State(initialValue: preset.notes)
        self._exercises = State(initialValue: preset.exercises)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Workout Details") {
                    TextField("Preset Name", text: $presetName)
                    TextField("Notes (optional)", text: $presetNotes, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section("Exercises") {
                    ForEach(exercises.indices, id: \.self) { index in
                        NavigationLink(destination: EditExerciseView(exercise: $exercises[index])) {
                            ExerciseRowView(exercise: exercises[index])
                        }
                    }
                    .onDelete(perform: deleteExercises)
                    
                    Button(action: addExercise) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Exercise")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Edit Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(presetName.isEmpty)
                }
            }
        }
    }
    
    private func addExercise() {
        exercises.append(Exercise(name: "New Exercise"))
    }
    
    private func deleteExercises(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }
    
    private func saveChanges() {
        let updatedPreset = WorkoutPreset(
            id: preset.id,
            name: presetName,
            exercises: exercises,
            notes: presetNotes,
            dateCreated: preset.dateCreated
        )
        dataManager.updatePreset(updatedPreset)
        dismiss()
    }
}

// Extension to WorkoutPreset to support updating with ID preservation
extension WorkoutPreset {
    init(id: UUID, name: String, exercises: [Exercise], notes: String, dateCreated: Date) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.notes = notes
        self.dateCreated = dateCreated
    }
}

#Preview {
    EditPresetView(preset: WorkoutPreset(name: "Push Day", notes: "Upper body focus"))
        .environmentObject(WorkoutDataManager())
}