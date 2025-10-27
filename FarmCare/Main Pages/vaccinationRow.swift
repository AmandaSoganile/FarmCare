//
//  vaccinationRow.swift
//  FarmCare
//
//  Created by Amanda Soganile on 23/10/2025.
//

import SwiftUI
import SwiftData


struct vaccinationRow: View {
    let sampleAnimal = Animal( name: "Bessie", species: .cow, breed: "Holstein", weight: 345, feedType: "Hay", feedSchedule: 6, vaccinationType: "Rabies", vaccinationFrequency: .sixWeeks, lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, notes: "")
    
    var animal: Animal
    var isMissed: Bool
    
    var body: some View {
        HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(animal.name)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Species: \(animal.species.rawValue.capitalized)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gray)
                        Text("Next vaccination: \(animal.nextVaccinationDate, style: .date)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isMissed ? .red : .blue)
                    }
                    Spacer()
                    Image(systemName: isMissed ? "exclamationmark.triangle.fill" : "bell.fill")
                        .foregroundColor(isMissed ? .red : .blue)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
    }


#Preview {
    vaccinationRow(animal: sampleAnimal, isMissed: false)
}
