import SwiftUI
import SwiftData

@main
struct FarmCareApp: App {
    @StateObject private var auth = AuthViewModel()
    @AppStorage("farmcare.appearance") private var appearance = "system"

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let message = auth.configurationError {
                    ContentUnavailableView("Connect FarmCare", systemImage: "server.rack", description: Text(message))
                } else if auth.isRestoringSession {
                    ProgressView("Restoring your session…")
                } else if let userID = auth.userID {
                    AccountView(userID: userID).id(userID)
                } else {
                    ContentView()
                }
            }
            .environmentObject(auth)
            .tint(FarmStyle.green)
            .preferredColorScheme(colorScheme)
        }
    }
}

// Each account gets its own local cache. The original shared store is left untouched.
struct AccountView: View {
    let userID: UUID
    @State private var container: ModelContainer?
    @State private var storeError: String?

    var body: some View {
        Group {
            if let container {
                SyncedTabsView(userID: userID).modelContainer(container)
            } else if let storeError {
                VStack(spacing: 16) {
                    ContentUnavailableView("Could not open your animals", systemImage: "externaldrive.badge.exclamationmark", description: Text(storeError))
                    Button("Retry") { openStore() }
                }
            } else {
                ProgressView("Opening your farm…")
            }
        }
        .task { openStore() }
    }

    private func openStore() {
        do {
            var folder = URL.applicationSupportDirectory.appending(path: "FarmCareAccounts", directoryHint: .isDirectory)
            if let configuration = SupabaseManager.shared.configuration, configuration.backend == .custom {
                // A different backend must not share an existing account cache implicitly.
                let namespace = Data(configuration.url.absoluteString.utf8).base64EncodedString()
                    .replacingOccurrences(of: "/", with: "_")
                folder = folder.appending(path: "custom-\(namespace)", directoryHint: .isDirectory)
            }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appending(path: "\(userID.uuidString).store")
            let configuration = ModelConfiguration(url: url, cloudKitDatabase: .none)
            if SupabaseManager.shared.configuration?.backend == .custom {
                container = try ModelContainer(for: Animal.self, PendingAnimalMutation.self, FarmSyncCheckpoint.self, configurations: configuration)
            } else { container = try ModelContainer(for: Animal.self, configurations: configuration) }
            storeError = nil
        } catch {
            storeError = error.localizedDescription
        }
    }
}

struct SyncedTabsView: View {
    let userID: UUID
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var sync = AnimalSyncService()
    @State private var showingSyncDetails = false
    @State private var showingConflicts = false

    var body: some View {
        TabsView()
            .environmentObject(sync)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    if sync.isSyncing { ProgressView().controlSize(.small) }
                    Button { showingSyncDetails = true } label: {
                        Label(sync.isSyncing ? "Syncing animals…" : (sync.lastError != nil ? "Changes waiting to sync" : sync.status),
                              systemImage: sync.lastError != nil ? "exclamationmark.icloud" : "checkmark.icloud")
                            .font(.caption).multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 8)
                    if !sync.conflicts.isEmpty {
                        Button("Review") { showingConflicts = true }.font(.caption.weight(.semibold))
                    }
                    Button(sync.lastError != nil ? "Retry" : "Sync") { Task { await sync.sync(context: context, userID: userID) } }
                        .font(.caption.weight(.semibold)).disabled(sync.isSyncing)
                }
                .padding(8)
                .background(.regularMaterial)
            }
            .sheet(isPresented: $showingConflicts) { SyncConflictsView().environmentObject(sync) }
            .alert("Animal sync", isPresented: $showingSyncDetails) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(sync.lastError.map { "Your changes are saved on this device. \($0)" } ?? sync.status)
            }
            .task {
                sync.configure(context: context, userID: userID)
                await sync.sync(context: context, userID: userID)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { sync.requestSync() }
            }
            .onDisappear { sync.stop() }
    }
}

struct SyncConflictsView: View {
    @EnvironmentObject private var sync: AnimalSyncService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if sync.conflicts.isEmpty { Text("All conflicts resolved.") }
                ForEach(sync.conflicts) { conflict in
                    Section(conflict.local.name) {
                        Text("This animal changed on another device. Choose which version to keep.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        version("On this device", data: conflict.local)
                        if conflict.localDeletion { Text("This device requested deletion.").foregroundStyle(.red) }
                        if let remote = conflict.remote { version("On the server", data: remote) }
                        else { Text("There is no record on the server. Using the server version will discard this local record.").foregroundStyle(.secondary) }
                        Button("Keep this device’s version") { sync.resolveConflict(conflict.id, keepLocal: true) }
                        Button("Use server version") { sync.resolveConflict(conflict.id, keepLocal: false) }
                    }
                }
                if let error = sync.lastError { Text(error).foregroundStyle(.red) }
            }
            .disabled(sync.isSyncing)
            .navigationTitle("Review changes")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func version(_ title: String, data: FarmAnimalData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text("\(data.name) · \(data.species.rawValue) · \(data.breed) · \(data.weight) kg")
            Text("Feed: \(data.feed_type), \(data.feed_schedule) times daily")
            Text("Vaccination: \(data.vaccination_type), every \(data.vaccination_frequency.rawValue) weeks")
            Text(data.last_vaccination_date, style: .date)
            if !data.notes.isEmpty { Text(data.notes) }
        }.font(.subheadline)
    }
}
