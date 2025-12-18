//
//  WelcomePage.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI
import SwiftData

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
            Color.green.opacity(0.025)
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
                        .fontDesign(.rounded)
                    
                    Spacer()
                    
                    NavigationLink(destination: Settings()) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .tint(Color.black)
                        
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.7))
                
                
                
                ScrollView{
                    VStack(spacing: 16) {
                        ZStack{
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width:366, height: 120)
                                .foregroundStyle(Color(.green).opacity(0.25))
                                .foregroundStyle(.ultraThinMaterial)
                                .shadow(radius: 1)
                                
                            NavigationLink{
                                AnimalCategories()
                            } label: {
                                HStack{
                                    VStack {
                                        Text("Total animals")
                                            .font(.system(size: 20, weight: .bold, design: .default))
                                        
                                        Text("\(animals.count)")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                    }
                                    .padding(.horizontal, 60)
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
                                            .foregroundStyle(Color(.green).opacity(0.25))
                                            .foregroundStyle(.ultraThinMaterial)
                                            .shadow(radius: 1)
                                        
                                        VStack {
                                            Text(card.name)
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .lineLimit(1)
                                                .foregroundStyle(Color(red: 7/255, green: 28/255, blue: 24/255))
                                            Text("\(card.total)")
                                                .font(.title)
                                                .fontWeight(.bold)
                                                .lineLimit(1)
                                                .foregroundStyle(Color(red: 7/255, green: 28/255, blue: 24/255))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(Edge.Set.all, 20)
                        
                        Divider()
                            .padding(.leading)
                        
                        
                        
                        Text("Vaccinations")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .lineLimit(1)
                            .foregroundStyle(Color(red: 7/255, green: 28/255, blue: 24/255))
                        
                        VStack(alignment: .leading){
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Upcoming Vaccinations")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .foregroundStyle(Color(red: 7/255, green: 28/255, blue: 24/255))
                                
                                if upcomingVaccinations.isEmpty {
                                    Text("No upcoming vaccinations")
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(upcomingVaccinations) { animal in
                                        VaccinationRow(animal: animal, isMissed: false)
                                    }
                                }
                            }
                            .padding()
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Missed Vaccinations")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .foregroundStyle(Color(red: 7/255, green: 28/255, blue: 24/255))
                                
                                if missedVaccinations.isEmpty {
                                    Text("No missed vaccinations ")
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(missedVaccinations) { animal in
                                        VaccinationRow(animal: animal, isMissed: true)
                                    }
                                }
                            }
                            .padding()
                        }
                        .padding()
                    }
                    .padding(.bottom)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}


#Preview {
    HomePage()
        .environmentObject(AuthViewModel())
}
