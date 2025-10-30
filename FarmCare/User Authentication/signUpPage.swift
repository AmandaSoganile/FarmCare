//
//  sign up page.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI

struct signUpPage: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var showPassword: Bool = false
    @State private var navigateToHome = false
    @State private var showConfirmPassword: Bool = false
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack{
        Text("Create your Account")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding()
        
            VStack{
                VStack(alignment: .leading){
                    CustomTextField(title: "Name", text: $viewModel.name, placeholder: "Name")
                        
                }
                
                
                VStack(alignment: .leading){
                    CustomTextField(title: "Email", text: $viewModel.email, placeholder: "  Email")
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                
                VStack(alignment: .leading){
                    Text("Password")
                        .font(.title3)
                        .fontWeight(.bold)
                    HStack {
                        if showPassword {
                            TextField("Password", text: $viewModel.password)
                        } else {
                            SecureField("Password", text: $viewModel.password)
                        }
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .frame(width: 366, height: 50)
                }
                
                Text(viewModel.password.count < 8 ? "Password must be at least 8 characters" : " Strong password")
                    .foregroundColor(viewModel.password.count < 8 ? .red : .green)
                    .font(.footnote)
                    .padding(.leading, 10)
            
            
                VStack(alignment: .leading){
                    Text("Confirm Password")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    HStack {
                        if showConfirmPassword {
                            TextField("Confirm Password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                        }
                        Button(action: { showConfirmPassword.toggle() }) {
                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .frame(width: 366, height: 50)
                    
                    if confirmPassword != viewModel.password && !confirmPassword.isEmpty {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.leading, 10)
                    }
                }
                .padding()
                
                
                Button{
                    Task{
                        try await viewModel.signUpWithEmail(name : viewModel.name, email: viewModel.email, password: viewModel.password)
                        if viewModel.isAuthenticated {
                            navigateToHome = true
                        }else {
                            viewModel.errorMessage = "Please fix the errors before signing up."
                        }
                    }
                } label: {
                    
                    ZStack {
                        
                        RoundedRectangle(cornerRadius: 40)
                            .frame(width: 366, height: 60)
                            .foregroundStyle(Color.black.gradient)
                        
                        Text("SIGN UP")
                            .font(.title2)
                            .fontDesign(.default)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)
                        
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
                .padding()
                
                HStack{
                    Spacer()
                    
                    Text("Already have an account?")
                    
                    NavigationLink{
                        signInPage()
                    } label: {
                        Text("Sign In")
                    }
                }
                .padding(.trailing, 25)
                NavigationLink(destination: HomePage(), isActive: $navigateToHome) {
                                   EmptyView()
                               }
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}
        

#Preview {
    signUpPage()
}
