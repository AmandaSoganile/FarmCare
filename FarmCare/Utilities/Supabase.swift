//
//  supabase.swift
//  FarmCare
//
//  Created by Amanda Soganile on 29/10/2025.
//

import Foundation
import Supabase

@MainActor
class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: Constants.supabaseURL,
            supabaseKey: Constants.supabaseKey
        )
    }
}
