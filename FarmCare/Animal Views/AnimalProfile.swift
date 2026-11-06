import SwiftUI
import SwiftData

struct AnimalProfile: View {
    @EnvironmentObject private var sync: AnimalSyncService
    @Environment(\.modelContext) private var context
    @Bindable var animal: Animal
    @State private var isEditing = false
    @State private var showDetails = false
    @State private var notes = ""
    @State private var saveError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FarmCard {
                    HStack(alignment: .top, spacing: 18) {
                        Image(animal.species.imageResource).resizable().scaledToFit()
                            .frame(width: 68, height: 68)
                            .padding(10)
                            .background(FarmStyle.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                        VStack(alignment: .leading, spacing: 8) {
                            Text(animal.name).font(.system(.title, design: .rounded).bold())
                            Text("\(animal.species.rawValue) · \(animal.breed)").font(.subheadline).foregroundStyle(.secondary)
                            AnimalScheduleBadge(animal: animal)
                        }
                        Spacer(minLength: 0)
                    }
                }
                FarmCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Care schedule").font(.headline)
                        Label("\(animal.feedType) · every \(animal.feedSchedule) hours", systemImage: "leaf")
                        Divider()
                        Label(animal.vaccinationType, systemImage: "calendar")
                        LabeledContent("Next vaccination") {
                            Text(animal.nextVaccinationDate, format: .dateTime.day().month().year())
                        }.font(.subheadline)
                    }
                }
                FarmCard {
                    DisclosureGroup("Animal details", isExpanded: $showDetails) {
                        VStack(spacing: 12) {
                            LabeledContent("Species", value: animal.species.rawValue)
                            LabeledContent("Breed", value: animal.breed)
                            LabeledContent("Weight", value: "\(animal.weight) kg")
                            LabeledContent("Vaccination interval", value: animal.vaccinationFrequency.description)
                            LabeledContent("Last vaccination") {
                                Text(animal.lastVaccinationDate, format: .dateTime.day().month().year())
                            }
                        }.font(.subheadline).padding(.top, 16)
                    }.font(.headline)
                }
                FarmCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Notes").font(.headline)
                        if isEditing {
                            TextEditor(text: $notes)
                                .frame(minHeight: 140)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(FarmStyle.background, in: RoundedRectangle(cornerRadius: 12))
                                .accessibilityLabel("Animal notes")
                        } else {
                            Text(animal.notes.isEmpty ? "Record observations and care notes here." : animal.notes)
                                .foregroundStyle(animal.notes.isEmpty ? Color.secondary : Color.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Button(action: editOrSave) {
                            Label(isEditing ? "Save notes" : "Edit notes", systemImage: isEditing ? "checkmark" : "square.and.pencil")
                        }.buttonStyle(FarmPrimaryButtonStyle())
                        if isEditing {
                            Button("Cancel editing", role: .cancel) { isEditing = false }
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .background(FarmStyle.background)
        .navigationTitle("Animal Profile")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .alert("Could not save notes", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? "Please retry.") }
    }

    private func editOrSave() {
        if isEditing {
            animal.notes = notes
            animal.markChanged()
            do {
                try context.save()
                sync.requestSync()
                isEditing = false
            } catch {
                context.rollback()
                saveError = error.localizedDescription
            }
        } else {
            notes = animal.notes
            isEditing = true
        }
    }
}

#Preview {
    NavigationStack { AnimalProfile(animal: sampleAnimal) }
        .environmentObject(AnimalSyncService())
        .modelContainer(for: Animal.self, inMemory: true)
}
