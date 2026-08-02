//
//  ContentView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    @State private var statusMessage = "Not tested yet"

    var body: some View {
        VStack(spacing: 20) {
            Text("Firebase Connection Test")
                .font(.title2)
                .bold()

            Text(statusMessage)
                .foregroundColor(.secondary)

            Button("Test Firebase Connection") {
                testFirebase()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    func testFirebase() {
        let db = Firestore.firestore()

        db.collection("testCollection").addDocument(data: [
            "message": "Hello from Railmates!",
            "timestamp": Date()
        ]) { error in
            if let error = error {
                statusMessage = "Failed: \(error.localizedDescription)"
            } else {
                statusMessage = "Success! Document written."
            }
        }
    }
}

#Preview {
    ContentView()
}
