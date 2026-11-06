import SwiftUI
import SwiftData

struct TabsView: View {
    private enum Tab: Hashable { case home, add, animals }
    @State private var selection: Tab = .home
    @State private var previousTab: Tab = .home
    @State private var showingAddAnimal = false

    var body: some View {
        TabView(selection: $selection) {
            HomePage().tag(Tab.home)
                .tabItem { Label("Home", systemImage: "house") }
            Color.clear.tag(Tab.add)
                .tabItem { Label("Add", systemImage: "plus.circle") }
            AnimalCategories().tag(Tab.animals)
                .tabItem { Label("Animals", systemImage: "pawprint") }
        }
        .tint(FarmStyle.green)
        .onChange(of: selection) { _, tab in
            if tab == .add {
                selection = previousTab
                showingAddAnimal = true
            } else {
                previousTab = tab
            }
        }
        .sheet(isPresented: $showingAddAnimal) { AddNewAnimal() }
    }
}

#Preview {
    TabsView().environmentObject(AuthViewModel()).environmentObject(AnimalSyncService())
        .modelContainer(for: Animal.self, inMemory: true)
}
