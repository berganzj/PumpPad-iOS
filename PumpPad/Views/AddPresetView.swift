import SwiftUI

struct AddPresetView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var presetName = ""
    @State private var presetNotes = ""
    @State private var exercises: [Exercise] = []
    
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
                    VStack(spacing: 20) {
                        GlassContainer(cornerRadius: 20, padding: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Workout Details")
                                    .font(.headline)
                                
                                TextField("Preset Name", text: $presetName)
                                    .glassTextField()
                                
                                TextField("Notes (optional)", text: $presetNotes, axis: .vertical)
                                    .lineLimit(3)
                                    .glassTextField()
                            }
                        }
                        
                        GlassContainer(cornerRadius: 20, padding: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Exercises")
                                    .font(.headline)
                                
                                ForEach(exercises.indices, id: \.self) { index in
                                    NavigationLink(destination: EditExerciseView(exercise: $exercises[index])) {
                                        ExerciseRowView(exercise: exercises[index])
                                    }
                                }
                                
                                Button(action: addExercise) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Exercise")
                                    }
                                }
                                .glassButton()
                            }
                        }
                    }
                    .padding()
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
                    .glassButton(isEnabled: !presetName.isEmpty)
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