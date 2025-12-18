//
//  tabview.swift
//  FarmCare
//
//  Created by Amanda Soganile on 16/10/2025.
//

import SwiftUI

struct TabsView: View {
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
            
            
            AnimalCategories()
                .tabItem {
                    Label("Animal", systemImage: "pawprint.fill")
                }
        }
        .sheet(isPresented: $showingSheet) {
            AddNewAnimal()
        }
    }
}

#Preview {
    TabsView()
}
