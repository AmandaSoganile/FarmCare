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
        NavigationStack{
            ZStack{
                VStack{
                    NavigationStack {
                        List(sampleAnimals.filter { $0.species == category.species }) { animal in
                            NavigationLink{
                                animal_profile(animal: animal)
                            } label: {
                                singleAnimalRow(animal: animal)
                            }
                        }
                        .navigationTitle(category.name)
                    }
                }
                
                VStack{
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        NavigationLink{
                            add_New_Animal()
                        } label: {
                            
                            ZStack {
                                Circle()
                                    .frame(width: 60)
                                    .foregroundStyle(Color.black)
                                
                                Image(systemName: "plus")
                                    .resizable()
                                    .foregroundStyle(Color.white)
                                    .frame(width: 25, height: 25)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}



#Preview {
    single_animal_species(category: animalCategory(name: "Cattle", icon: Image("cow"), species: .cow))
}
