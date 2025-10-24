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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Animal.self)
    }
}
