import SwiftUI

struct AddPresetView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var presetName = ""
    @State private var presetNotes = ""
    @State private var exercises: [Exercise] = []
    
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
            .navigationTitle("New Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreset()
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
    
    private func savePreset() {
        let newPreset = WorkoutPreset(
            name: presetName,
            exercises: exercises,
            notes: presetNotes
        )
        dataManager.addPreset(newPreset)
        dismiss()
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            
            if !exercise.sets.isEmpty {
                Text("\(exercise.sets.count) sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("No sets added")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AddPresetView()
        .environmentObject(WorkoutDataManager())
}