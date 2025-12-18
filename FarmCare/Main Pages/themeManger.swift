//
//  File.swift
//  FarmCare
//
//  Created by Amanda Soganile on 4/11/2025.
//

import Foundation
import SwiftUI
import Combine

enum AppTheme: String {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    @AppStorage("farmcare_theme") private var storedThemeValue: String = AppTheme.system.rawValue
    @Published var currentTheme: AppTheme

    init() {
        let saved = ThemeManager.loadTheme()
        _currentTheme = Published(initialValue: saved)
    }
    
    private static func loadTheme() -> AppTheme {
        let stored = UserDefaults.standard.string(forKey: "farmcare_theme")
        return AppTheme(rawValue: stored ?? "system") ?? .system
    }

    func set(_ theme: AppTheme) {
        currentTheme = theme
        storedThemeValue = theme.rawValue
    }
}
