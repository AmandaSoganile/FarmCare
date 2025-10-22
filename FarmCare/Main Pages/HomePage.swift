//
//  WelcomePage.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI

struct HomePage: View {
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 16) {
                Text("Hello")
            }
            .navigationBarBackButtonHidden(true)
        }
        
    }
}

#Preview {
    HomePage()
}
