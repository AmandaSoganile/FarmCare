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
            HomePage(category: .init(name: "Pig", icon: .init("pig"), species: .pig))
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            add_New_Animal()
                .tabItem {
                    Label("Add", systemImage: "plus.app.fill")
                }
            
            animalCategories()
                .tabItem {
                    Label("Animal", systemImage: "pawprint.fill")
                }
               
        }
    }
}

#Preview {
    tabview()
}
