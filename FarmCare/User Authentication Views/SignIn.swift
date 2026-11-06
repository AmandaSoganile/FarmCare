import SwiftUI

struct SignIn: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var showPassword = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("FarmCare Transparent").resizable().scaledToFit().frame(height: 150)
                VStack(spacing: 8) {
                    Text("Welcome back").font(.system(.largeTitle, design: .rounded).bold())
                    Text("Sign in to see your animals.").foregroundStyle(.secondary)
                }
                TextField("Email address", text: $viewModel.email)
                    .keyboardType(.emailAddress).textContentType(.username)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                HStack {
                    if showPassword { TextField("Password", text: $viewModel.password) }
                    else { SecureField("Password", text: $viewModel.password).textContentType(.password) }
                    Button { showPassword.toggle() } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                    }.accessibilityLabel(showPassword ? "Hide password" : "Show password")
                }
                AuthMessages()
                Button {
                    Task { await viewModel.signInWithEmail(email: viewModel.email, password: viewModel.password) }
                } label: {
                    Text(viewModel.isLoading ? "Signing in…" : "Sign In").frame(maxWidth: .infinity)
                }
                .buttonStyle(FarmPrimaryButtonStyle()).disabled(viewModel.isLoading)
                if viewModel.usesCustomAPI {
                    NavigationLink("Forgot password?") { AccountEmailView(recovery: true) }
                    NavigationLink("Resend confirmation email") { AccountEmailView(recovery: false) }
                }
                NavigationLink("Create an account") { SignUp() }
            }
            .textFieldStyle(.roundedBorder)
            .padding(24).frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .background(FarmStyle.background)
        .navigationTitle("Sign In").navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear { viewModel.errorMessage = nil }
    }
}

struct AccountEmailView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    let recovery: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(recovery ? "Reset your password" : "Confirm your email")
                .font(.system(.title, design: .rounded).bold())
            Text(recovery
                 ? "Enter your account email. Open the email link to choose a new password, then return here to sign in."
                 : "Enter your account email to request another confirmation link.")
                .foregroundStyle(.secondary)
            TextField("Email address", text: $viewModel.email)
                .keyboardType(.emailAddress).textContentType(.emailAddress)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
            AuthMessages()
            Button {
                Task { await viewModel.sendAccountEmail(recovery: recovery) }
            } label: {
                Text(viewModel.isLoading ? "Sending…" : "Send email").frame(maxWidth: .infinity)
            }
            .buttonStyle(FarmPrimaryButtonStyle()).disabled(viewModel.isLoading)
            Spacer()
        }
        .padding(24).frame(maxWidth: 480).frame(maxWidth: .infinity)
        .background(FarmStyle.background)
        .navigationTitle(recovery ? "Password recovery" : "Email confirmation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.errorMessage = nil; viewModel.informationMessage = nil }
    }
}

struct AuthMessages: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    var body: some View {
        if let error = viewModel.errorMessage {
            Text(error).foregroundStyle(.red).accessibilityLabel("Error: \(error)")
        }
        if let message = viewModel.informationMessage {
            Text(message).foregroundStyle(.secondary)
        }
    }
}
