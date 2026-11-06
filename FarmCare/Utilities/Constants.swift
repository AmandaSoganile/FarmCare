import Foundation

struct BackendConfiguration {
    enum Backend: String { case supabase, custom }
    let backend: Backend
    let url: URL
    let publicKey: String

    static func load() throws -> BackendConfiguration {
        let info = Bundle.main.infoDictionary ?? [:]
        let selection = (info["FARMCARE_BACKEND"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if selection == "custom" {
            let host = (info["FARMCARE_API_HOST"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let scheme = (info["FARMCARE_API_SCHEME"] as? String ?? "https").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !host.isEmpty, !host.contains("$("), !host.contains("/"),
                  let url = URL(string: "\(scheme)://\(host)"), let hostname = url.host,
                  url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else {
                throw ConfigurationError.missingSettings
            }
            var allowed = scheme == "https"
            #if DEBUG
            // Plain HTTP is limited to local development in Debug builds.
            let octets = hostname.split(separator: ".").compactMap { Int($0) }
            let isIPv4 = hostname.split(separator: ".").count == 4 && octets.count == 4 && octets.allSatisfy { (0...255).contains($0) }
            let privateIPv4 = isIPv4 && (octets[0] == 10 ||
                (octets[0] == 192 && octets[1] == 168) ||
                (octets[0] == 172 && (16...31).contains(octets[1])))
            let local = hostname == "localhost" || hostname == "127.0.0.1" || hostname.hasSuffix(".local") ||
                privateIPv4
            allowed = allowed || (scheme == "http" && local)
            #endif
            guard allowed else { throw ConfigurationError.missingSettings }
            return BackendConfiguration(backend: .custom, url: url, publicKey: "")
        }
        guard selection.isEmpty || selection.contains("$(") || selection == "supabase" else {
            throw ConfigurationError.missingSettings
        }
        let rawURL = (info["SUPABASE_URL"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let key = (info["SUPABASE_KEY"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let address = rawURL.hasPrefix("https://") ? rawURL : "https://\(rawURL)"
        guard !rawURL.isEmpty, !rawURL.contains("$("), !key.isEmpty, !key.contains("$("),
              let url = URL(string: address), url.scheme == "https", let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
              url.path.isEmpty || url.path == "/" else {
            throw ConfigurationError.missingSettings
        }
        guard !host.contains("your_project_ref"), !host.contains("YOUR_PROJECT_REF") else {
            throw ConfigurationError.missingSettings
        }
        return BackendConfiguration(backend: .supabase, url: url, publicKey: key)
    }
}

enum ConfigurationError: LocalizedError {
    case missingSettings
    var errorDescription: String? {
        "Configure FarmCare/Secrets.xcconfig and rebuild. For the new API, set FARMCARE_BACKEND = custom, FARMCARE_API_HOST, and FARMCARE_API_SCHEME. Existing Supabase configurations remain supported."
    }
}
