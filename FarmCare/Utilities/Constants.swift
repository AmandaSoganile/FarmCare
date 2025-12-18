//
//  Constants.swift
//  FarmCare
//
//  Created by Amanda Soganile on 18/12/2025.
//

import Foundation

enum Constants {
    static let supabaseKey: String = {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String else {
            fatalError("API_KEY not set in Info.plist")
        }
        return key
    }()

    
    static let supabaseURL: URL = {
        guard let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String else {
            fatalError("SUPABASE_URL not set in Info.plist")
        }
        return URL(string: "https://\(url)")!
    }()
}
