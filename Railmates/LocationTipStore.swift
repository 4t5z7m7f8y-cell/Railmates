//
//  LocationTipStore.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import Foundation
import FirebaseFirestore
import Combine

class LocationTipStore: ObservableObject {
    @Published var tips: [LocationTip] = []

    private let db = Firestore.firestore()

    func fetchAll() {
        db.collection("locationTips")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching tips: \(error)")
                    return
                }
                self.tips = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: LocationTip.self)
                } ?? []
            }
    }

    func add(_ tip: LocationTip) {
        do {
            _ = try db.collection("locationTips").addDocument(from: tip)
        } catch {
            print("Error adding tip: \(error)")
        }
    }
}
