# Setup & Configuration Guide

Follow these steps to set up your development environment for the NSU Ride project.

---

## 🔧 Environment Setup

### 1. Flutter & Dart
Ensure you have the latest stable version of Flutter and Dart installed.
```bash
flutter --version
```
If you need to install Flutter, follow the [official guide](https://docs.flutter.dev/get-started/install).

### 2. IDE Configuration
We recommend using **VS Code** or **Android Studio**.
- Install the **Flutter** and **Dart** plugins.
- (Optional) Install the **Better Comments** or **Error Lens** extensions for a better experience.

---

## 🔥 Firebase Configuration

The project relies heavily on Firebase for authentication, database, and storage.

1. **Create a Firebase Project** in the [Firebase Console](https://console.firebase.google.com/).
2. **Enable Services:**
   - **Authentication:** Email/Password and Google Sign-In.
   - **Cloud Firestore:** Start in test mode (and configure rules later).
   - **Firebase Storage:** For user profile pictures.
   - **Cloud Messaging (FCM):** For notifications.
3. **Add App Platforms:**
   - **Android:** Register app with ID `com.nsuride.app` (or your chosen ID). Download `google-services.json` and place it in `android/app/`.
   - **iOS:** Register app. Download `GoogleService-Info.plist` and add it via Xcode to the `Runner` target.
4. **Initialize FlutterFire:**
   Alternatively, use the Firebase CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

---

## 🗺️ Google Maps API Setup

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create or select a project.
3. Enable **Maps SDK for Android** and **Maps SDK for iOS**.
4. Create an **API Key** under "Credentials".
5. **Add API Key to Project:**
   - **Android:** In `android/app/src/main/AndroidManifest.xml`, add:
     ```xml
     <meta-data android:name="com.google.android.geo.API_KEY"
                android:value="YOUR_API_KEY_HERE"/>
     ```
   - **iOS:** In `ios/Runner/AppDelegate.swift`:
     ```swift
     GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
     ```

---

## 💳 Paystack Integration

1. Create an account on [Paystack](https://paystack.com/).
2. Get your **Public Key** from the Settings -> API Keys & Webhooks dashboard.
3. **Configuration:**
   - Locate the payment initialization logic (usually in `lib/services/payment_service.dart` or within the Wallet repository).
   - Replace the placeholder key with your actual Paystack Public Key.

---

## 🏃 Running the Project

1. Fetch dependencies:
   ```bash
   flutter pub get
   ```
2. Run on a connected device or emulator:
   ```bash
   flutter run
   ```

### Troubleshooting
- **Gradle Errors:** Run `cd android && ./gradlew clean && cd ..`.
- **CocoaPods Errors (macOS):** Run `cd ios && rm -rf Pods Podfile.lock && pod install && cd ..`.
- **Firebase Initialization:** Ensure `Firebase.initializeApp()` is called in `main.dart`.
