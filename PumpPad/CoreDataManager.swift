import CoreData
import Foundation

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PumpPadDataModel")
        
        // Configure for app updates and data migration
        let storeDescription = container.persistentStoreDescriptions.first!
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        
        container.loadPersistentStores { _, error in
            if let error = error {
                // In production, you should handle this more gracefully
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save Core Data context: \(error)")
            }
        }
    }
    
    // MARK: - Migration from UserDefaults
    func migrateFromUserDefaults() {
        let presetsKey = "workout_presets"
        let completedWorkoutsKey = "completed_workouts"
        let migrationKey = "has_migrated_to_coredata"
        
        // Check if migration has already been done
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }
        
        // Migrate presets
        if let data = UserDefaults.standard.data(forKey: presetsKey),
           let oldPresets = try? JSONDecoder().decode([WorkoutPreset].self, from: data) {
            
            for preset in oldPresets {
                let presetEntity = WorkoutPresetEntity(context: context)
                presetEntity.id = preset.id
                presetEntity.name = preset.name
                presetEntity.notes = preset.notes
                presetEntity.dateCreated = preset.dateCreated
                
                for (index, exercise) in preset.exercises.enumerated() {
                    let exerciseEntity = ExerciseEntity(context: context)
                    exerciseEntity.id = exercise.id
                    exerciseEntity.name = exercise.name
                    exerciseEntity.order = Int16(index)
                    exerciseEntity.workoutPreset = presetEntity
                    
                    for (setIndex, set) in exercise.sets.enumerated() {
                        let setEntity = WorkoutSetEntity(context: context)
                        setEntity.id = set.id
                        setEntity.targetReps = set.targetReps
                        setEntity.weight = set.weight ?? 0
                        setEntity.actualReps = Int16(set.actualReps ?? 0)
                        setEntity.order = Int16(setIndex)
                        setEntity.exercise = exerciseEntity
                    }
                }
            }
        }
        
        // Migrate completed workouts
        if let data = UserDefaults.standard.data(forKey: completedWorkoutsKey),
           let oldWorkouts = try? JSONDecoder().decode([CompletedWorkout].self, from: data) {
            
            for workout in oldWorkouts {
                let workoutEntity = CompletedWorkoutEntity(context: context)
                workoutEntity.id = workout.id
                workoutEntity.presetName = workout.presetName
                workoutEntity.notes = workout.notes
                workoutEntity.dateCompleted = workout.dateCompleted
                workoutEntity.duration = workout.duration ?? 0
                
                for (index, exercise) in workout.exercises.enumerated() {
                    let exerciseEntity = ExerciseEntity(context: context)
                    exerciseEntity.id = exercise.id
                    exerciseEntity.name = exercise.name
                    exerciseEntity.order = Int16(index)
                    exerciseEntity.completedWorkout = workoutEntity
                    
                    for (setIndex, set) in exercise.sets.enumerated() {
                        let setEntity = WorkoutSetEntity(context: context)
                        setEntity.id = set.id
                        setEntity.targetReps = set.targetReps
                        setEntity.weight = set.weight ?? 0
                        setEntity.actualReps = Int16(set.actualReps ?? 0)
                        setEntity.order = Int16(setIndex)
                        setEntity.exercise = exerciseEntity
                    }
                }
            }
        }
        
        save()
        
        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
        
        // Clean up old UserDefaults data
        UserDefaults.standard.removeObject(forKey: presetsKey)
        UserDefaults.standard.removeObject(forKey: completedWorkoutsKey)
    }
}