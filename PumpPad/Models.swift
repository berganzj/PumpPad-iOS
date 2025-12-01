import Foundation
import CoreData

// MARK: - Set Model
struct WorkoutSet: Identifiable, Codable {
    let id: UUID
    var targetReps: String // Support for ranges like "10-15" or single numbers
    var actualReps: Int?
    var weight: Double?
    
    init(id: UUID = UUID(), targetReps: String, actualReps: Int? = nil, weight: Double? = nil) {
        self.id = id
        self.targetReps = targetReps
        self.actualReps = actualReps
        self.weight = weight
    }
}

// MARK: - Exercise Model
struct Exercise: Identifiable, Codable {
    let id: UUID
    var name: String
    var sets: [WorkoutSet]
    
    init(id: UUID = UUID(), name: String, sets: [WorkoutSet] = []) {
        self.id = id
        self.name = name
        self.sets = sets
    }
}

// MARK: - Workout Preset Model
struct WorkoutPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var exercises: [Exercise]
    var notes: String
    var dateCreated: Date
    
    init(id: UUID = UUID(), name: String, exercises: [Exercise] = [], notes: String = "") {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.notes = notes
        self.dateCreated = Date()
    }
}

// MARK: - Completed Workout Model
struct CompletedWorkout: Identifiable, Codable {
    let id: UUID
    let presetId: UUID
    let presetName: String
    let exercises: [Exercise] // Contains actual performed data
    let notes: String
    let dateCompleted: Date
    let duration: TimeInterval? // Optional workout duration
    
    init(from preset: WorkoutPreset, exercises: [Exercise], duration: TimeInterval? = nil) {
        self.id = UUID()
        self.presetId = preset.id
        self.presetName = preset.name
        self.exercises = exercises
        self.notes = preset.notes
        self.dateCompleted = Date()
        self.duration = duration
    }
    
    init(id: UUID, presetId: UUID, presetName: String, exercises: [Exercise], notes: String, dateCompleted: Date, duration: TimeInterval?) {
        self.id = id
        self.presetId = presetId
        self.presetName = presetName
        self.exercises = exercises
        self.notes = notes
        self.dateCompleted = dateCompleted
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
    private let migrationKey = "has_migrated_to_coredata_v2"
    
    // Core Data manager (optional - falls back to UserDefaults if Core Data fails)
    private var coreDataManager: CoreDataManager?
    
    init() {
        // Try to initialize Core Data, but fall back to UserDefaults if it fails
        do {
            coreDataManager = CoreDataManager.shared
        } catch {
            print("Core Data initialization failed, using UserDefaults: \(error)")
            coreDataManager = nil
        }
        
        loadData()
        // Add sample data for previews if no data exists
        if presets.isEmpty && completedWorkouts.isEmpty {
            addSampleData()
        }
    }
    
    private func addSampleData() {
        // Add sample preset for preview
        let samplePreset = WorkoutPreset(
            name: "Push Day",
            exercises: [
                Exercise(name: "Bench Press", sets: [
                    WorkoutSet(targetReps: "8-10", weight: 135),
                    WorkoutSet(targetReps: "8-10", weight: 135),
                    WorkoutSet(targetReps: "6-8", weight: 145)
                ]),
                Exercise(name: "Overhead Press", sets: [
                    WorkoutSet(targetReps: "10-12", weight: 95),
                    WorkoutSet(targetReps: "10-12", weight: 95)
                ])
            ],
            notes: "Focus on form and controlled movement"
        )
        presets.append(samplePreset)
        
        // Add sample completed workout
        let completedWorkout = CompletedWorkout(
            from: samplePreset,
            exercises: [
                Exercise(name: "Bench Press", sets: [
                    WorkoutSet(targetReps: "8-10", actualReps: 10, weight: 135),
                    WorkoutSet(targetReps: "8-10", actualReps: 8, weight: 135),
                    WorkoutSet(targetReps: "6-8", actualReps: 6, weight: 145)
                ])
            ],
            duration: 2400 // 40 minutes
        )
        completedWorkouts.append(completedWorkout)
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
    
    // MARK: - Data Persistence (Enhanced with Core Data support)
    private func savePresets() {
        // Try Core Data first, fall back to UserDefaults
        if let coreDataManager = coreDataManager {
            // Save to Core Data
            savePresetsToCoreData()
        } else {
            // Fall back to UserDefaults
            if let data = try? JSONEncoder().encode(presets) {
                UserDefaults.standard.set(data, forKey: presetsKey)
            }
        }
    }
    
    private func saveCompletedWorkouts() {
        // Try Core Data first, fall back to UserDefaults
        if let coreDataManager = coreDataManager {
            // Save to Core Data
            saveCompletedWorkoutsToCoreData()
        } else {
            // Fall back to UserDefaults
            if let data = try? JSONEncoder().encode(completedWorkouts) {
                UserDefaults.standard.set(data, forKey: completedWorkoutsKey)
            }
        }
    }
    
    private func loadData() {
        // Try Core Data first, fall back to UserDefaults
        if let coreDataManager = coreDataManager {
            // Check for migration from UserDefaults
            if !UserDefaults.standard.bool(forKey: migrationKey) {
                migrateFromUserDefaults()
            }
            loadDataFromCoreData()
        } else {
            loadDataFromUserDefaults()
        }
    }
    
    private func loadDataFromUserDefaults() {
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
    
    // MARK: - Core Data Methods (when available)
    private func migrateFromUserDefaults() {
        guard let coreDataManager = coreDataManager else { return }
        
        // Migrate existing UserDefaults data to Core Data
        loadDataFromUserDefaults()
        
        if !presets.isEmpty || !completedWorkouts.isEmpty {
            savePresetsToCoreData()
            saveCompletedWorkoutsToCoreData()
            
            // Clear UserDefaults after successful migration
            UserDefaults.standard.removeObject(forKey: presetsKey)
            UserDefaults.standard.removeObject(forKey: completedWorkoutsKey)
            UserDefaults.standard.set(true, forKey: migrationKey)
        }
    }
    
    private func loadDataFromCoreData() {
        // Implementation would go here when Core Data entities are properly set up
        // For now, fall back to UserDefaults
        loadDataFromUserDefaults()
    }
    
    private func savePresetsToCoreData() {
        // Implementation would go here when Core Data entities are properly set up
        // For now, also save to UserDefaults as backup
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: presetsKey + "_backup")
        }
    }
    
    private func saveCompletedWorkoutsToCoreData() {
        // Implementation would go here when Core Data entities are properly set up
        // For now, also save to UserDefaults as backup
        if let data = try? JSONEncoder().encode(completedWorkouts) {
            UserDefaults.standard.set(data, forKey: completedWorkoutsKey + "_backup")
        }
    }
}