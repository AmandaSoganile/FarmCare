import Foundation
import Supabase

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()
    let configuration: BackendConfiguration?
    let client: SupabaseClient?
    let configurationError: String?

    private init() {
        do {
            let configuration = try BackendConfiguration.load()
            self.configuration = configuration
            client = configuration.backend == .supabase
                ? SupabaseClient(supabaseURL: configuration.url, supabaseKey: configuration.publicKey) : nil
            configurationError = nil
        } catch {
            configuration = nil
            client = nil
            configurationError = error.localizedDescription
        }
    }
}
