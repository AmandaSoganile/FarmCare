import Foundation
import Combine
import Security

struct FarmUser: Codable {
    let id: UUID
    let email: String
    let name: String
}

struct FarmSession: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int
    let user: FarmUser
    var receivedAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case access_token, refresh_token, expires_in, user, receivedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        access_token = try values.decode(String.self, forKey: .access_token)
        refresh_token = try values.decode(String.self, forKey: .refresh_token)
        expires_in = try values.decode(Int.self, forKey: .expires_in)
        user = try values.decode(FarmUser.self, forKey: .user)
        receivedAt = try values.decodeIfPresent(Date.self, forKey: .receivedAt) ?? Date()
    }
}

struct FarmAPIError: LocalizedError, Decodable {
    let code: String
    let message: String
    let request_id: String?
    let fields: [FieldError]?

    struct FieldError: Decodable { let field: String; let message: String }

    var errorDescription: String? {
        let details = fields?.map { "\($0.field): \($0.message)" }.joined(separator: "\n")
        return [message, details, request_id.map { "Reference: \($0)" }]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n")
    }

    static let signedOut = FarmAPIError(code: "SESSION_EXPIRED", message: "Please sign in again.", request_id: nil, fields: nil)
}

private struct FarmErrorEnvelope: Decodable { let error: FarmAPIError }
struct FarmMessage: Decodable { let message: String }

// Reject redirects: a bearer token must only be sent to the configured API origin.
private final class FarmRedirectPolicy: NSObject, URLSessionTaskDelegate {
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask,
                               willPerformHTTPRedirection response: HTTPURLResponse,
                               newRequest request: URLRequest,
                               completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

@MainActor
final class FarmAPI: ObservableObject {
    static let shared = FarmAPI()
    @Published private(set) var session: FarmSession?
    private let configuration: BackendConfiguration?
    private let transport = URLSession(configuration: .ephemeral, delegate: FarmRedirectPolicy(), delegateQueue: nil)
    private var refreshTask: Task<FarmSession, Error>?
    private var epoch = UUID()
    private var keychainAccount: String { configuration?.url.absoluteString ?? "unconfigured" }

    private init() {
        configuration = try? BackendConfiguration.load()
        if configuration?.backend == .custom {
            // A cached account remains usable offline; server operations still validate its session.
            session = try? JSONDecoder().decode(FarmSession.self, from: readCredentials())
        }
    }

    func login(email: String, password: String) async throws {
        let marker = epoch
        let data = try await send("v1/auth/login", method: "POST", body: json(["email": email, "password": password]))
        let value = try JSONDecoder().decode(FarmSession.self, from: data)
        guard marker == epoch else { throw CancellationError() }
        try save(value)
        epoch = UUID()
        session = value
    }

    func logout() async throws {
        _ = try await authorized("v1/auth/logout", method: "POST")
        try clearCredentials()
    }

    func restore() async throws {
        guard session != nil else { return }
        _ = try await authorized("v1/me")
    }

    func message(_ path: String, values: [String: String]) async throws -> String {
        let data = try await send(path, method: "POST", body: json(values))
        return try JSONDecoder().decode(FarmMessage.self, from: data).message
    }

    func authorized(_ path: String, method: String = "GET", body: Data? = nil,
                    query: [URLQueryItem] = [], retrySafe: Bool = false) async throws -> Data {
        guard var value = session else { throw FarmAPIError.signedOut }
        let marker = epoch
        if value.receivedAt.addingTimeInterval(Double(value.expires_in - 30)) <= Date() {
            value = try await refresh(using: value.refresh_token)
        }
        do {
            let data = try await send(path, method: method, body: body, token: value.access_token, query: query, retrySafe: retrySafe)
            guard marker == epoch else { throw CancellationError() }
            return data
        } catch let error as FarmAPIError where error.code == "SESSION_EXPIRED" {
            guard marker == epoch else { throw CancellationError() }
            value = try await refresh(using: value.refresh_token)
            do {
                let data = try await send(path, method: method, body: body, token: value.access_token, query: query, retrySafe: retrySafe)
                guard marker == epoch else { throw CancellationError() }
                return data
            } catch let error as FarmAPIError where error.code == "SESSION_EXPIRED" {
                if marker == epoch { try clearCredentials() }
                throw error
            }
        }
    }

    private func refresh(using previous: String) async throws -> FarmSession {
        if let refreshTask { return try await refreshTask.value }
        // A concurrent request may already have rotated the token.
        if let session, session.refresh_token != previous { return session }
        let marker = epoch
        let task = Task<FarmSession, Error> {
            do {
                let data = try await send("v1/auth/refresh", method: "POST", body: json(["refresh_token": previous]))
                let value = try JSONDecoder().decode(FarmSession.self, from: data)
                guard marker == epoch else { throw CancellationError() }
                try save(value)
                session = value
                return value
            } catch let error as FarmAPIError where error.code == "SESSION_EXPIRED" {
                if marker == epoch { try clearCredentials() }
                throw error
            }
        }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    private func send(_ path: String, method: String = "GET", body: Data? = nil, token: String? = nil,
                      query: [URLQueryItem] = [], retrySafe: Bool = false) async throws -> Data {
        guard let configuration, configuration.backend == .custom else { throw ConfigurationError.missingSettings }
        var components = URLComponents(url: configuration.url.appending(path: path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw ConfigurationError.missingSettings }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let attempts = retrySafe || method == "GET" ? 3 : 1
        for attempt in 0..<attempts {
            do {
                let (data, response) = try await transport.data(for: request)
                guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                if (200..<300).contains(response.statusCode) { return data }
                if [429, 502, 503, 504].contains(response.statusCode), attempt + 1 < attempts {
                    let requested = retryDelay(response.value(forHTTPHeaderField: "Retry-After"))
                    // Long cooldowns are surfaced rather than retried before Retry-After.
                    if let requested, requested > 30 { throw apiError(data, response: response) }
                    try await pause(attempt, minimum: requested)
                    continue
                }
                throw apiError(data, response: response)
            } catch let error as URLError {
                guard attempt + 1 < attempts, [.timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost].contains(error.code) else { throw error }
                try await pause(attempt)
            }
        }
        throw URLError(.cannotConnectToHost)
    }

    private func apiError(_ data: Data, response: HTTPURLResponse) -> FarmAPIError {
        if let envelope = try? JSONDecoder().decode(FarmErrorEnvelope.self, from: data) { return envelope.error }
        return FarmAPIError(code: response.statusCode == 401 ? "SESSION_EXPIRED" : "HTTP_ERROR",
                            message: "FarmCare returned an unexpected response (\(response.statusCode)). Please retry.",
                            request_id: response.value(forHTTPHeaderField: "X-Request-ID"), fields: nil)
    }

    private func pause(_ attempt: Int, minimum: Double? = nil) async throws {
        let seconds = max(minimum ?? 0, pow(2, Double(attempt)) + Double.random(in: 0...0.5))
        try await Task.sleep(for: .seconds(seconds))
    }

    private func retryDelay(_ header: String?) -> Double? {
        guard let header else { return nil }
        if let seconds = Double(header) { return max(0, seconds) }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: header).map { max(0, $0.timeIntervalSinceNow) }
    }

    private func json(_ value: [String: String]) throws -> Data { try JSONEncoder().encode(value) }

    private var keychainQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "FarmCare.CustomAPI",
         kSecAttrAccount as String: keychainAccount]
    }

    private func readCredentials() throws -> Data {
        var query = keychainQuery
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { throw credentialError() }
        return data
    }

    private func save(_ value: FarmSession) throws {
        let data = try JSONEncoder().encode(value)
        let changes = [kSecValueData as String: data]
        let result = SecItemUpdate(keychainQuery as CFDictionary, changes as CFDictionary)
        if result == errSecItemNotFound {
            var query = keychainQuery
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else { throw credentialError() }
        } else if result != errSecSuccess { throw credentialError() }
    }

    private func clearCredentials() throws {
        let result = SecItemDelete(keychainQuery as CFDictionary)
        guard result == errSecSuccess || result == errSecItemNotFound else { throw credentialError() }
        epoch = UUID()
        session = nil
    }

    private func credentialError() -> FarmAPIError {
        FarmAPIError(code: "KEYCHAIN_ERROR", message: "FarmCare could not access secure sign-in storage. Unlock your device and try again.", request_id: nil, fields: nil)
    }
}
