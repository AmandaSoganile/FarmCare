//
//  AnimalCategoryModel.swift
//  FarmCare
//
//  Created by Amanda Soganile on 18/12/2025.
//

import Foundation
import SwiftUI

struct AnimalCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: Image
    let species: Species
}

let categories = [
    AnimalCategory(name: "Cattle", icon: Image("cow"), species: .cow),
    AnimalCategory(name: "Chicken", icon: Image("chicken"), species: .chicken),
    AnimalCategory(name: "Pig", icon: Image("pig"), species: .pig)
]
