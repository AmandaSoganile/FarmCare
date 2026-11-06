import Foundation
import Combine
import SwiftData
import Supabase
import Network

// Tombstones propagate deletions. Dirty revisions protect edits made while an upload is in flight.
@MainActor
final class AnimalSyncService: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var status = "Ready to sync"
    @Published private(set) var lastError: String?
    @Published private(set) var conflicts: [AnimalSyncConflict] = []
    @Published private(set) var lastSuccessfulSync: Date?
    private var context: ModelContext?
    private var userID: UUID?
    private var pending = false
    private var stopped = false
    private let customSync = FarmAnimalSync()
    private var networkMonitor: NWPathMonitor?

    func configure(context: ModelContext, userID: UUID) {
        self.context = context
        self.userID = userID
        stopped = false
        if SupabaseManager.shared.configuration?.backend == .custom {
            conflicts = (try? customSync.conflicts(context: context)) ?? []
            networkMonitor?.cancel()
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { [weak self] path in
                guard path.status == .satisfied else { return }
                Task { @MainActor [weak self] in self?.requestSync() }
            }
            monitor.start(queue: DispatchQueue(label: "FarmCare.Network"))
            networkMonitor = monitor
        }
    }

    func stop() { stopped = true; customSync.stop(); networkMonitor?.cancel(); networkMonitor = nil }

    func resolveConflict(_ id: UUID, keepLocal: Bool) {
        guard let context, !isSyncing else { return }
        do {
            try customSync.resolve(id, keepLocal: keepLocal, context: context)
            conflicts = try customSync.conflicts(context: context)
            requestSync()
        } catch { lastError = error.localizedDescription }
    }

    func requestSync() {
        guard !stopped, let context, let userID else { return }
        Task { await sync(context: context, userID: userID) }
    }

    func sync(context: ModelContext, userID: UUID) async {
        guard !stopped else { return }
        if isSyncing { pending = true; return }
        isSyncing = true
        defer { isSyncing = false }
        repeat {
            pending = false
            do {
                try await performSync(context: context, userID: userID)
                status = conflicts.isEmpty ? "Animals synced" : "\(conflicts.count) conflicts need review"
                lastError = nil
            } catch is CancellationError {
                return
            } catch {
                if SupabaseManager.shared.configuration?.backend == .custom {
                    conflicts = (try? customSync.conflicts(context: context)) ?? conflicts
                }
                lastError = error.localizedDescription
                status = "Changes waiting to sync"
                return
            }
        } while pending && !stopped
    }

    private func performSync(context: ModelContext, userID: UUID) async throws {
        if SupabaseManager.shared.configuration?.backend == .custom {
            lastSuccessfulSync = try await customSync.sync(context: context, userID: userID)
            conflicts = try customSync.conflicts(context: context)
            // A durable request may acknowledge an older local edit after a restart.
            // Stage and send the newer edit before reporting that everything is synced.
            if try context.fetch(FetchDescriptor<Animal>()).contains(where: { $0.needsSync && $0.conflictSnapshot == nil }) {
                pending = true
            }
            return
        }
        guard let client = SupabaseManager.shared.client,
              let configuration = SupabaseManager.shared.configuration else { throw ConfigurationError.missingSettings }
        let session = try await client.auth.session
        guard session.user.id == userID, !stopped else { throw CancellationError() }
        let api = AnimalAPI(configuration: configuration, token: session.accessToken)
        try context.save()
        let local = try context.fetch(FetchDescriptor<Animal>())
        for animal in local where animal.needsSync {
            guard !stopped else { throw CancellationError() }
            let revision = animal.syncRevision
            let record = AnimalRecord(animal: animal, ownerID: userID)
            try await api.upload(record)
            guard !stopped else { throw CancellationError() }
            if animal.syncRevision == revision {
                animal.needsSync = false
                try context.save()
            }
        }
        let remote = try await api.download(ownerID: userID)
        guard !stopped else { throw CancellationError() }
        let current = try context.fetch(FetchDescriptor<Animal>())
        var byID = Dictionary(uniqueKeysWithValues: current.map { ($0.syncID, $0) })
        for record in remote {
            if let animal = byID[record.id] {
                if !animal.needsSync { record.apply(to: animal) }
            } else {
                let animal = record.makeAnimal()
                context.insert(animal)
                byID[record.id] = animal
            }
        }
        try context.save()
    }
}

struct AnimalRecord: Codable {
    let id: UUID
    let owner_id: UUID
    let name: String
    let species: Species
    let breed: String
    let weight: Int
    let feed_type: String
    let feed_schedule: Int
    let vaccination_type: String
    let vaccination_frequency: VaccinationInterval
    let last_vaccination_date: Date
    let notes: String
    let deleted_at: Date?

    init(animal: Animal, ownerID: UUID) {
        id = animal.syncID
        owner_id = ownerID
        name = animal.name
        species = animal.species
        breed = animal.breed
        weight = animal.weight
        feed_type = animal.feedType
        feed_schedule = animal.feedSchedule
        vaccination_type = animal.vaccinationType
        vaccination_frequency = animal.vaccinationFrequency
        last_vaccination_date = animal.lastVaccinationDate
        notes = animal.notes
        deleted_at = animal.deletedAt
    }

    func makeAnimal() -> Animal {
        let animal = Animal(name: name, species: species, breed: breed, weight: weight, feedType: feed_type,
                            feedSchedule: feed_schedule, vaccinationType: vaccination_type,
                            vaccinationFrequency: vaccination_frequency, lastVaccinationDate: last_vaccination_date, notes: notes)
        apply(to: animal)
        return animal
    }

    func apply(to animal: Animal) {
        animal.syncID = id
        animal.name = name
        animal.species = species
        animal.breed = breed
        animal.weight = weight
        animal.feedType = feed_type
        animal.feedSchedule = feed_schedule
        animal.vaccinationType = vaccination_type
        animal.vaccinationFrequency = vaccination_frequency
        animal.lastVaccinationDate = last_vaccination_date
        animal.notes = notes
        animal.deletedAt = deleted_at
        animal.needsSync = false
    }
}

struct AnimalAPI {
    let configuration: BackendConfiguration
    let token: String

    func upload(_ record: AnimalRecord) async throws {
        var request = request()
        request.httpMethod = "POST"
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(record)
        _ = try await send(request)
    }

    func download(ownerID: UUID) async throws -> [AnimalRecord] {
        var result: [AnimalRecord] = []
        var offset = 0
        while true {
            var request = request()
            var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "owner_id", value: "eq.\(ownerID.uuidString)"),
                                     URLQueryItem(name: "order", value: "id.asc")]
            request.url = components.url
            request.setValue("\(offset)-\(offset + 499)", forHTTPHeaderField: "Range")
            request.setValue("count=exact", forHTTPHeaderField: "Prefer")
            let (data, response) = try await send(request)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let value = try decoder.singleValueContainer().decode(String.self)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: value) { return date }
                formatter.formatOptions = [.withInternetDateTime]
                guard let date = formatter.date(from: value) else {
                    throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(), debugDescription: "Invalid server date")
                }
                return date
            }
            let batch = try decoder.decode([AnimalRecord].self, from: data)
            result.append(contentsOf: batch)
            offset += batch.count
            let total = response.value(forHTTPHeaderField: "Content-Range")?.split(separator: "/").last.flatMap { Int($0) }
            if batch.isEmpty || (total.map { offset >= $0 } ?? (batch.count < 500)) { break }
        }
        return result
    }

    private func request() -> URLRequest {
        var request = URLRequest(url: configuration.url.appending(path: "rest/v1/animals"))
        request.timeoutInterval = 30
        request.setValue(configuration.publicKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(response.statusCode) else { throw BackendError.http(response.statusCode) }
        return (data, response)
    }
}

enum BackendError: LocalizedError {
    case http(Int)
    var errorDescription: String? {
        switch self {
        case .http(401): return "Sign in again to reconnect."
        case .http(403): return "Database access was denied. Check the account access policies."
        case .http(404): return "The animals table is unavailable. Apply the database migration."
        case .http(let code): return "Server returned \(code). Check the database setup and retry."
        }
    }
}
