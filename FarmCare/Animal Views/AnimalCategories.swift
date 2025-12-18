//
//  animalCategories.swift
//  FarmCare
//
//  Created by Amanda Soganile on 17/10/2025.
//

import SwiftUI


struct AnimalCategories: View {
    var body: some View {
        NavigationStack {
            ZStack{
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.6), Color.orange.opacity(0.05)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 17) {
                        Text("Animal Species")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundStyle(Color(red: 7/255, green: 28/255, blue: 24/255))
                        
                        ForEach(categories) { category in
                            NavigationLink(destination: SingleAnimalSpecies(category: category)) {
                                
                                HStack(spacing: 29){
                                    Image(category.species.imageResource)
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                    
                                    Text(category.name)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.black)
                                    
                                }
                                
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color.white)
                                        .frame(height: 200)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 28)
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                        .shadow(radius: 5)
                                )
                                .frame(height: 200)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
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
                                    .foregroundStyle(Color(red: 7/255, green: 28/255, blue: 24/255))
                                    .shadow(radius: 12)
                                
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
}




#Preview {
    NavigationStack {
        AnimalCategories()
    }
}
