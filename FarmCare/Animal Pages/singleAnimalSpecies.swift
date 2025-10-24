//
//  animal species tab.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI
import SwiftData

struct singleAnimalSpecies: View {
@Query var animals: [Animal]
    
    let category: animalCategory
    
    var body: some View {
        NavigationStack{
            ZStack{
                VStack{
                    NavigationStack {
                        List(animals.filter { $0.species == category.species }) { animal in
                            NavigationLink{
                                animalProfile(animal: animal)
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
    singleAnimalSpecies(category: animalCategory(name: "Cattle", icon: Image("cow"), species: .cow))
}
