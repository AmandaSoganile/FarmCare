import SwiftUI

struct SignUp: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var confirmPassword = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("FarmCare Transparent").resizable().scaledToFit().frame(height: 150)
                VStack(spacing: 8) {
                    Text("Create your account").font(.system(.title, design: .rounded).bold())
                    Text("A little less paperwork. More time on the farm.").foregroundStyle(.secondary)
                }.multilineTextAlignment(.center)
                TextField("Name", text: $viewModel.name).textContentType(.name)
                TextField("Email address", text: $viewModel.email)
                    .keyboardType(.emailAddress).textContentType(.username)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                SecureField("Password (at least 8 characters)", text: $viewModel.password).textContentType(.newPassword)
                SecureField("Confirm password", text: $confirmPassword).textContentType(.newPassword)
                AuthMessages()
                Button {
                    guard confirmPassword == viewModel.password else {
                        viewModel.errorMessage = "Passwords do not match."
                        return
                    }
                    Task {
                        await viewModel.signUpWithEmail(name: viewModel.name, email: viewModel.email, password: viewModel.password)
                        if viewModel.errorMessage == nil { confirmPassword = "" }
                    }
                } label: {
                    Text(viewModel.isLoading ? "Creating account…" : "Sign Up").frame(maxWidth: .infinity)
                }
                .buttonStyle(FarmPrimaryButtonStyle()).disabled(viewModel.isLoading)
                Text("Already registered? Go back to Sign In.").font(.footnote).foregroundStyle(.secondary)
            }
            .textFieldStyle(.roundedBorder)
            .padding(24).frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .background(FarmStyle.background)
        .navigationTitle("Sign Up").navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear { viewModel.errorMessage = nil; viewModel.informationMessage = nil }
    }
}
