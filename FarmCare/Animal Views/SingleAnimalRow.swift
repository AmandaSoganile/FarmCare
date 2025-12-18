//
//  singleAnimalRow.swift
//  FarmCare
//
//  Created by Amanda Soganile on 20/10/2025.
//

import SwiftUI

struct SingleAnimalRow: View {
    let animal: Animal
    
    var body: some View {
        HStack(spacing: 40){
            Image(animal.species.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width:80, height:80)
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
    
    SingleAnimalRow(animal: sampleAnimal)
}
