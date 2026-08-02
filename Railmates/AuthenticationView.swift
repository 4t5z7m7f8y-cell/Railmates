//
//  AuthenticationView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isSignUp = false
    
    var body: some View {
        if authManager.isAuthenticated {
            MainTabView()
                .environmentObject(authManager)
                .task {
                    // Request notification permission after sign in
                    do {
                        let granted = try await notificationManager.requestPermission()
                        if granted {
                            print("✅ Notifications authorized")
                            
                            // Save notification token to user profile
                            if let token = notificationManager.deviceToken {
                                await authManager.updateNotificationToken(token)
                            }
                        }
                    } catch {
                        print("Error requesting notifications: \(error)")
                    }
                }
        } else {
            if isSignUp {
                SignUpView(authManager: authManager, isSignUp: $isSignUp)
            } else {
                SignInView(authManager: authManager, isSignUp: $isSignUp)
            }
        }
    }
}

struct SignInView: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var isSignUp: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo/Header
                VStack(spacing: 8) {
                    Image(systemName: "train.side.front.car")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Railmates")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Connect with fellow interrailers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                    
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button {
                        signIn()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    
                    Button {
                        isSignUp = true
                    } label: {
                        Text("Don't have an account? **Sign Up**")
                            .font(.subheadline)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Welcome Back")
        }
    }
    
    func signIn() {
        isLoading = true
        Task {
            await authManager.signIn(email: email, password: password)
            isLoading = false
        }
    }
}

struct SignUpView: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var isSignUp: Bool
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var validationError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Join Railmates")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Share tips and meet travelers")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                    
                    // Form
                    VStack(spacing: 16) {
                        TextField("Display Name", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                        
                        if let error = validationError ?? authManager.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button {
                            signUp()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Text("Create Account")
                                    .bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(!isFormValid || isLoading)
                        
                        Button {
                            isSignUp = false
                        } label: {
                            Text("Already have an account? **Sign In**")
                                .font(.subheadline)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Sign Up")
        }
    }
    
    var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    func signUp() {
        validationError = nil
        
        guard password == confirmPassword else {
            validationError = "Passwords don't match"
            return
        }
        
        guard password.count >= 6 else {
            validationError = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        Task {
            await authManager.signUp(email: email, password: password, displayName: displayName)
            isLoading = false
        }
    }
}

#Preview("Sign In") {
    SignInView(authManager: AuthenticationManager(), isSignUp: .constant(false))
}

#Preview("Sign Up") {
    SignUpView(authManager: AuthenticationManager(), isSignUp: .constant(true))
}
