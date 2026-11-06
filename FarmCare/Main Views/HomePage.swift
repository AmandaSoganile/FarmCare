import SwiftUI
import SwiftData

struct HomePage: View {
    @Query(filter: #Predicate<Animal> { $0.deletedAt == nil }) private var animals: [Animal]
    @State private var showingAddAnimal = false

    private var upcoming: [Animal] {
        animals.filter(\.isVaccinationDueSoon).sorted { $0.nextVaccinationDate < $1.nextVaccinationDate }
    }
    private var overdue: [Animal] {
        animals.filter(\.isVaccinationMissed).sorted { $0.nextVaccinationDate < $1.nextVaccinationDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 12) {
                        Image("FarmCare Transparent").resizable().scaledToFit().frame(width: 54, height: 54)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your farm at a glance").font(.title2.bold())
                            Text("Animals, care and upcoming vaccinations.").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink { AnimalCategories() } label: {
                        FarmCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Total animals").font(.subheadline).foregroundStyle(.secondary)
                                    Text(animals.count, format: .number).font(.system(.largeTitle, design: .rounded).bold())
                                }
                                Spacer()
                                Image(systemName: "pawprint.fill").font(.title).foregroundStyle(FarmStyle.green)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }.buttonStyle(.plain)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 12)], spacing: 12) {
                        ForEach(categories) { category in
                            NavigationLink { SingleAnimalSpecies(category: category) } label: {
                                FarmCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(category.name).font(.caption).foregroundStyle(.secondary)
                                        Text(animals.filter { $0.species == category.species }.count, format: .number)
                                            .font(.system(.title2, design: .rounded).bold())
                                    }
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                    if animals.isEmpty {
                        FarmCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Welcome to your farm", systemImage: "leaf").font(.headline)
                                Text("Add your first animal to see care schedules here.").foregroundStyle(.secondary)
                                Button("Add an animal") { showingAddAnimal = true }.buttonStyle(FarmPrimaryButtonStyle())
                            }
                        }
                    }
                    vaccinationSection("Overdue vaccinations", animals: overdue, isMissed: true,
                                       emptyMessage: "No overdue vaccinations.")
                    vaccinationSection("Upcoming vaccinations", animals: upcoming, isMissed: false,
                                       emptyMessage: "Nothing due in the next 7 days.")
                }
                .padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .background(FarmStyle.background)
            .navigationTitle("FarmCare")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { Settings() } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingAddAnimal) { AddNewAnimal() }
        }
    }

    private func vaccinationSection(_ title: String, animals: [Animal], isMissed: Bool, emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text(animals.count, format: .number).font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            if animals.isEmpty {
                FarmCard {
                    Label(emptyMessage, systemImage: "checkmark.circle")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            } else {
                ForEach(animals) { animal in
                    NavigationLink { AnimalProfile(animal: animal) } label: {
                        VaccinationRow(animal: animal, isMissed: isMissed)
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    HomePage().environmentObject(AuthViewModel()).environmentObject(AnimalSyncService())
        .modelContainer(for: Animal.self, inMemory: true)
}
