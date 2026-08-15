//
//  AppTheme.swift
//  Railmates
//

import SwiftUI
import UIKit

extension Color {
    static let appGreen  = Color(red: 0.176, green: 0.431, blue: 0.294) // forest green #2D6E4B
    static let appOchre  = Color(red: 0.784, green: 0.565, blue: 0.098) // ochre #C89019
    static let appBrown  = Color(red: 0.40,  green: 0.26,  blue: 0.13)  // warm brown
}

// Card surface + shadow
struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

extension View {
    func appCard() -> some View { modifier(AppCardModifier()) }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
