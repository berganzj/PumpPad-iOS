import Foundation
import CoreData

// MARK: - Set Model
struct WorkoutSet: Identifiable, Codable, Equatable {
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
struct Exercise: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var sets: [WorkoutSet]
    var isSkipped: Bool // Track if exercise was skipped
    
    init(id: UUID = UUID(), name: String, sets: [WorkoutSet] = [], isSkipped: Bool = false) {
        self.id = id
        self.name = name
        self.sets = sets
        self.isSkipped = isSkipped
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
    
    init(from preset: WorkoutPreset, exercises: [Exercise], notes: String = "", duration: TimeInterval? = nil) {
        self.id = UUID()
        self.presetId = preset.id
        self.presetName = preset.name
        self.exercises = exercises
        self.notes = notes.isEmpty ? preset.notes : notes // Use workout notes if provided, otherwise fall back to preset notes
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

// MARK: - In Progress Workout Model
struct InProgressWorkout: Codable {
    let presetId: UUID
    let presetName: String
    var exercises: [Exercise]
    var notes: String
    let startTime: Date
    
    init(from preset: WorkoutPreset) {
        self.presetId = preset.id
        self.presetName = preset.name
        self.exercises = preset.exercises
        self.notes = ""
        self.startTime = Date()
    }
}

// MARK: - Data Manager
class WorkoutDataManager: ObservableObject {
    @Published var presets: [WorkoutPreset] = []
    @Published var completedWorkouts: [CompletedWorkout] = []
    @Published var currentWorkout: WorkoutPreset?
    @Published var inProgressWorkout: InProgressWorkout?
    
    private let presetsKey = "workout_presets"
    private let completedWorkoutsKey = "completed_workouts"
    private let inProgressWorkoutKey = "in_progress_workout"
    private let migrationKey = "has_migrated_to_coredata_v2"
    
    // Core Data manager (optional - falls back to UserDefaults if Core Data fails)
    private var coreDataManager: CoreDataManager?
    
    init() {
        // Try to initialize Core Data, but fall back to UserDefaults if it fails
        // CoreDataManager.shared is not throwing, so we can assign directly
        coreDataManager = CoreDataManager.shared
        
        loadData()
        loadInProgressWorkout()
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
        inProgressWorkout = InProgressWorkout(from: preset)
        saveInProgressWorkout()
    }
    
    func updateInProgressWorkout(exercises: [Exercise], notes: String) {
        guard var workout = inProgressWorkout else { return }
        workout.exercises = exercises
        workout.notes = notes
        inProgressWorkout = workout
        saveInProgressWorkout()
    }
    
    func completeWorkout(_ completedWorkout: CompletedWorkout) {
        completedWorkouts.append(completedWorkout)
        currentWorkout = nil
        inProgressWorkout = nil
        clearInProgressWorkout()
        saveCompletedWorkouts()
    }
    
    func cancelCurrentWorkout() {
        currentWorkout = nil
        inProgressWorkout = nil
        clearInProgressWorkout()
    }
    
    func resumeInProgressWorkout() -> WorkoutPreset? {
        guard let inProgress = inProgressWorkout,
              let preset = presets.first(where: { $0.id == inProgress.presetId }) else {
            return nil
        }
        currentWorkout = preset
        return preset
    }
    
    // MARK: - Data Persistence (Enhanced with Core Data support)
    // File-based storage URLs in Documents directory
    private var presetsFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("workout_presets.json")
    }
    
    private var completedWorkoutsFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("completed_workouts.json")
    }
    
    private func savePresets() {
        // Save to Documents directory (primary storage - persists across updates)
        do {
            let data = try JSONEncoder().encode(presets)
            try data.write(to: presetsFileURL, options: [.atomicWrite, .completeFileProtection])
            
            // Also save to UserDefaults as backup
            UserDefaults.standard.set(data, forKey: presetsKey)
            
            // Try Core Data if available
            if coreDataManager != nil {
                savePresetsToCoreData()
            }
        } catch {
            print("Failed to save presets: \(error)")
            // Fallback to UserDefaults
            if let data = try? JSONEncoder().encode(presets) {
                UserDefaults.standard.set(data, forKey: presetsKey)
            }
        }
    }
    
    private func saveCompletedWorkouts() {
        // Save to Documents directory (primary storage - persists across updates)
        do {
            let data = try JSONEncoder().encode(completedWorkouts)
            try data.write(to: completedWorkoutsFileURL, options: [.atomicWrite, .completeFileProtection])
            
            // Also save to UserDefaults as backup
            UserDefaults.standard.set(data, forKey: completedWorkoutsKey)
            
            // Try Core Data if available
            if coreDataManager != nil {
                saveCompletedWorkoutsToCoreData()
            }
        } catch {
            print("Failed to save completed workouts: \(error)")
            // Fallback to UserDefaults
            if let data = try? JSONEncoder().encode(completedWorkouts) {
                UserDefaults.standard.set(data, forKey: completedWorkoutsKey)
            }
        }
    }
    
    private func loadData() {
        // Try Core Data first, fall back to UserDefaults
        if coreDataManager != nil {
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
        // Load presets from Documents directory first (primary storage)
        if FileManager.default.fileExists(atPath: presetsFileURL.path),
           let data = try? Data(contentsOf: presetsFileURL),
           let presets = try? JSONDecoder().decode([WorkoutPreset].self, from: data) {
            self.presets = presets
        } else if let data = UserDefaults.standard.data(forKey: presetsKey),
                  let presets = try? JSONDecoder().decode([WorkoutPreset].self, from: data) {
            // Fallback to UserDefaults and migrate
            self.presets = presets
            savePresets() // Migrate to file-based storage
        }
        
        // Load completed workouts from Documents directory first
        if FileManager.default.fileExists(atPath: completedWorkoutsFileURL.path),
           let data = try? Data(contentsOf: completedWorkoutsFileURL),
           let completedWorkouts = try? JSONDecoder().decode([CompletedWorkout].self, from: data) {
            self.completedWorkouts = completedWorkouts
        } else if let data = UserDefaults.standard.data(forKey: completedWorkoutsKey),
                  let completedWorkouts = try? JSONDecoder().decode([CompletedWorkout].self, from: data) {
            // Fallback to UserDefaults and migrate
            self.completedWorkouts = completedWorkouts
            saveCompletedWorkouts() // Migrate to file-based storage
        }
    }
    
    // MARK: - Core Data Methods (when available)
    private func migrateFromUserDefaults() {
        guard coreDataManager != nil else { return }
        
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
    
    // MARK: - In Progress Workout Persistence
    // File-based storage in Documents directory (persists across app updates)
    private var inProgressWorkoutFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("in_progress_workout.json")
    }
    
    private func saveInProgressWorkout() {
        guard let workout = inProgressWorkout else {
            // Clear file if no workout in progress
            try? FileManager.default.removeItem(at: inProgressWorkoutFileURL)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(workout)
            try data.write(to: inProgressWorkoutFileURL, options: [.atomicWrite, .completeFileProtection])
            
            // Also keep UserDefaults as backup
            UserDefaults.standard.set(data, forKey: inProgressWorkoutKey)
        } catch {
            print("Failed to save in-progress workout: \(error)")
            // Fallback to UserDefaults
            if let data = try? JSONEncoder().encode(workout) {
                UserDefaults.standard.set(data, forKey: inProgressWorkoutKey)
            }
        }
    }
    
    private func loadInProgressWorkout() {
        // Try loading from Documents directory first
        if FileManager.default.fileExists(atPath: inProgressWorkoutFileURL.path),
           let data = try? Data(contentsOf: inProgressWorkoutFileURL),
           let workout = try? JSONDecoder().decode(InProgressWorkout.self, from: data) {
            inProgressWorkout = workout
            return
        }
        
        // Fallback to UserDefaults (for migration)
        if let data = UserDefaults.standard.data(forKey: inProgressWorkoutKey),
           let workout = try? JSONDecoder().decode(InProgressWorkout.self, from: data) {
            inProgressWorkout = workout
            // Migrate to file-based storage
            saveInProgressWorkout()
        }
    }
    
    private func clearInProgressWorkout() {
        // Remove file
        try? FileManager.default.removeItem(at: inProgressWorkoutFileURL)
        // Also clear UserDefaults
        UserDefaults.standard.removeObject(forKey: inProgressWorkoutKey)
    }
    
    // MARK: - Backup and Restore
    func createBackup() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backupDirectory = documentsPath.appendingPathComponent("Backups")
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupFolder = backupDirectory.appendingPathComponent("backup_\(timestamp)")
        try FileManager.default.createDirectory(at: backupFolder, withIntermediateDirectories: true)
        
        // Backup presets
        if let presetsData = try? JSONEncoder().encode(presets) {
            try presetsData.write(to: backupFolder.appendingPathComponent("presets.json"))
        }
        
        // Backup completed workouts
        if let workoutsData = try? JSONEncoder().encode(completedWorkouts) {
            try workoutsData.write(to: backupFolder.appendingPathComponent("completed_workouts.json"))
        }
        
        // Backup in-progress workout if exists
        if FileManager.default.fileExists(atPath: inProgressWorkoutFileURL.path) {
            try FileManager.default.copyItem(at: inProgressWorkoutFileURL, to: backupFolder.appendingPathComponent("in_progress_workout.json"))
        }
        
        // Create metadata
        let metadata: [String: Any] = [
            "version": "1.0",
            "timestamp": timestamp,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
        let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
        try metadataData.write(to: backupFolder.appendingPathComponent("backup_info.json"))
        
        return backupFolder
    }
    
    func restoreBackup(from backupFolder: URL) throws {
        // Restore presets
        let presetsFile = backupFolder.appendingPathComponent("presets.json")
        if FileManager.default.fileExists(atPath: presetsFile.path),
           let data = try? Data(contentsOf: presetsFile),
           let restoredPresets = try? JSONDecoder().decode([WorkoutPreset].self, from: data) {
            presets = restoredPresets
            savePresets()
        }
        
        // Restore completed workouts
        let workoutsFile = backupFolder.appendingPathComponent("completed_workouts.json")
        if FileManager.default.fileExists(atPath: workoutsFile.path),
           let data = try? Data(contentsOf: workoutsFile),
           let restoredWorkouts = try? JSONDecoder().decode([CompletedWorkout].self, from: data) {
            completedWorkouts = restoredWorkouts
            saveCompletedWorkouts()
        }
        
        // Restore in-progress workout
        let inProgressFile = backupFolder.appendingPathComponent("in_progress_workout.json")
        if FileManager.default.fileExists(atPath: inProgressFile.path) {
            try FileManager.default.copyItem(at: inProgressFile, to: inProgressWorkoutFileURL)
            loadInProgressWorkout()
        }
    }
}
