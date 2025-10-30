//
//  ContentView.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI


struct ContentView: View {
    @State private var ShowingText = false
    @State private var farmLogo: Bool = false
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 60) {
                Spacer()
                
                Image("FarmCare Transparent")
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .scaleEffect(farmLogo ? 1.0 : 0.8)
                    .opacity(farmLogo ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.5), value: farmLogo)
                    
                
                
                
                Text("Modern Tools For Traditional Farmers")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color(red: 7/255, green: 28/255, blue: 24/255))

                    .padding()
                
                
                Spacer()
                
                NavigationLink { 
                    signInPage()
                    
                } label: {
                    
                    ZStack {
                        
                        RoundedRectangle(cornerRadius: 40)
                            .frame(width: 360, height: 85)
                            .foregroundStyle(Color(red: 7/255, green: 28/255, blue: 24/255).gradient)
                        
                        Text("Get Started")
                            .font(.title2)
                            .fontDesign(.default)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)
                        
                    }
                }
                .buttonStyle(.plain)
                
            }
            .onAppear {
                farmLogo = true
            }
        }
    }
    
    
}


#Preview {
    ContentView()
}
