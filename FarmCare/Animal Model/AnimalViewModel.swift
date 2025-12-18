//
//  AnimalViewModel.swift
//  FarmCare
//
//  Created by Amanda Soganile on 7/11/2025.
//

import Foundation
import SwiftData
import Combine

@MainActor
class AnimalViewModel: ObservableObject {
    @Published var animals: [Animal] = []
    
    func loadAnimals(context: ModelContext, ownerId: String) {
        do {
            let fetch = FetchDescriptor<Animal>(predicate: #Predicate { $0.ownerID == ownerId})
            animals = try context.fetch(fetch)
        } catch {
            print("Fetch failed: \(error)")
            animals = []
        }
    }
    
    func addAnimal(context: ModelContext, ownerId: String, name: String, species: Species, breed: String, weight: Int, feedType: String, feedSchedule: Int, vaccinationType: String, vaccinationFrequency: VaccinationInterval, lastVaccinationDate: Date = Date(), notes: String = "") async {
        let animal = Animal(name: name, species: species, breed: breed, weight: weight, feedType: feedType, feedSchedule: feedSchedule, vaccinationType: vaccinationType, vaccinationFrequency: vaccinationFrequency, lastVaccinationDate: lastVaccinationDate, notes: notes, ownerID: ownerId)
        context.insert(animal)
        do { try context.save()
            loadAnimals(context: context, ownerId: ownerId)
        } catch {
            print("Save failed: \(error)") }
    }
    
    
    func deleteAnimal(context: ModelContext, animal: Animal, ownerId: String) {
        context.delete(animal)
        do { try context.save()
            loadAnimals(context: context, ownerId: ownerId)
        } catch {
            print("Delete failed: \(error)") }
    }
}
