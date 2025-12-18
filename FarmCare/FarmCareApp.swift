//
//  FarmCareApp.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI
import SwiftData



@main
struct FarmCareApp: App {
 @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated{
                HomePage(category: .init(name: "Pig", icon: .init("pig"), species: .pig))
                    .environmentObject(authViewModel)
                    .environmentObject(AnimalViewModel())
            } else {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(AnimalViewModel())
            }
        }
        .modelContainer(for: Animal.self)
    }
}
