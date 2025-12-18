//
//  settings.swift
//  FarmCare
//
//  Created by Amanda Soganile on 15/10/2025.
//

import SwiftUI

struct settings: View {
    var body: some View {
        NavigationStack {
            List {
                
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundStyle(.gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My profile")
                                .font(.headline)
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Preferences") {
                    Label("Notifications", systemImage: "bell").fontWeight(.semibold)
                    Label("Privacy", systemImage: "lock").fontWeight(.semibold)
                    Label("Appearance", systemImage: "paintbrush").fontWeight(.semibold)
                }
                
                
                Section("Support") {
                    Label("Help Center", systemImage: "questionmark.circle").fontWeight(.semibold)
                    Label("Terms & Conditions", systemImage: "doc.text").fontWeight(.semibold)
                    Label("About", systemImage: "info.circle").fontWeight(.semibold)
                }
                
                Section {
                    Text("Log Out")
                        .foregroundStyle(.red)
                        .fontWeight(.semibold)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    settings()
}
