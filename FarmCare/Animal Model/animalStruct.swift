//
//  animalStruct.swift
//  FarmCare
//
//  Created by Amanda Soganile on 17/10/2025.
//

import Foundation
import SwiftUI
import SwiftData


enum Species: String, CaseIterable, Codable {
    case cow = "Cow"
    case chicken = "Chicken"
    case pig = "Pig"
    
    var imageResource: ImageResource {
        switch self {
        case .cow:
            return .cowHead
        case .chicken:
            return .chickenHead
        case .pig:
            return .pigHead
        }
    }
}

@Model
class Animal {
    var name: String
    var species: Species
    var breed: String
    var weight: Int
    var feedType: String
    var feedSchedule: Int
    var vaccinationType: String
    var vaccinationFrequency: VaccinationInterval
    var lastVaccinationDate: Date
    var notes: String

    init(id: UUID, name: String, species: Species, breed: String, weight: Int, feedType: String, feedSchedule: Int, vaccinationType: String, vaccinationFrequency: VaccinationInterval, lastVaccinationDate: Date, notes: String) {
        self.name = name
        self.species = species
        self.breed = breed
        self.weight = weight
        self.feedType = feedType
        self.feedSchedule = feedSchedule
        self.vaccinationType = vaccinationType
        self.vaccinationFrequency = vaccinationFrequency
        self.lastVaccinationDate = lastVaccinationDate
        self.notes = notes
    }
    
    var nextVaccinationDate: Date {
        vaccinationFrequency.nextVaccinationDate(from: lastVaccinationDate)
    }
    
    var isVaccinationDueSoon: Bool {
        let today = Date()
        if let daysBetween = Calendar.current.dateComponents([.day], from: today, to: nextVaccinationDate).day {
            return daysBetween <= 7 && daysBetween >= 0
        }
        return false
    }
    
    var isVaccinationMissed: Bool {
        nextVaccinationDate < Date()
    }
    
}


enum VaccinationInterval: Int, CaseIterable, Identifiable, Codable {
    case oneWeek = 1
    case twoWeeks = 2
    case threeWeeks = 3
    case fourWeeks = 4
    case sixWeeks = 6
    case eightWeeks = 8
    case twelveWeeks = 12
    case twentyFourWeeks = 24

    var id: Int { self.rawValue }

    var description: String {
        switch self {
        case .oneWeek: return "1 week"
        case .twoWeeks: return "2 weeks"
        case .threeWeeks: return "3 weeks"
        case .fourWeeks: return "4 weeks"
        case .sixWeeks: return "6 weeks"
        case .eightWeeks: return "8 weeks"
        case .twelveWeeks: return "12 weeks"
        case .twentyFourWeeks: return "24 weeks"
        }
    }

    func nextVaccinationDate(from date: Date) -> Date {
        let daysToAdd = self.rawValue * 7
        return Calendar.current.date(byAdding: .day, value: daysToAdd, to: date) ?? date
    }
}


var sampleAnimals: [Animal] = [
    
    Animal(id: UUID(), name: "Bessie", species: .cow, breed: "Holstein", weight: 500, feedType: "Hay", feedSchedule: 2, vaccinationType: "Rabies", vaccinationFrequency: .fourWeeks, lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -24, to: Date())!, notes: "Due soon"),
    
    Animal(id: UUID(), name: "Clucky", species: .chicken, breed: "Leghorn", weight: 5, feedType: "Corn", feedSchedule: 1, vaccinationType: "Newcastle", vaccinationFrequency: .twoWeeks, lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, notes: "Due soon"),
    
    Animal(id: UUID(), name: "Oinky", species: .pig, breed: "Yorkshire", weight: 150, feedType: "Pellets", feedSchedule: 2, vaccinationType: "Swine Flu", vaccinationFrequency: .threeWeeks, lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -17, to: Date())!, notes: "Due soon"),

    Animal(id: UUID(), name: "Daisy", species: .cow, breed: "Guernsey", weight: 520, feedType: "Grass", feedSchedule: 1, vaccinationType: "Foot & Mouth", vaccinationFrequency: .twoWeeks, lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, notes: "Missed last vaccination"),
    
    Animal(id: UUID(), name: "Henrietta", species: .chicken, breed: "Sussex", weight: 7, feedType: "Corn", feedSchedule: 1, vaccinationType: "Newcastle", vaccinationFrequency: .oneWeek, lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, notes: "Overdue"),

    Animal(id: UUID(), name: "MooMoo", species: .cow, breed: "Jersey", weight: 480, feedType: "Grain", feedSchedule: 1, vaccinationType: "Foot & Mouth", vaccinationFrequency: .fourWeeks, lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, notes: "Healthy"),
    
    Animal(id: UUID(), name: "Feathers", species: .chicken, breed: "Rhode Island Red", weight: 6, feedType: "Mixed", feedSchedule: 1, vaccinationType: "Marek's Disease", vaccinationFrequency: .sixWeeks, lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -15, to: Date())!, notes: "Active"),
    
    Animal(id: UUID(), name: "Porky", species: .pig, breed: "Berkshire", weight: 140, feedType: "Hay", feedSchedule: 2, vaccinationType: "Erysipelas", vaccinationFrequency: .twelveWeeks, lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, notes: "On schedule"),
    
    Animal(id: UUID(), name: "Bacon", species: .pig, breed: "Hampshire", weight: 160, feedType: "Mixed", feedSchedule: 2, vaccinationType: "Swine Fever", vaccinationFrequency: .twentyFourWeeks, lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -40, to: Date())!, notes: "Stable"),
    
    Animal(id: UUID(), name: "Buttercup", species: .cow, breed: "Ayrshire", weight: 510, feedType: "Hay & Grain", feedSchedule: 2, vaccinationType: "Rabies", vaccinationFrequency: .eightWeeks, lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, notes: "Routine checkup soon")
]




var newAnimals : [Animal] = []

