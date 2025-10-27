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
    
    var body: some View {
        NavigationStack{
                Text("Sign in")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

            
            
            //name textfield
            VStack{
                VStack(alignment: .leading){
                    Text("Email address")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    TextField("Email Address ", text: $email)
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
                    
                    SecureField("Password", text: $password)
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
            }
        }
    }
}
    


#Preview {
    signInPage()
}

