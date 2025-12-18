//
//  WelcomePage.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI
import SwiftData



struct SummaryCard {
    var name: String
    var total: Int
}

struct HomePage: View {
    @Query var animals: [Animal]
    @EnvironmentObject var viewModel: AuthViewModel
    let animalVM: AnimalViewModel = AnimalViewModel()
    @Environment(\.modelContext) var modelContext
    @State private var showAdd = false
    
    let category: animalCategory
    
    var animalTotals: [SummaryCard] {
        Species.allCases.map { species in
            SummaryCard(
                name: species.rawValue.capitalized + "s",
                total: animals.filter { $0.species == species }.count
            )
        }
    }
    
    var upcomingVaccinations: [Animal] {
        animals.filter { $0.isVaccinationDueSoon }
    }
    
    var missedVaccinations: [Animal] {
        animals.filter { $0.isVaccinationMissed }
    }
    
    var body: some View {
        ZStack{
            Color.beige.opacity(0.1)
                .ignoresSafeArea()
            
            NavigationStack{
                HStack {
                    Image("FarmCare Transparent")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 65, height: 65)
                    
                    Spacer()
                    
                    Text("FarmCare")
                        .font(.largeTitle.bold())
                    
                    Spacer()
                    
                    NavigationLink(destination: settings()) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .tint(Color.black)

                    }
                }
                .padding()
                ScrollView{
                    
                   
                        Text("Welcome, \(viewModel.name.isEmpty ? "Farmer" : viewModel.name)!")
                            .font(.title2)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            ZStack{
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width:366, height: 120)
                                    .foregroundStyle(Color.init(uiColor: .white))
                                    .shadow(radius: 10)
                                NavigationLink{
                                    animalCategories()
                                } label: {
                                    HStack{
                                        VStack {
                                            Text("Total animals")
                                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                                .foregroundStyle(Color.black)
                                            
                                            
                                            Text("\(animals.count)")
                                                .font(.title3)
                                                .fontWeight(.medium)
                                                .foregroundStyle(Color.black)
                                        }
                                        .padding(.horizontal,   60)
                                        .padding(.horizontal, 25)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(animalTotals, id: \.name) { card in
                                        NavigationLink(destination: singleAnimalSpecies(category: category)) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 18)
                                                    .frame(width: 140, height: 80)
                                                    .foregroundStyle(Color.init(uiColor: .white))
                                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(style: StrokeStyle(lineWidth: 0.5)))
                                                
                                                VStack {
                                                    Text(card.name)
                                                        .font(.headline)
                                                    Text("\(card.total)")
                                                        .font(.title)
                                                        .fontWeight(.bold)
                                                }
                                                .foregroundStyle(Color.primary)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
//                    } else {
//                        Text("Please sign in to view your animals.").foregroundColor(.secondary).padding()
//                    }
                
                    Divider()
                    
                    Text("Vaccinations")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Divider()
                    VStack(alignment: .leading){
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Upcoming Vaccinations")
                                .font(.title)
                                .fontWeight(.semibold)
                            
                            if upcomingVaccinations.isEmpty {
                                Text("No upcoming vaccinations")
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(upcomingVaccinations) { animal in
                                    NavigationLink(destination: animalProfile(animal: animal)){
                                        vaccinationRow(animal: animal, isMissed: false)
                                    }
                                }
                            }
                        }
                        .padding()
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Missed Vaccinations")
                                .font(.title)
                                .fontWeight(.semibold)
                            
                            if missedVaccinations.isEmpty {
                                Text("No missed vaccinations ")
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(missedVaccinations) { animal in
                                    NavigationLink(destination: animalProfile(animal: animal)){
                                        vaccinationRow(animal: animal, isMissed: true)
                                    }
                                }
                            }
                        }
                        .padding()
                        
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
                    .padding(.bottom)
                }
                .navigationBarBackButtonHidden(true)
            }
        }
    }
}


#Preview {
    HomePage(category: .init(name: "Pig", icon: .init("pig"), species: .pig))
        .environmentObject(AuthViewModel())
                    .environmentObject(AnimalViewModel())
                    
                    .modelContainer(for: Animal.self, inMemory: true)
}

