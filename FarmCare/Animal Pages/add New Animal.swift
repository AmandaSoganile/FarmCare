//
//  add New Animal.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI
import SwiftData

struct add_New_Animal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var selectedOption = Species.cow
    let options = [Species.cow, Species.pig, Species.chicken]
    
    @State private var selectedWeight = 1
    let weightOptions = Array(40...1000)
    
    @State private var selectedFeed = 1
    let feedOptions = [1, 2, 3, 4, 6, 8, 10, 12, 24]
    
    @State private var selectedVaccination = 1
    @State private var selectedVaccinationFrequency: VaccinationInterval = .sixWeeks
    @State private var selectedVaccinationDate: Date = Date()

    
    @State private var name = ""
    @State private var breed = ""
    @State private var feedType = ""
    @State private var vaccinationType = ""
    
    @State private var feedingSchedule: Int = 1
    @State private var vaccinationSchedule: Int = 1
    

    
    var body: some View {
        NavigationStack{
            VStack{
                HStack{
                    Text("Add New Animal")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                    
                }
                .padding()
                
                //Choose a species
                ScrollView{
                    HStack(spacing: 60){
                        Text("Species")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Picker("Choose a species", selection: $selectedOption){
                            ForEach(options, id: \.self){ option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        
                        .pickerStyle(.segmented)
                        .padding()
                    }
                    .padding()
                    
                    // Animal name text field
                    VStack(alignment: .leading){
                        Text("Name")
                            .font(.title3)
                            .fontWeight(.bold)
                        TextField("Enter Animal Name eg. Tom", text: $name)
                            .padding(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 366, height: 50)
                                .shadow(radius: 20))
                    }
                    .padding()
                    
                    //Breed textfield
                    VStack(alignment: .leading){
                        Text("Breed")
                            .font(.title3)
                            .fontWeight(.bold)
                        TextField("Enter breed of animal eg.Holstein", text: $breed)
                            .padding(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 366, height: 50)
                                .shadow(radius: 20))
                    }
                    .padding()
                    
                    //Weight picker
                    VStack{
                        HStack(spacing: 60){
                            Text("Weight")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(18)
                            Picker("Choose weight", selection: $selectedWeight) {
                                ForEach(weightOptions, id: \.self) { value in
                                    Text("\(value) kg").tag(value)
                                }
                            }
                            .frame(height: 85)
                            .padding()
                            .pickerStyle(.inline)
                            
                        }
                       
                        
                        //feed type text field
                        VStack(alignment: .leading){
                            Text("Feed Type")
                                .font(.title3)
                                .fontWeight(.bold)
                            TextField("Enter name of feed eg. Hay", text: $feedType)
                                .padding(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 366, height: 50)
                                    .shadow(radius: 20))
                        }
                        .padding()
                        
                        //feed schedule picker
                        HStack(spacing: 60){
                            Text("Feed Schedule")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(18)
                            Picker("Choose weight", selection: $selectedFeed) {
                                ForEach(feedOptions, id: \.self) { value in
                                    Text("\(value) hr(s)").tag(value)
                                }
                            }
                            .frame(height: 85)
                            .padding()
                            .pickerStyle(.inline)
                            
                            
                        }
                        
                        
                        //vaccination type text field
                        VStack(alignment: .leading){
                            Text("Vaccination Type")
                                .font(.title3)
                                .fontWeight(.bold)
                            TextField("Enter name of vaccination eg. Rabies", text: $vaccinationType)
                                .padding(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 366, height: 50)
                                    .shadow(radius: 20))
                        }
                        .padding()
                        
                        
                        //last vaccination date picker
                        HStack(spacing: 60) {
                            Text("Last Vaccination Date")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            DatePicker("Select date", selection: $selectedVaccinationDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(.leading, 10)
                        }
                        .padding()
                        
                        
                        //vaccination frequency picker
                        HStack(spacing: 60) {
                            Text("Vaccination Frequency")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(18)
                            
                            Picker("Select frequency", selection: $selectedVaccinationFrequency) {
                                ForEach(VaccinationInterval.allCases, id: \.self) { interval in
                                    Text(interval.description).tag(interval)
                                }
                            }
                            .frame(height: 85)
                            .padding()
                            .pickerStyle(.inline)
                        }
                        
                        //button to save to a new array
                        Button {
                            
                            let animalToSave = Animal(
                                name: name,
                                species: selectedOption,
                                breed: breed,
                                weight: selectedWeight,
                                feedType: feedType,
                                feedSchedule: selectedFeed,
                                vaccinationType: vaccinationType,
                                vaccinationFrequency: selectedVaccinationFrequency,
                                lastVaccinationDate: selectedVaccinationDate,
                                notes: "",
                                ownerID: ""
                            )

                            context.insert(animalToSave)
                            
                            dismiss()
                        
                            do{
                                try context.save()
                                print("Animal saved")
                            }catch{
                                print("Failed to save")
                            }
                            
                        } label: {
                            
                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 40)
                                    .frame(width: 360, height: 85)
                                    .foregroundStyle(Color.black.gradient)
                                
                                Text("SAVE")
                                    .font(.title2)
                                    .fontDesign(.default)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.white)
                                
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)}
        
    }
}



#Preview {
    add_New_Animal()
}

