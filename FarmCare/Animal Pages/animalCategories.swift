//
//  animalCategories.swift
//  FarmCare
//
//  Created by Amanda Soganile on 17/10/2025.
//

import SwiftUI

struct animalCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: Image
    let species: Species
}

struct animalCategories: View {
    let categories = [
        animalCategory(name: "Cattle", icon: Image("cow"), species: .cow),
        animalCategory(name: "Chicken", icon: Image("chicken"), species: .chicken),
        animalCategory(name: "Pig", icon: Image("pig"), species: .pig)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 17) {
                    Text("Animal Species")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                    
                    ForEach(categories) { category in
                        NavigationLink(destination: single_animal_species(category: category)) {
                            Text(category.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.black)
                            
                        
                            
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                            )
                            .frame(height: 200)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
            }
            
        }
    }
}


#Preview {
    NavigationStack {
        animalCategories()
    }
}
