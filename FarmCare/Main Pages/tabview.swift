//
//  tabview.swift
//  FarmCare
//
//  Created by Amanda Soganile on 16/10/2025.
//

import SwiftUI

struct tabview: View {
    @State private var showingSheet = false
    var body: some View {
        TabView {
            HomePage()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            Color.clear
                .tabItem {
                    Label("Add", systemImage: "plus.app.fill")
                }
                .onAppear {
                    showingSheet = true
                }
            
            
            animalCategories()
                .tabItem {
                    Label("Animal", systemImage: "pawprint.fill")
                }
        }
        .sheet(isPresented: $showingSheet) {
                    add_New_Animal()
                }
    }
}

#Preview {
    tabview()
}
