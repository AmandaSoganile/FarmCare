//
//  signInViewModel.swift
//  FarmCare
//
//  Created by Amanda Soganile on 28/10/2025.
//

import Foundation
import Combine
import Supabase

@MainActor
class AuthViewModel: ObservableObject{
    
    @Published var isAuthenticated = false
    @Published var email = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var errorMessage: String? = nil
    @Published var userId: String? = nil
    
    private let client = SupabaseManager.shared.client
    
    func signUpWithEmail(name: String, email: String, password: String) async throws {
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            let user = response.user
            let userId = user.id
            
            try await client.database
                .from("profiles")
                .insert(["id" : userId.uuidString, "name" : name, "email" : email])
                .execute()
            self.userId = user.id.uuidString
            self.isAuthenticated = true
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        do {
            let response = try await client.auth.signIn(email: email, password: password)
            let user = response.user
            self.userId = user.id.uuidString
            self.isAuthenticated = true
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() async throws {
        do{
            try await client.auth.signOut()
            isAuthenticated = false
            self.userId = nil
        } catch {
            print("Sign out failed : \(error.localizedDescription)")
        }
    }
    
    func checkSession() async {
        do{
            let session = try await client.auth.user()
            isAuthenticated = session != nil
        } catch {
            isAuthenticated = false
            userId = nil
        }
    }
    
    
    
    func isValidEmail() -> Bool {
        let emailFormat = "(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
    }
    

}
