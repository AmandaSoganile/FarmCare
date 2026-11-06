import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Image("FarmCare Transparent").resizable().scaledToFit().frame(maxWidth: 240)
                        .padding(.top, 36)
                    VStack(spacing: 12) {
                        Text("Care for your farm,\none animal at a time.")
                            .font(.system(.largeTitle, design: .rounded).bold())
                        Text("Keep livestock records and care schedules together.")
                            .font(.body).foregroundStyle(.secondary)
                    }.multilineTextAlignment(.center)
                    HStack(spacing: 18) {
                        Label("Animals", systemImage: "pawprint")
                        Label("Care", systemImage: "leaf")
                    }
                    .font(.subheadline).foregroundStyle(FarmStyle.green)
                    NavigationLink { SignIn() } label: { Text("Get started") }
                        .buttonStyle(FarmPrimaryButtonStyle())
                }
                .padding(24).frame(maxWidth: 480).frame(maxWidth: .infinity)
            }
            .background(FarmStyle.background)
        }
    }
}

#Preview { ContentView().environmentObject(AuthViewModel()) }
