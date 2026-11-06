import Foundation
import Combine
import Supabase
import _Helpers

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var userID: UUID?
    @Published private(set) var userEmail = ""
    @Published private(set) var isRestoringSession = true
    @Published private(set) var isLoading = false
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var errorMessage: String?
    @Published var informationMessage: String?

    var isAuthenticated: Bool { userID != nil }
    var configurationError: String? { SupabaseManager.shared.configurationError }
    var usesCustomAPI: Bool { SupabaseManager.shared.configuration?.backend == .custom }
    private var authTask: Task<Void, Never>?
    private var customSessionSubscription: AnyCancellable?

    init() {
        if SupabaseManager.shared.configuration?.backend == .custom {
            let api = FarmAPI.shared
            customSessionSubscription = api.$session.sink { [weak self] session in
                self?.userID = session?.user.id
                self?.userEmail = session?.user.email ?? ""
            }
            authTask = Task { [weak self] in
                do { try await api.restore() }
                catch {
                    // Keep cached records accessible if restoration fails offline.
                    if api.session != nil { self?.informationMessage = "Working offline. Sync will retry when connected." }
                }
                self?.isRestoringSession = false
            }
            return
        }
        guard let client = SupabaseManager.shared.client else {
            isRestoringSession = false
            return
        }
        authTask = Task { [weak self] in
            for await state in await client.auth.authStateChanges {
                guard !Task.isCancelled else { return }
                self?.apply(state.session)
                self?.isRestoringSession = false
            }
        }
    }

    deinit { authTask?.cancel() }

    private func apply(_ session: Session?) {
        userID = session?.user.id
        userEmail = session?.user.email ?? ""
    }

    func signUpWithEmail(name: String, email: String, password: String) async {
        guard !isLoading else { return }
        errorMessage = nil
        informationMessage = nil
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, validEmail(cleanEmail), password.count >= 8 else {
            errorMessage = "Enter your name, a valid email address, and a password with at least 8 characters."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            if usesCustomAPI {
                informationMessage = try await FarmAPI.shared.message("v1/auth/register", values: [
                    "email": cleanEmail, "name": cleanName, "password": password
                ])
                self.password = ""
                return
            }
            guard let client = SupabaseManager.shared.client else { throw ConfigurationError.missingSettings }
            // A database trigger creates the profile, including when email confirmation is required.
            let response = try await client.auth.signUp(
                email: cleanEmail, password: password, data: ["name": .string(cleanName)]
            )
            apply(response.session)
            self.password = ""
            if response.session == nil {
                informationMessage = "Check your email to confirm your account, then return here and sign in."
            }
        } catch {
            errorMessage = readableError(error)
        }
    }

    func signInWithEmail(email: String, password: String) async {
        guard !isLoading else { return }
        errorMessage = nil
        informationMessage = nil
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validEmail(cleanEmail), !password.isEmpty else {
            errorMessage = "Enter a valid email address and your password."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            if usesCustomAPI {
                try await FarmAPI.shared.login(email: cleanEmail, password: password)
                self.password = ""
                return
            }
            guard let client = SupabaseManager.shared.client else { throw ConfigurationError.missingSettings }
            let session = try await client.auth.signIn(email: cleanEmail, password: password)
            apply(session)
            self.password = ""
        } catch {
            errorMessage = readableError(error)
        }
    }

    func signOut() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            if usesCustomAPI { try await FarmAPI.shared.logout() }
            else {
                guard let client = SupabaseManager.shared.client else { throw ConfigurationError.missingSettings }
                try await client.auth.signOut()
            }
            apply(nil)
            password = ""
            email = ""
            name = ""
            informationMessage = nil
        } catch {
            errorMessage = "Could not sign out: \(readableError(error))"
        }
    }

    func sendAccountEmail(recovery: Bool) async {
        guard !isLoading, usesCustomAPI else { return }
        errorMessage = nil
        informationMessage = nil
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validEmail(cleanEmail) else {
            errorMessage = "Enter a valid email address."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            informationMessage = try await FarmAPI.shared.message(
                recovery ? "v1/auth/forgot-password" : "v1/auth/resend-verification", values: ["email": cleanEmail])
        } catch { errorMessage = readableError(error) }
    }

    private func readableError(_ error: Error) -> String {
        if let auth = error as? AuthError {
            return auth.errorDescription ?? "Sign-in could not be completed. Check your email, password, and project configuration."
        }
        if let network = error as? URLError {
            switch network.code {
            case .cannotFindHost, .dnsLookupFailed:
                return "FarmCare could not find the server. Check the configured API hostname and rebuild."
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
                return "Could not connect to FarmCare. Check your connection and try again."
            default: break
            }
        }
        return error.localizedDescription
    }

    private func validEmail(_ value: String) -> Bool {
        value.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }
}
