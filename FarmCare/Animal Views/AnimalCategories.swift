import SwiftUI
import SwiftData

struct AnimalCategories: View {
    @Query(filter: #Predicate<Animal> { $0.deletedAt == nil }) private var animals: [Animal]
    @State private var showingAddAnimal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Browse your livestock by species.").foregroundStyle(.secondary)
                    ForEach(categories) { category in
                        NavigationLink { SingleAnimalSpecies(category: category) } label: {
                            FarmCard {
                                HStack(spacing: 18) {
                                    Image(category.species.imageResource).resizable().scaledToFit()
                                        .frame(width: 58, height: 58)
                                        .padding(10)
                                        .background(FarmStyle.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(category.name).font(.title3.bold())
                                        let count = animals.filter { $0.species == category.species }.count
                                        Text("\(count) \(count == 1 ? "animal" : "animals")").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }.buttonStyle(.plain)
                    }
                }
                .padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .background(FarmStyle.background)
            .navigationTitle("Animals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddAnimal = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add animal")
                }
            }
            .sheet(isPresented: $showingAddAnimal) { AddNewAnimal() }
        }
    }
}

#Preview {
    AnimalCategories().environmentObject(AnimalSyncService()).modelContainer(for: Animal.self, inMemory: true)
}
