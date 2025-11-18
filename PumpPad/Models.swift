import Foundation

// MARK: - Set Model
struct WorkoutSet: Identifiable, Codable {
    let id = UUID()
    var targetReps: String // Support for ranges like "10-15" or single numbers
    var actualReps: Int?
    var weight: Double?
    
    init(targetReps: String, actualReps: Int? = nil, weight: Double? = nil) {
        self.targetReps = targetReps
        self.actualReps = actualReps
        self.weight = weight
    }
}

// MARK: - Exercise Model
struct Exercise: Identifiable, Codable {
    let id = UUID()
    var name: String
    var sets: [WorkoutSet]
    
    init(name: String, sets: [WorkoutSet] = []) {
        self.name = name
        self.sets = sets
    }
}

// MARK: - Workout Preset Model
struct WorkoutPreset: Identifiable, Codable {
    var id = UUID()
    var name: String
    var exercises: [Exercise]
    var notes: String
    var dateCreated: Date
    
    init(name: String, exercises: [Exercise] = [], notes: String = "") {
        self.name = name
        self.exercises = exercises
        self.notes = notes
        self.dateCreated = Date()
    }
}

// MARK: - Completed Workout Model
struct CompletedWorkout: Identifiable, Codable {
    let id = UUID()
    let presetId: UUID
    let presetName: String
    let exercises: [Exercise] // Contains actual performed data
    let notes: String
    let dateCompleted: Date
    let duration: TimeInterval? // Optional workout duration
    
    init(from preset: WorkoutPreset, exercises: [Exercise], duration: TimeInterval? = nil) {
        self.presetId = preset.id
        self.presetName = preset.name
        self.exercises = exercises
        self.notes = preset.notes
        self.dateCompleted = Date()
        self.duration = duration
    }
}

// MARK: - Data Manager
class WorkoutDataManager: ObservableObject {
    @Published var presets: [WorkoutPreset] = []
    @Published var completedWorkouts: [CompletedWorkout] = []
    @Published var currentWorkout: WorkoutPreset?
    
    private let presetsKey = "workout_presets"
    private let completedWorkoutsKey = "completed_workouts"
    
    init() {
        loadData()
    }
    
    // MARK: - Preset Management
    func addPreset(_ preset: WorkoutPreset) {
        presets.append(preset)
        savePresets()
    }
    
    func updatePreset(_ preset: WorkoutPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            savePresets()
        }
    }
    
    func deletePreset(_ preset: WorkoutPreset) {
        presets.removeAll { $0.id == preset.id }
        savePresets()
    }
    
    // MARK: - Workout Management
    func startWorkout(preset: WorkoutPreset) {
        currentWorkout = preset
    }
    
    func completeWorkout(_ completedWorkout: CompletedWorkout) {
        completedWorkouts.append(completedWorkout)
        currentWorkout = nil
        saveCompletedWorkouts()
    }
    
    func cancelCurrentWorkout() {
        currentWorkout = nil
    }
    
    // MARK: - Data Persistence
    private func savePresets() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: presetsKey)
        }
    }
    
    private func saveCompletedWorkouts() {
        if let data = try? JSONEncoder().encode(completedWorkouts) {
            UserDefaults.standard.set(data, forKey: completedWorkoutsKey)
        }
    }
    
    private func loadData() {
        // Load presets
        if let data = UserDefaults.standard.data(forKey: presetsKey),
           let presets = try? JSONDecoder().decode([WorkoutPreset].self, from: data) {
            self.presets = presets
        }
        
        // Load completed workouts
        if let data = UserDefaults.standard.data(forKey: completedWorkoutsKey),
           let completedWorkouts = try? JSONDecoder().decode([CompletedWorkout].self, from: data) {
            self.completedWorkouts = completedWorkouts
        }
    }
}