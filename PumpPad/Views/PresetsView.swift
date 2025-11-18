import SwiftUI

struct PresetsView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var showingAddPreset = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.presets) { preset in
                    NavigationLink(destination: PresetDetailView(preset: preset)) {
                        PresetRowView(preset: preset)
                    }
                }
                .onDelete(perform: deletePresets)
            }
            .navigationTitle("Workout Presets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPreset = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPreset) {
                AddPresetView()
            }
        }
    }
    
    private func deletePresets(at offsets: IndexSet) {
        for index in offsets {
            dataManager.deletePreset(dataManager.presets[index])
        }
    }
}

struct PresetRowView: View {
    let preset: WorkoutPreset
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(preset.name)
                .font(.headline)
            
            Text("\(preset.exercises.count) exercises")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !preset.notes.isEmpty {
                Text(preset.notes)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    PresetsView()
        .environmentObject(WorkoutDataManager())
}