//
//  AuthTextFieldStyle.swift
//  ExpanseTracker
//
//  Created by KPIT on 29/07/25.
//


import SwiftUI

struct AuthTextFieldStyle: TextFieldStyle {
    
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
    }
}
