//
//  add New Animal.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI

struct add_New_Animal: View {
    @State private var selectedOption = "Cow"
    let options = ["Cow", "Chicken"]
    
    @State private var selectedWeight = 1
    let weightOptions = Array(40...1000)
    @State private var name = ""
    @State private var breed = ""
    @State private var feedType = ""
    @State private var vaccinationType = ""
    
    @State private var feedingSchedule: Date = .now
    @State private var vaccinationSchedule: Date = .now
    
    var body: some View {
        
        VStack{
            HStack{
                Text("Add New Animal")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                
            }
            .padding()
            ScrollView{
                HStack(spacing: 60){
                    Text("Species")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Picker("Choose a species", selection: $selectedOption){
                        ForEach(options, id: \.self){ option in
                            Text(option).tag(option)
                        }
                    }
                    
                    .pickerStyle(.segmented)
                    .padding()
                }
                .padding()
                
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
                        .padding()
                        .pickerStyle(.inline)
                        
                    }
                    //                Spacer(minLength: 220)
                    
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
                    
                    //                    HStack(spacing: 60){
                    //                        Text("Species")
                    //                            .font(.title3)
                    //                            .fontWeight(.bold)
                    //
                    
                    DatePicker("Feed schedule", selection: $feedingSchedule, displayedComponents: .hourAndMinute)
                        .font(.title3)
                        .fontWeight(.bold)
                    .padding()
                }
            }
        }
    }
}



#Preview {
    add_New_Animal()
}

