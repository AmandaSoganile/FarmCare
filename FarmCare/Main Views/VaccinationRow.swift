//
//  vaccinationRow.swift
//  FarmCare
//
//  Created by Amanda Soganile on 23/10/2025.
//

import SwiftUI
import SwiftData


struct VaccinationRow: View {
    var animal: Animal
    var isMissed: Bool
    
    var body: some View {
        HStack {
            
            Color.green.opacity(0.7)
                .frame(width: 10, height: 100)
                .contrast(0.3)
                .cornerRadius(5)
            VStack(alignment: .leading, spacing: 6) {
                Text(animal.name)
                    .font(.title)
                    .fontWeight(.bold)
                Text("Species: \(animal.species.rawValue.capitalized)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(Edge.Set([.top]), 4)
                    .foregroundStyle(Color.gray)
                Text("Next vaccination: \(animal.nextVaccinationDate, style: .date)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isMissed ? .red : (Color(red: 7/255, green: 28/255, blue: 24/255)))
            }
            Spacer()
            Image(systemName: isMissed ? "exclamationmark.triangle.fill" : "bell.fill")
                .foregroundColor(isMissed ? .red : Color(red: 7/255, green: 28/255, blue: 24/255))
                .font(.system(size: 26))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}


#Preview {
    VaccinationRow(animal: sampleAnimal, isMissed: false)
}
