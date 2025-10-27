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
    
    var body: some View {
        NavigationStack{
        Text("Sign Up")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding()
        
            VStack{
                VStack(alignment: .leading){
                    Text("Full Name")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    TextField("Name", text: $name)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.black, lineWidth: 2)
                            .frame(width: 366, height: 50)
                            .shadow(radius: 20))
                }
                .padding()
                
                VStack(alignment: .leading){
                    Text("Email")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    TextField("Email", text: $email)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.black, lineWidth: 2)
                            .frame(width: 366, height: 50)
                            .shadow(radius: 20))
                }
                .padding()
                
                VStack(alignment: .leading){
                    Text("Password")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    TextField("Password", text: $password)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.black, lineWidth: 2)
                            .frame(width: 366, height: 50)
                            .shadow(radius: 20))
                }
                .padding()
                VStack(alignment: .leading){
                    Text("Confirm Password")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    TextField("Password", text: $confirmPassword)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.black, lineWidth: 2)
                            .frame(width: 366, height: 50)
                            .shadow(radius: 20))
                }
                .padding()
                
                NavigationLink{
                    HomePage()
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
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}

#Preview {
    signUpPage()
}
