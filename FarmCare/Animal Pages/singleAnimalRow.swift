//
//  singleAnimalRow.swift
//  FarmCare
//
//  Created by Amanda Soganile on 20/10/2025.
//

import SwiftUI

let sampleAnimal = Animal(id: UUID(), name: "Bessie", species: .cow, breed: "Holstein", feedType: "Hay", feedSchedule: 6, vaccinationType: "Rabies", vaccinationFrequency: 12)

struct singleAnimalRow: View {
    let animal: Animal
    
    var body: some View {
        HStack(spacing: 40){
            Image(animal.species.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width:100, height:100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading) {
                Text(animal.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Breed : \(animal.breed)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gray)
            }
            
            
        }
    }
}

#Preview {
   
    singleAnimalRow(animal: sampleAnimal)
}
