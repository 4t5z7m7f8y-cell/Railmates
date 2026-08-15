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

    // MARK: - Bookmarks

    func toggleSavedTip(_ tipId: String) async {
        guard let userId = user?.id else { return }
        let alreadySaved = user?.savedTipIds?.contains(tipId) ?? false
        do {
            try await db.collection("users").document(userId).updateData([
                "savedTipIds": alreadySaved ? FieldValue.arrayRemove([tipId]) : FieldValue.arrayUnion([tipId])
            ])
            if alreadySaved {
                user?.savedTipIds?.removeAll { $0 == tipId }
            } else {
                if user?.savedTipIds == nil { user?.savedTipIds = [] }
                user?.savedTipIds?.append(tipId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSavedStory(_ storyId: String) async {
        guard let userId = user?.id else { return }
        let alreadySaved = user?.savedStoryIds?.contains(storyId) ?? false
        do {
            try await db.collection("users").document(userId).updateData([
                "savedStoryIds": alreadySaved ? FieldValue.arrayRemove([storyId]) : FieldValue.arrayUnion([storyId])
            ])
            if alreadySaved {
                user?.savedStoryIds?.removeAll { $0 == storyId }
            } else {
                if user?.savedStoryIds == nil { user?.savedStoryIds = [] }
                user?.savedStoryIds?.append(storyId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSavedGuide(_ guideId: String) async {
        guard let userId = user?.id else { return }
        let alreadySaved = user?.savedGuideIds?.contains(guideId) ?? false
        do {
            try await db.collection("users").document(userId).updateData([
                "savedGuideIds": alreadySaved ? FieldValue.arrayRemove([guideId]) : FieldValue.arrayUnion([guideId])
            ])
            if alreadySaved {
                user?.savedGuideIds?.removeAll { $0 == guideId }
            } else {
                if user?.savedGuideIds == nil { user?.savedGuideIds = [] }
                user?.savedGuideIds?.append(guideId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Following

    func toggleFollow(userId targetId: String) async {
        guard let myId = user?.id, myId != targetId else { return }
        let alreadyFollowing = user?.following?.contains(targetId) ?? false
        do {
            try await db.collection("users").document(myId).updateData([
                "following": alreadyFollowing ? FieldValue.arrayRemove([targetId]) : FieldValue.arrayUnion([targetId])
            ])
            if alreadyFollowing {
                user?.following?.removeAll { $0 == targetId }
            } else {
                if user?.following == nil { user?.following = [] }
                user?.following?.append(targetId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
