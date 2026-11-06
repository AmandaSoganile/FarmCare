import SwiftUI
import SwiftData

struct AddNewAnimal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var sync: AnimalSyncService
    @State private var selectedSpecies: Species
    @State private var name = ""
    @State private var breed = ""
    @State private var weight = ""
    @State private var feedType = ""
    @State private var feedHours = 6
    @State private var vaccinationType = ""
    @State private var vaccinationFrequency: VaccinationInterval = .sixWeeks
    @State private var vaccinationDate = Date()
    @State private var saveError: String?

    init(initialSpecies: Species = .cow) {
        _selectedSpecies = State(initialValue: initialSpecies)
    }

    private var validWeight: Int? {
        guard let value = Int(weight.trimmingCharacters(in: .whitespacesAndNewlines)), value > 0 else { return nil }
        return value
    }
    private var canSave: Bool {
        [name, breed, feedType, vaccinationType].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } && validWeight != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Label("Animal details", systemImage: "pawprint"),
                        footer: Text("Enter the animal’s current weight in whole kilograms.")) {
                    Picker("Species", selection: $selectedSpecies) {
                        ForEach(Species.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    TextField("Name", text: $name).textInputAutocapitalization(.words)
                    TextField("Breed", text: $breed).textInputAutocapitalization(.words)
                    HStack {
                        TextField("Weight", text: $weight).keyboardType(.numberPad)
                        Text("kg").foregroundStyle(.secondary)
                    }
                }

                Section {
                    TextField("Feed type, e.g. hay", text: $feedType)
                    Picker("Feed every", selection: $feedHours) {
                        ForEach([1, 2, 3, 4, 6, 8, 10, 12, 24], id: \.self) { Text("\($0) hours").tag($0) }
                    }
                } header: { Label("Feeding", systemImage: "leaf") }

                Section(header: Label("Vaccination schedule", systemImage: "calendar"),
                        footer: Text("Use the schedule recommended for this animal by your veterinarian.")) {
                    TextField("Vaccination name", text: $vaccinationType)
                    DatePicker("Last given", selection: $vaccinationDate, in: ...Date(), displayedComponents: .date)
                    Picker("Repeat every", selection: $vaccinationFrequency) {
                        ForEach(VaccinationInterval.allCases) { Text($0.description).tag($0) }
                    }
                }

                Section {
                    Button("Save animal", action: save).buttonStyle(FarmPrimaryButtonStyle())
                        .disabled(!canSave).listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Add Animal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .scrollDismissesKeyboard(.interactively)
            .alert("Could not save animal", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("OK") { saveError = nil }
            } message: { Text(saveError ?? "Please retry.") }
        }
    }

    private func save() {
        guard canSave, let validWeight else { return }
        let animal = Animal(name: name.trimmingCharacters(in: .whitespacesAndNewlines), species: selectedSpecies,
                            breed: breed.trimmingCharacters(in: .whitespacesAndNewlines), weight: validWeight,
                            feedType: feedType.trimmingCharacters(in: .whitespacesAndNewlines), feedSchedule: feedHours,
                            vaccinationType: vaccinationType.trimmingCharacters(in: .whitespacesAndNewlines),
                            vaccinationFrequency: vaccinationFrequency, lastVaccinationDate: vaccinationDate, notes: "")
        context.insert(animal)
        do {
            try context.save()
            sync.requestSync()
            dismiss()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    AddNewAnimal().environmentObject(AnimalSyncService()).modelContainer(for: Animal.self, inMemory: true)
}
