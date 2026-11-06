import Foundation
import SwiftData

// Exact request bytes are saved before transmission. Retrying after a crash or a
// lost response reuses the same mutation ID and payload, even after further edits.
@Model
final class PendingAnimalMutation {
    @Attribute(.unique) var id: UUID
    var animalID: UUID
    var localRevision: UUID
    var body: Data

    init(id: UUID, animalID: UUID, localRevision: UUID, body: Data) {
        self.id = id
        self.animalID = animalID
        self.localRevision = localRevision
        self.body = body
    }
}

@Model
final class FarmSyncCheckpoint {
    @Attribute(.unique) var key: String = "animals"
    var cursor: String?
    var lastSyncedAt: Date?
    init() { }
}

struct FarmAnimalData: Codable {
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

    init(_ animal: Animal) {
        name = animal.name; species = animal.species; breed = animal.breed; weight = animal.weight
        feed_type = animal.feedType; feed_schedule = animal.feedSchedule
        vaccination_type = animal.vaccinationType; vaccination_frequency = animal.vaccinationFrequency
        last_vaccination_date = animal.lastVaccinationDate; notes = animal.notes
    }

    func makeAnimal() -> Animal {
        Animal(name: name, species: species, breed: breed, weight: weight, feedType: feed_type,
               feedSchedule: feed_schedule, vaccinationType: vaccination_type,
               vaccinationFrequency: vaccination_frequency, lastVaccinationDate: last_vaccination_date, notes: notes)
    }

    func apply(to animal: Animal) {
        animal.name = name; animal.species = species; animal.breed = breed; animal.weight = weight
        animal.feedType = feed_type; animal.feedSchedule = feed_schedule
        animal.vaccinationType = vaccination_type; animal.vaccinationFrequency = vaccination_frequency
        animal.lastVaccinationDate = last_vaccination_date; animal.notes = notes
    }
}

struct FarmRemoteAnimal: Codable {
    let id: UUID
    let revision: Int64
    let deleted: Bool
    let data: FarmAnimalData?

    func apply(to animal: Animal) {
        if !deleted { data?.apply(to: animal) }
        animal.syncID = id
        animal.serverRevision = revision
        animal.deletedAt = deleted ? (animal.deletedAt ?? Date()) : nil
        animal.needsSync = false
        animal.conflictSnapshot = nil
    }
}

private struct FarmMutation: Encodable {
    let mutation_id: UUID
    let record_id: UUID
    let base_revision: Int64
    let operation: String
    let data: FarmAnimalData?
}
private struct FarmPush: Encodable { let mutations: [FarmMutation] }
private struct FarmPushResponse: Decodable {
    struct Result: Decodable { let mutation_id: UUID; let status: String; let record: FarmRemoteAnimal? }
    let results: [Result]
}
private struct FarmPull: Decodable { let changes: [FarmRemoteAnimal]; let cursor: String; let has_more: Bool }

struct AnimalSyncConflict: Identifiable {
    let id: UUID
    let local: FarmAnimalData
    let remote: FarmAnimalData?
    let localDeletion: Bool
}

@MainActor
final class FarmAnimalSync {
    private let api = FarmAPI.shared
    private var generation = UUID()

    func stop() { generation = UUID() }

    private func checkAccount(_ userID: UUID, generation marker: UUID) throws {
        guard marker == generation, api.session?.user.id == userID else { throw CancellationError() }
    }

    var encoder: JSONEncoder {
        let value = JSONEncoder(); value.dateEncodingStrategy = .iso8601; return value
    }

    var decoder: JSONDecoder {
        let value = JSONDecoder()
        value.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: text) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid server date")
            }
            return date
        }
        return value
    }

    func conflicts(context: ModelContext) throws -> [AnimalSyncConflict] {
        try context.fetch(FetchDescriptor<Animal>()).compactMap { animal in
            guard let saved = animal.conflictSnapshot else { return nil }
            let remote = try decoder.decode(FarmRemoteAnimal.self, from: saved)
            return AnimalSyncConflict(id: animal.syncID, local: FarmAnimalData(animal), remote: remote.data,
                                      localDeletion: animal.deletedAt != nil)
        }
    }

    func resolve(_ id: UUID, keepLocal: Bool, context: ModelContext) throws {
        guard let animal = try context.fetch(FetchDescriptor<Animal>()).first(where: { $0.syncID == id }),
              let saved = animal.conflictSnapshot else { return }
        let remote = try decoder.decode(FarmRemoteAnimal.self, from: saved)
        if keepLocal && !remote.deleted {
            animal.serverRevision = remote.revision
            animal.conflictSnapshot = nil
            animal.markChanged()
        } else if remote.data == nil && !remote.deleted {
            // The server has no record. Discarding the local version hides it locally.
            animal.deletedAt = Date()
            animal.serverRevision = 0
            animal.needsSync = false
            animal.conflictSnapshot = nil
        } else { remote.apply(to: animal) }
        try context.save()
    }

    func sync(context: ModelContext, userID: UUID) async throws -> Date? {
        let marker = generation
        try checkAccount(userID, generation: marker)
        let local = try context.fetch(FetchDescriptor<Animal>())
        var queued = try context.fetch(FetchDescriptor<PendingAnimalMutation>())
        let queuedIDs = Set(queued.map(\.animalID))
        for animal in local where animal.needsSync && animal.conflictSnapshot == nil && !queuedIDs.contains(animal.syncID) {
            let id = UUID()
            let mutation = FarmMutation(mutation_id: id, record_id: animal.syncID, base_revision: animal.serverRevision,
                                        operation: animal.deletedAt == nil ? "upsert" : "delete",
                                        data: animal.deletedAt == nil ? FarmAnimalData(animal) : nil)
            let pending = PendingAnimalMutation(id: id, animalID: animal.syncID, localRevision: animal.syncRevision,
                                                body: try encoder.encode(FarmPush(mutations: [mutation])))
            context.insert(pending)
            queued.append(pending)
        }
        try context.save()
        for pending in queued {
            try checkAccount(userID, generation: marker)
            let data = try await api.authorized("v1/sync/push", method: "POST", body: pending.body, retrySafe: true)
            try checkAccount(userID, generation: marker)
            let response = try decoder.decode(FarmPushResponse.self, from: data)
            guard let result = response.results.first, response.results.count == 1,
                  result.mutation_id == pending.id else {
                throw URLError(.cannotParseResponse)
            }
            let remote: FarmRemoteAnimal
            if let record = result.record { remote = record }
            else if result.status == "conflict" {
                remote = FarmRemoteAnimal(id: pending.animalID, revision: 0, deleted: false, data: nil)
            } else { throw URLError(.cannotParseResponse) }
            guard remote.id == pending.animalID else { throw URLError(.cannotParseResponse) }
            if let animal = try context.fetch(FetchDescriptor<Animal>()).first(where: { $0.syncID == pending.animalID }) {
                switch result.status {
                case "applied", "deleted":
                    if remote.deleted || animal.syncRevision == pending.localRevision { remote.apply(to: animal) }
                    else { animal.serverRevision = remote.revision }
                case "conflict":
                    animal.conflictSnapshot = try encoder.encode(remote)
                default: throw URLError(.cannotParseResponse)
                }
            }
            context.delete(pending)
            try context.save()
        }
        let checkpoint: FarmSyncCheckpoint
        if let stored = try context.fetch(FetchDescriptor<FarmSyncCheckpoint>()).first { checkpoint = stored }
        else { checkpoint = FarmSyncCheckpoint(); context.insert(checkpoint) }
        var resetExpiredCursor = false
        while true {
            try checkAccount(userID, generation: marker)
            let query = checkpoint.cursor.map { [URLQueryItem(name: "cursor", value: $0)] } ?? []
            let data: Data
            do { data = try await api.authorized("v1/sync/pull", query: query) }
            catch let error as FarmAPIError where error.code == "INVALID_CURSOR" && !resetExpiredCursor {
                checkpoint.cursor = nil
                try context.save()
                resetExpiredCursor = true
                continue
            }
            try checkAccount(userID, generation: marker)
            let page = try decoder.decode(FarmPull.self, from: data)
            let animals = try context.fetch(FetchDescriptor<Animal>())
            var byID = Dictionary(uniqueKeysWithValues: animals.map { ($0.syncID, $0) })
            for remote in page.changes {
                if let animal = byID[remote.id] {
                    guard remote.revision > animal.serverRevision else { continue }
                    if remote.deleted {
                        remote.apply(to: animal)
                        for mutation in try context.fetch(FetchDescriptor<PendingAnimalMutation>()) where mutation.animalID == animal.syncID {
                            context.delete(mutation)
                        }
                    } else if animal.needsSync { animal.conflictSnapshot = try encoder.encode(remote) }
                    else { remote.apply(to: animal) }
                } else if !remote.deleted, let payload = remote.data {
                    let animal = payload.makeAnimal()
                    remote.apply(to: animal)
                    context.insert(animal)
                    byID[remote.id] = animal
                }
            }
            // Record changes and cursor commit together; never advance past unsaved data.
            checkpoint.cursor = page.cursor
            if !page.has_more { checkpoint.lastSyncedAt = Date() }
            try context.save()
            if !page.has_more { break }
        }
        return checkpoint.lastSyncedAt
    }
}
