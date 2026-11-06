import SwiftUI
import SwiftData

struct SingleAnimalSpecies: View {
    @Query(filter: #Predicate<Animal> { $0.deletedAt == nil }) private var animals: [Animal]
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var sync: AnimalSyncService
    @State private var search = ""
    @State private var showingAddAnimal = false
    @State private var saveError: String?
    let category: AnimalCategory

    private var filteredAnimals: [Animal] {
        animals.filter {
            $0.species == category.species &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.breed.localizedCaseInsensitiveContains(search))
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            ForEach(filteredAnimals) { animal in
                NavigationLink { AnimalProfile(animal: animal) } label: { SingleAnimalRow(animal: animal) }
                    .listRowSeparator(.hidden)
                    .listRowBackground(FarmStyle.surface)
            }
            .onDelete(perform: deleteAnimals)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(FarmStyle.background)
        .overlay {
            if filteredAnimals.isEmpty {
                if search.isEmpty {
                    ContentUnavailableView {
                        Label("No animals yet", systemImage: "pawprint")
                    } description: {
                        Text("Add your first animal to this category.")
                    } actions: {
                        Button("Add animal") { showingAddAnimal = true }.buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView.search(text: search)
                }
            }
        }
        .searchable(text: $search, prompt: "Search name or breed")
        .navigationTitle(category.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddAnimal = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add animal")
            }
        }
        .sheet(isPresented: $showingAddAnimal) { AddNewAnimal(initialSpecies: category.species) }
        .alert("Could not delete animal", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? "Please retry.") }
    }

    private func deleteAnimals(_ indexSet: IndexSet) {
        let displayed = filteredAnimals
        for index in indexSet {
            let animal = displayed[index]
            animal.deletedAt = Date()
            animal.markChanged()
        }
        do {
            try context.save()
            sync.requestSync()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SingleAnimalSpecies(category: categories[0])
    }
    .environmentObject(AnimalSyncService())
    .modelContainer(for: Animal.self, inMemory: true)
}
