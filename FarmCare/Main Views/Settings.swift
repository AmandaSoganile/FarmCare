import SwiftUI

struct Settings: View {
    @EnvironmentObject private var auth: AuthViewModel
    @AppStorage("farmcare.appearance") private var appearance = "system"
    @State private var confirmLogout = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 44)).foregroundStyle(FarmStyle.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your account").font(.headline)
                        Text(auth.userEmail).font(.subheadline).foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }.padding(.vertical, 8)
            }
            Section("Preferences") {
                Picker(selection: $appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                } label: { Label("Appearance", systemImage: "paintbrush") }
                LabeledContent("Notifications", value: "Planned")
            }
            Section("About FarmCare") {
                Label("Modern tools for traditional farmers", systemImage: "leaf")
                Text("Keep animal records and care schedules together. Changes save on this device before syncing to your account.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Section {
                Button(role: .destructive) { confirmLogout = true } label: {
                    Label(auth.isLoading ? "Signing out…" : "Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }.disabled(auth.isLoading)
                if let error = auth.errorMessage { Text(error).font(.footnote).foregroundStyle(.red) }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .confirmationDialog("Log out? Changes waiting to sync will stay on this device for this account.", isPresented: $confirmLogout, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { Task { await auth.signOut() } }
            Button("Cancel", role: .cancel) { }
        }
    }
}

#Preview { NavigationStack { Settings().environmentObject(AuthViewModel()) } }
