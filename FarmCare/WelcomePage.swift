//
//  WelcomePage.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI

struct WelcomePage: View {
    @State private var ShowingText = false
    var body: some View {
        NavigationStack{
            VStack(spacing: 60) {
                Spacer()
                
                Image("FarmCare Transparent")
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                
                
                Text("Modern Tools For Traditional Farmers")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .fontDesign(.rounded)
                    .padding()
                
                Spacer()
                
                NavigationLink { ContentView()
                    
                } label: {
                    
                    ZStack {
                        
                        RoundedRectangle(cornerRadius: 40)
                            .frame(width: 360, height: 85)
                            .foregroundStyle(.black.gradient)
                        
                        Text("Get Started")
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
}

#Preview {
    WelcomePage()
}
