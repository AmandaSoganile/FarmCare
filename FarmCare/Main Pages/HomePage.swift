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
            NavigationStack{
                ScrollView{
                    Text("Farm Overview")
                        .font(Font.largeTitle.bold())
                    
                    VStack(spacing: 16) {
                        ZStack{
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width:366, height: 120)
                                .foregroundStyle(.ultraThinMaterial)
                            NavigationLink{
                                animalCategories()
                            } label: {
                                HStack{
                                    VStack {
                                        Text("Total animals")
                                            .font(.system(size: 20, weight: .bold, design: .default))
                                        
                                        Text("\(animals.count)")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                    }
                                    .padding(.horizontal,   60)
//                                     Spacer()
                                    
//                                    Image(systemName: "arrowshape.forward.fill")
//                                        .resizable()
//                                        .frame(width:35, height: 30)
//                                        .padding(.horizontal, 25)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(animalTotals, id: \.name) { card in
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 18)
                                                .frame(width: 140, height: 80)
                                                .foregroundStyle(.ultraThinMaterial)
                                            
                                            VStack {
                                                Text(card.name)
                                                    .font(.headline)
                                                Text("\(card.total)")
                                                    .font(.title)
                                                    .fontWeight(.bold)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Divider()
                            
                            Text("Vaccinations")
                                .font(.largeTitle)
                                .fontWeight(.bold)
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
                                            vaccinationRow(animal: animal, isMissed: false)
                                        }
                                    }
                                }
                                
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
                }
            }
        }
    }



#Preview {
    HomePage()
}
