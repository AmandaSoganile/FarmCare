//
//  animal profile.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI

struct animal_profile: View {
    
    let sampleAnimal = Animal(id: UUID(), name: "Bessie", species: .cow, breed: "Holstein", feedType: "Hay", feedSchedule: 6, vaccinationType: "Rabies", vaccinationFrequency: 12)
    
    let animal: Animal
    
    var body: some View {
        
        VStack {
            Text(animal.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            VStack{
                Text("Health Summary:")
                
            }
        }
    }
}

#Preview {
    animal_profile(animal: sampleAnimal)
}
