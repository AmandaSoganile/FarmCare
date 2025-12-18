//
//  animal profile.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI
import SwiftData

struct animalProfile: View {
    @Environment(\.modelContext) private var context
    @Bindable var animal: Animal
    @State private var isEditing: Bool = false
    
    
    @State private var showDetails = false
    @State private var notes: String = ""
    @State private var healthStatus: HealthStatus = .healthy
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                //animal name and health status
                HStack(alignment: .center) {
                    Image(animal.species.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                        .padding(.trailing, 8)
                    VStack(alignment: .leading) {
                        Text(animal.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(animal.species.speciesDisplayName)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Circle()
                        .fill(healthStatus.color)
                        .frame(width: 20, height: 20)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 5)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Health Summary")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    // health summary
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Feed: \(animal.feedType)", systemImage: "leaf.fill")
                            Label("Every \(animal.feedSchedule) hrs", systemImage: "clock")
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Vaccination: \(animal.vaccinationType)", systemImage: "bandage.fill")
                            Label("Every \(animal.vaccinationFrequency.description)", systemImage: "calendar")
                        }
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                
                DisclosureGroup(isExpanded: $showDetails) {
                    
                    
                    // full details
                    VStack(alignment: .leading, spacing: 10) {
                        
                        Text("Name: \(animal.name)")
                        Text("Species: \(animal.species.speciesDisplayName)")
                        Text("Breed: \(animal.breed)")
                        Text("Feed Type: \(animal.feedType)")
                        Text("Feed Schedule: \(animal.feedSchedule) hours")
                        Text("Vaccination Type: \(animal.vaccinationType)")
                        Text("Vaccination Frequency: \(animal.vaccinationFrequency.description)")
                        Text("Last vaccination:  \(animal.lastVaccinationDate, style: .date)")
                        Text("Next vaccination: \(animal.nextVaccinationDate, style: .date)")
                    }
                    
                    .padding(.top, 8)
                    .font(.system(size: 20, weight: .medium, design: .default))
                    
                } label: {
                    
                    Text("View Full Details")
                        .font(.headline)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    
                    if isEditing {
                        TextEditor(text: $notes)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .onChange(of: notes) { _ in
                               
                                animal.notes = notes
                                do {
                                    try context.save()
                                } catch {
                                    // Handle save error appropriately in production
                                    print("Failed to save notes")
                                }
                            }
                    } else {
                        if animal.notes.isEmpty {
                            Text("No Notes Yet")
                                .foregroundColor(.secondary)
                        } else {
                            Text(animal.notes)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    Button(action: {
                        if isEditing {
                            
                            animal.notes = notes
                            do {
                                try context.save()
                            } catch {
                                print("Failed to save notes: \(error)")
                            }
                        } else {
                            
                            notes = animal.notes
                        }
                        isEditing.toggle()
                    }) {
                        Label(isEditing ? "Done" : "Edit Notes", systemImage: isEditing ? "checkmark.circle.fill" : "square.and.pencil")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Animal Profile")
        .onAppear {
            
            healthStatus = determineHealthStatus()
        }
    }
    
    
    func saveNotes() {
        print("Notes saved: \(notes)")
    }
    
    
    func determineHealthStatus() -> HealthStatus {
        
        if animal.vaccinationFrequency.rawValue <= 2 {
            return .healthy
        } else if animal.vaccinationFrequency.rawValue < 3 {
            return .monitor
        } else {
            return .needsAttention
        }
    }
}

enum HealthStatus {
    case healthy, monitor, needsAttention
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .monitor: return .yellow
        case .needsAttention: return .red
        }
    }
}


extension Species {
    var speciesDisplayName: String {
        switch self {
        case .cow: return "Cow"
        case .chicken: return "Chicken"
        case .pig: return "Pig"
        }
    }
}


#Preview {
    let previewAnimal = Animal(
        name: "Bessie",
        species: .cow,
        breed: "Holstein",
        weight: 345,
        feedType: "Hay",
        feedSchedule: 6,
        vaccinationType: "Rabies",
        vaccinationFrequency: .sixWeeks,
        lastVaccinationDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        notes: "Lively and eating well.",
        ownerID: ""
    )
    animalProfile(animal: previewAnimal)
}
