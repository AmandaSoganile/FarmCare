//
//  animalStruct.swift
//  FarmCare
//
//  Created by Amanda Soganile on 17/10/2025.
//

import Foundation
import SwiftUI



enum Species {
    case cow
    case chicken
    case pig
    
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
    var feedType: String
    var feedSchedule: Int
    var vaccinationType: String
    var vaccinationFrequency: Int
    
}

let sampleAnimals: [Animal] = [
    Animal(id: UUID(), name: "Bella", species: .cow, breed: "Holstein", feedType: "Grass & Grain", feedSchedule: 3, vaccinationType: "Foot-and-Mouth", vaccinationFrequency: 6),
    Animal(id: UUID(), name: "Molly", species: .cow, breed: "Jersey", feedType: "Hay", feedSchedule: 2, vaccinationType: "Brucellosis", vaccinationFrequency: 12),
    Animal(id: UUID(), name: "Rosie", species: .cow, breed: "Angus", feedType: "Pasture & Corn", feedSchedule: 3, vaccinationType: "Lumpy Skin Disease", vaccinationFrequency: 12),

    Animal(id: UUID(), name: "Coco", species: .chicken, breed: "Leghorn", feedType: "Grains", feedSchedule: 4, vaccinationType: "Newcastle", vaccinationFrequency: 6),
    Animal(id: UUID(), name: "Nugget", species: .chicken, breed: "Rhode Island Red", feedType: "Corn Mix", feedSchedule: 3, vaccinationType: "Infectious Bronchitis", vaccinationFrequency: 6),
    Animal(id: UUID(), name: "Sunny", species: .chicken, breed: "Sussex", feedType: "Layer Mash", feedSchedule: 3, vaccinationType: "Marek’s Disease", vaccinationFrequency: 12),

    Animal(id: UUID(), name: "Bacon", species: .pig, breed: "Yorkshire", feedType: "Pellets", feedSchedule: 3, vaccinationType: "Swine Flu", vaccinationFrequency: 6),
    Animal(id: UUID(), name: "Porky", species: .pig, breed: "Landrace", feedType: "Corn & Soybean", feedSchedule: 3, vaccinationType: "Erysipelas", vaccinationFrequency: 12),
    Animal(id: UUID(), name: "Wilbur", species: .pig, breed: "Duroc", feedType: "Grain Mix", feedSchedule: 2, vaccinationType: "Parvovirus", vaccinationFrequency: 12),
    Animal(id: UUID(), name: "Truffle", species: .pig, breed: "Berkshire", feedType: "Organic Feed", feedSchedule: 2, vaccinationType: "Leptospirosis", vaccinationFrequency: 6)
]

var newAnimals : [Animal] = []

