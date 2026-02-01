import SwiftUI

struct PresetDetailView: View {
    let preset: WorkoutPreset
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var showingEditView = false
    
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
                            
                            if !preset.notes.isEmpty {
                                Text(preset.notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Label("\(preset.exercises.count) exercises", systemImage: "list.bullet")
                                Spacer()
                                Label("Created \(preset.dateCreated, formatter: dateFormatter)", systemImage: "calendar")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    GlassContainer(cornerRadius: 20, padding: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Exercises")
                                .font(.headline)
                            
                            if preset.exercises.isEmpty {
                                Text("No exercises added yet")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(preset.exercises.indices, id: \.self) { index in
                                    ExerciseDetailRowView(exercise: preset.exercises[index], exerciseNumber: index + 1)
                                }
                            }
                        }
                    }
                    
                    Button(action: { dataManager.startWorkout(preset: preset) }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Start This Workout")
                        }
                    }
                    .glassButton()
                }
                .padding()
            }
        }
        .navigationTitle("Preset Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
                .glassButton()
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditPresetView(preset: preset)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

struct ExerciseDetailRowView: View {
    let exercise: Exercise
    let exerciseNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(exerciseNumber). \(exercise.name)")
                .font(.headline)
            
            if exercise.sets.isEmpty {
                Text("No sets configured")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(exercise.sets.indices, id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(exercise.sets[index].targetReps) reps")
                            .font(.caption)
                        
                        if let weight = exercise.sets[index].weight {
                            Text("@ \(weight, specifier: "%.1f") lbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        PresetDetailView(preset: WorkoutPreset(name: "Push Day", exercises: [
            Exercise(name: "Bench Press", sets: [
                WorkoutSet(targetReps: "8-10", weight: 135),
                WorkoutSet(targetReps: "8-10", weight: 135)
            ])
        ], notes: "Focus on form"))
            .environmentObject(WorkoutDataManager())
    }
}