import SwiftUI

struct EditExerciseView: View {
    @Binding var exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    @State private var exerciseName: String
    @State private var sets: [WorkoutSet]
    
    init(exercise: Binding<Exercise>) {
        self._exercise = exercise
        self._exerciseName = State(initialValue: exercise.wrappedValue.name)
        self._sets = State(initialValue: exercise.wrappedValue.sets)
    }
    
    var body: some View {
        Form {
            Section("Exercise Details") {
                TextField("Exercise Name", text: $exerciseName)
            }
            
            Section("Sets") {
                ForEach(sets.indices, id: \.self) { index in
                    VStack(spacing: 8) {
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.headline)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Target Reps:")
                            TextField("e.g., 10-15 or 12", text: $sets[index].targetReps)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Weight (lbs):")
                            TextField("Optional", value: $sets[index].weight, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteSets)
                
                Button(action: addSet) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Set")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    saveChanges()
                    dismiss()
                }
            }
        }
        .onDisappear {
            saveChanges()
        }
    }
    
    private func addSet() {
        sets.append(WorkoutSet(targetReps: "10"))
    }
    
    private func deleteSets(at offsets: IndexSet) {
        sets.remove(atOffsets: offsets)
    }
    
    private func saveChanges() {
        exercise.name = exerciseName
        exercise.sets = sets
    }
}

#Preview {
    NavigationView {
        EditExerciseView(exercise: .constant(Exercise(name: "Bench Press", sets: [WorkoutSet(targetReps: "10-12", weight: 135)])))
    }
}