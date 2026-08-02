# Firebase Authentication Setup Guide

## 🔥 Adding Firebase Auth to Your Project

You're getting the error because Firebase Authentication isn't added to your project yet.

---

## Option 1: Swift Package Manager (Recommended)

### Steps:

1. **Open your Xcode project**

2. **Go to**: File → Add Package Dependencies...

3. **Enter the URL**:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```

4. **Click "Add Package"**

5. **Select these packages**:
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore (you likely already have this)
   - ✅ FirebaseMessaging (for v3 notifications later)

6. **Click "Add Package"**

7. **Wait for Xcode to download** (may take a minute)

---

## Option 2: CocoaPods

If you're using CocoaPods, add to your `Podfile`:

```ruby
pod 'Firebase/Auth'
pod 'Firebase/Firestore'
pod 'Firebase/Messaging'
```

Then run:
```bash
pod install
```

---

## After Installing

### 1. Update your app initialization

Check your `RailmatesApp.swift` file. Let me create/update that next!

### 2. Build the project

After adding the packages:
1. Press **Cmd + B** to build
2. The error should disappear

---

## Enable Authentication in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your Railmates project
3. Go to **Authentication** in the left menu
4. Click **Get Started**
5. Enable sign-in methods:
   - ✅ **Email/Password** (enable this first)
   - ✅ **Google** (optional, for later)
   - ✅ **Apple** (optional, recommended for iOS)

---

## Next Steps After Setup

Once Firebase Auth is installed, you can:
1. Build the sign-in/sign-up UI
2. Test authentication
3. Continue with happenings features

Let me know when you've added the Firebase packages and I'll continue! 🚂
