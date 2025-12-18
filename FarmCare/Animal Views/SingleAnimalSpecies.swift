//
//  animal species tab.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI
import SwiftData

struct SingleAnimalSpecies: View {
    @Query var animals: [Animal]
    @Environment(\.modelContext) private var modelContext
    
    let category: AnimalCategory
    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.6), Color.orange.opacity(0.05)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                VStack{
                    NavigationStack {
                        List {
                            ForEach(animals.filter { $0.species == category.species }) { animal in
                                NavigationLink {
                                    AnimalProfile(animal: animal)
                                } label: {
                                    SingleAnimalRow(animal: animal)
                                }
                            }
                            .onDelete(perform: deleteAnimals)
                        }
                        .navigationTitle(category.name)
                        .scrollContentBackground(.hidden)
                    }
                }
                
                VStack{
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        NavigationLink{
                            AddNewAnimal()
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
    func deleteAnimals(_ indexSet: IndexSet) {
        for index in indexSet {
            let animal = animals[index]
            modelContext.delete(animal)
        }
    }
}





#Preview {
    SingleAnimalSpecies(category: AnimalCategory(name: "Cattle", icon: Image("cow"), species: .cow))
}

