//
//  CustomTextField.swift
//  FarmCare
//
//  Created by Amanda Soganile on 29/10/2025.
//

import SwiftUI

struct CustomTextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String

    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            
            TextField(placeholder, text: $text)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.black, lineWidth: 2)
                )
                .frame(width: 366, height: 50)
        }
    }
}

#Preview {
    CustomTextField(title: "Email", text: .constant(""), placeholder: "Hello")
}
