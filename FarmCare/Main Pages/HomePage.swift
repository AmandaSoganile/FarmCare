//
//  WelcomePage.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI

// Reminder: Add `CaseIterable` to your `Species` enum in animalStruct.swift for this to work.
struct SummaryCard {
    var name: String
    var total: Int
}

struct HomePage: View {
    let animalTotals: [SummaryCard] = Species.allCases.map { species in
        SummaryCard(name: species.rawValue + "s", total: sampleAnimals.filter { $0.species == species }.count)
    }
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 16) {
                Text("Farm Overview")
                    .font(Font.largeTitle.bold())
                
                ZStack{
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width:366, height: 120)
                        .foregroundStyle(.ultraThinMaterial)
                    
                    VStack {
                        Text("Total animals")
                            .font(.system(size: 20, weight: .bold, design: .default))
                        
                        Text("\(sampleAnimals.count)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(animalTotals, id: \.name) { card in
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .frame(width: 140, height: 80)
                                    .foregroundStyle(Color.gray.opacity(0.18))
                                
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
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Upcoming Vaccinations")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    
                    Text("Missed Vaccinations")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    HomePage()
}
