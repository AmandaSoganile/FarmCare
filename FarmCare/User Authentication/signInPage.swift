//
//  sign_in page.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI

struct signInPage: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var navigateToHome : Bool = false
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        NavigationStack{
            Text("Sign in")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            
            
            //name textfield
            VStack{
                VStack(alignment: .leading){
                    CustomTextField(title: "Email Address", text: $viewModel.email, placeholder: "Email")
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                .padding()
                
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
                
                
                
                Button {
                    Task { try await viewModel.signInWithEmail(email: viewModel.email, password: viewModel.password)
                        if viewModel.isAuthenticated {
                            navigateToHome = true
                        }else {
                            viewModel.errorMessage = "Please fix the errors before signing in."
                        }
                    }
                } label: {
                    
                    ZStack {
                        
                        RoundedRectangle(cornerRadius: 40)
                            .frame(width: 366, height: 60)
                            .foregroundStyle(Color.black.gradient)
                        
                        Text("SIGN IN")
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
                    
                    Text("Dont have an account?")
                    
                    NavigationLink{
                        signUpPage()
                    } label: {
                        Text("Sign Up")
                    }
                }
                .padding(.trailing, 25)
                NavigationLink(destination: HomePage(), isActive: $navigateToHome) {
                    EmptyView()
                }
            }
        }
    }
}



#Preview {
    signInPage()
}

