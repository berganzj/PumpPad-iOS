import SwiftUI

struct PresetsView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var showingAddPreset = false
    
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
                    VStack(spacing: 12) {
                        ForEach(dataManager.presets) { preset in
                            NavigationLink(destination: PresetDetailView(preset: preset)) {
                                GlassContainer(cornerRadius: 16, padding: 16) {
                                    PresetRowView(preset: preset)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Workout Presets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPreset = true }) {
                        Image(systemName: "plus")
                    }
                    .glassButton()
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