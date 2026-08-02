//
//  AuthenticationManager.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        // Check if user is already signed in
        if let firebaseUser = auth.currentUser {
            Task {
                await fetchUserProfile(userId: firebaseUser.uid)
            }
        }
    }
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String, displayName: String) async {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Create user profile in Firestore
            let newUser = User(
                id: result.user.uid,
                displayName: displayName,
                email: email
            )
            
            try db.collection("users").document(result.user.uid).setData(from: newUser)
            
            self.user = newUser
            self.isAuthenticated = true
            self.errorMessage = nil
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Sign up error: \(error)")
        }
    }
    
    func signIn(email: String, password: String) async {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await fetchUserProfile(userId: result.user.uid)
            self.errorMessage = nil
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Sign in error: \(error)")
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            self.user = nil
            self.isAuthenticated = false
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            print("Sign out error: \(error)")
        }
    }
    
    // MARK: - User Profile Management
    
    func fetchUserProfile(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            self.user = try document.data(as: User.self)
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
            print("Fetch user error: \(error)")
        }
    }
    
    func updateDisplayName(_ newName: String) async {
        guard let userId = user?.id else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "displayName": newName
            ])
            
            // Update local user
            self.user?.displayName = newName
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Update display name error: \(error)")
        }
    }
    
    func addFavoriteCity(_ city: String) async {
        guard let userId = user?.id else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "favoriteCities": FieldValue.arrayUnion([city])
            ])
            
            // Update local user
            if !user!.favoriteCities.contains(city) {
                self.user?.favoriteCities.append(city)
            }
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Add favorite city error: \(error)")
        }
    }
    
    func removeFavoriteCity(_ city: String) async {
        guard let userId = user?.id else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "favoriteCities": FieldValue.arrayRemove([city])
            ])
            
            // Update local user
            self.user?.favoriteCities.removeAll { $0 == city }
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Remove favorite city error: \(error)")
        }
    }
    
    func updateNotificationToken(_ token: String) async {
        guard let userId = user?.id else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "notificationToken": token
            ])
            
            self.user?.notificationToken = token
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Update notification token error: \(error)")
        }
    }
}
