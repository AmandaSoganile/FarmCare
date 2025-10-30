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
            supabaseURL: URL(string: "https://wnjawruuuyiwkhbyapvp.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InduamF3cnV1dXlpd2toYnlhcHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0NDA3MTgsImV4cCI6MjA3NjAxNjcxOH0.tUMvk58Lsu5KNdaLfH-FCtB77ElBhbQT9mmyHBhl_LI")
    }
}
