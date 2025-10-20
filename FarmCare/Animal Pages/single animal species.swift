//
//  animal species tab.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI

struct single_animal_species: View {
    
    let category: animalCategory
    
    var body: some View {
        VStack{
            NavigationSplitView {
                List(sampleAnimals.filter { $0.species == category.species }) { animal in
                    NavigationLink{
                        animal_profile(animal: animal)
                    } label: {
                        singleAnimalRow(animal: animal)
                    }
                }
                .navigationTitle(category.name)
            }detail: {
                Text("Select an animal to view more information")
            }
        }
            
            
            
            
            
        }
        
    }



#Preview {
    single_animal_species(category: animalCategory(name: "Cattle", icon: Image("cow"), species: .cow))
}
