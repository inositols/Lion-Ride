# NSU Ride 🚗

A modern, real-time campus ride-sharing application built with Flutter and Firebase. NSU Ride connects students looking for rides with available riders within the campus community, facilitating safe and efficient transportation.

---

## 🌟 Key Features

### 🎓 For Students
- **Real-time Map:** View available "Ghost Riders" nearby before requesting.
- **Ride Requesting:** Easy-to-use interface to request rides to specific destinations.
- **Live Tracking:** Track your rider's arrival and trip progress in real-time.
- **Wallet System:** Secure payments and balance management integrated with Paystack.
- **Trip History:** Records of all previous rides for easy tracking.

### 🏍️ For Riders
- **Online/Offline Toggle:** Control availability with a simple switch.
- **Request Management:** Accept or decline ride requests with live notifications.
- **Navigation Integration:** Direct links to Google Maps for efficient routing.
- **Earnings Tracking:** Monitor daily and total earnings directly in the app.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (v3.10.8+)
- **Language:** [Dart](https://dart.dev/)
- **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc) (BLoC/Cubit pattern)
- **Backend:** [Firebase](https://firebase.google.com/) (Auth, Firestore, Storage, Cloud Messaging)
- **Maps:** [google_maps_flutter](https://pub.dev/packages/google_maps_flutter)
- **Location:** [geolocator](https://pub.dev/packages/geolocator) & [geoflutterfire_plus](https://pub.dev/packages/geoflutterfire_plus)
- **Payments:** [flutter_paystack_max](https://pub.dev/packages/flutter_paystack_max)
- **Utilities:** [equatable](https://pub.dev/packages/equatable), [google_fonts](https://pub.dev/packages/google_fonts), [intl](https://pub.dev/packages/intl)

---

## 📂 Project Structure

```text
lib/
├── core/           # Constants, themes, and shared utilities
├── logic/          # BLoC/Cubit implementations (State Management)
│   ├── auth/       # Authentication logic
│   ├── ride/       # Ride booking and tracking logic
│   └── ...         # Location, Rider, Wallet logic
├── models/         # Data models (User, Ride, Transaction, etc.)
├── repositories/   # Data layer (Firebase interactions)
├── screens/        # UI Pages (Auth, Student Home, Rider Dashboard)
├── services/       # External services (Payment, Notification)
└── widgets/        # Reusable UI components
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.10.8 or higher)
- Android Studio / VS Code with Flutter extensions
- A Firebase Project (for backend services)
- Google Maps API Key

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/nsuride_mobile.git
   cd nsuride_mobile
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   - Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective directories.
   - Or use the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup?platform=ios) to configure.

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📖 Further Documentation

- [Technical Architecture](ARCHITECTURE.md)
- [Setup & Configuration Guide](SETUP.md)

---

Developed with ❤️ for the NSU Community.
