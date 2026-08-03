//
//  ErrorAlert.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI

// Error handling
struct ErrorAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// View modifier for showing errors
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: ErrorAlert?
    
    func body(content: Content) -> some View {
        content
            .alert(error?.title ?? "Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                Text(error?.message ?? "")
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<ErrorAlert?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}
