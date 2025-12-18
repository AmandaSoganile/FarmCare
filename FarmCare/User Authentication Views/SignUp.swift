//
//  sign up page.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//


import SwiftUI

struct SignUp: View {
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    @State private var navigateToHome = false
    
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                
                Image("FarmCare Transparent")
                    .resizable()
                    .frame(width: 200, height: 150)
                
                Text("Create your Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(spacing: 16) {
                    
                    // Name
                    CustomTextField(
                        title: "Name",
                        text: $viewModel.name,
                        placeholder: "Name"
                    )
                    
                    // Email
                    CustomTextField(
                        title: "Email",
                        text: $viewModel.email,
                        placeholder: "Email"
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    
                    // Password
                    VStack(alignment: .leading) {
                        Text("Password")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        HStack {
                            if showPassword {
                                TextField("Password", text: $viewModel.password)
                            } else {
                                SecureField("Password", text: $viewModel.password)
                            }
                            
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .frame(height: 50)
                    }
                    
                    // Password strength
                    Text(
                        viewModel.password.count < 8
                        ? "Password must be at least 8 characters"
                        : "Strong password"
                    )
                    .foregroundColor(
                        viewModel.password.count < 8 ? .red : .green
                    )
                    .font(.footnote)
                    
                    // Confirm Password
                    VStack(alignment: .leading) {
                        Text("Confirm Password")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        HStack {
                            if showConfirmPassword {
                                TextField("Confirm Password", text: $confirmPassword)
                            } else {
                                SecureField("Confirm Password", text: $confirmPassword)
                            }
                            
                            Button {
                                showConfirmPassword.toggle()
                            } label: {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .frame(height: 50)
                        
                        if confirmPassword != viewModel.password && !confirmPassword.isEmpty {
                            Text("Passwords do not match")
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                    }
                }
                .padding()
                
                
                Button {
                    Task {
                        guard confirmPassword == viewModel.password else {
                            viewModel.errorMessage = "Passwords do not match"
                            return
                        }

                        do {
                            try await viewModel.signUpWithEmail(
                                name: viewModel.name,
                                email: viewModel.email,
                                password: viewModel.password
                            )
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 40)
                            .frame(height: 60)
                            .foregroundStyle((Color(red: 7/255, green: 28/255, blue: 24/255)).gradient)

                        Text("SIGN UP")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                
                HStack {
                    Text("Already have an account?")
                    NavigationLink("Sign In") {
                        SignIn()
                    }
                }
                .padding(.bottom, 20)
                
                Spacer()
            }
            .onChange(of: viewModel.isAuthenticated) {
                    if viewModel.isAuthenticated {
                        navigateToHome = true
                    }
                }
            .navigationDestination(isPresented: $navigateToHome) {
                TabsView()
            }
        }
    }
}



#Preview {
    SignUp()
        .environmentObject(AuthViewModel())
}
