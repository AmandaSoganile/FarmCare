//
//  animalStruct.swift
//  FarmCare
//
//  Created by Amanda Soganile on 17/10/2025.
//

import Foundation
import SwiftUI



enum Species: String {
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





struct Animal: Identifiable, Hashable {
    let id: UUID
    var name: String
    var species : Species
    var breed: String
    var weight: Int
    var feedType: String
    var feedSchedule: Int
    var vaccinationType: String
    var vaccinationFrequency: Int
    var notes: String
    
}

var sampleAnimals: [Animal] = [
    Animal(id: UUID(), name: "Bella", species: .cow, breed: "Holstein", weight: 670, feedType: "Grass & Grain", feedSchedule: 3, vaccinationType: "Foot-and-Mouth", vaccinationFrequency: 6, notes: ""),
    Animal(id: UUID(), name: "Molly", species: .cow, breed: "Jersey", weight: 234, feedType: "Hay", feedSchedule: 2, vaccinationType: "Brucellosis", vaccinationFrequency: 12, notes: ""),
    Animal(id: UUID(), name: "Rosie", species: .cow, breed: "Angus", weight: 123, feedType: "Pasture & Corn", feedSchedule: 3, vaccinationType: "Lumpy Skin Disease", vaccinationFrequency: 12, notes: ""),

    Animal(id: UUID(), name: "Coco", species: .chicken, breed: "Leghorn", weight: 23, feedType: "Grains", feedSchedule: 4, vaccinationType: "Newcastle", vaccinationFrequency: 6, notes: ""),
    Animal(id: UUID(), name: "Nugget", species: .chicken, breed: "Rhode Island Red", weight: 22, feedType: "Corn Mix", feedSchedule: 3, vaccinationType: "Infectious Bronchitis", vaccinationFrequency: 6, notes: ""),
    Animal(id: UUID(), name: "Sunny", species: .chicken, breed: "Sussex", weight: 37, feedType: "Layer Mash", feedSchedule: 3, vaccinationType: "Marek’s Disease", vaccinationFrequency: 12, notes: ""),

    Animal(id: UUID(), name: "Bacon", species: .pig, breed: "Yorkshire", weight: 550, feedType: "Pellets", feedSchedule: 3, vaccinationType: "Swine Flu", vaccinationFrequency: 6, notes: ""),
    Animal(id: UUID(), name: "Porky", species: .pig, breed: "Landrace", weight: 645, feedType: "Corn & Soybean", feedSchedule: 3, vaccinationType: "Erysipelas", vaccinationFrequency: 12, notes: ""),
    Animal(id: UUID(), name: "Wilbur", species: .pig, breed: "Duroc", weight: 432, feedType: "Grain Mix", feedSchedule: 2, vaccinationType: "Parvovirus", vaccinationFrequency: 12, notes: ""),
    Animal(id: UUID(), name: "Truffle", species: .pig, breed: "Berkshire", weight: 660, feedType: "Organic Feed", feedSchedule: 2, vaccinationType: "Leptospirosis", vaccinationFrequency: 6, notes: "")
]

var newAnimals : [Animal] = []

