//
//  tabview.swift
//  FarmCare
//
//  Created by Amanda Soganile on 16/10/2025.
//

import SwiftUI

struct tabview: View {
    var body: some View {
        TabView {
            HomePage()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            add_New_Animal()
                .tabItem {
                    Label("Add", systemImage: "plus.app.fill")
                }
            
            animal_species_tab()
                .tabItem {
                    Label("Animal", systemImage: "pawprint.fill")
                }
               
        }
    }
}

#Preview {
    tabview()
}
