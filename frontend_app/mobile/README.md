<div align="center">
  <img src="../../app_icon_transparent.png" width="100" height="100" alt="CuanBuddy Logo">
  <h1>💰 CuanBuddy Mobile App</h1>
  <p><strong>A beautiful, cross-platform personal finance companion application.</strong></p>
</div>

<hr />

## 🚀 Overview
**CuanBuddy** is designed to make money management approachable and intuitive for everyone. This frontend repository houses the mobile application (Android & iOS) built with Flutter. It emphasizes rich aesthetics, smooth micro-animations, and a premium user experience while interacting with the CuanBuddy RESTful backend.

## 🛠️ Tech Stack
This mobile application leverages the best of the modern Flutter ecosystem:

- **Framework**: [Flutter](https://flutter.dev/) (Cross-platform native UI)
- **State Management**: [Riverpod](https://riverpod.dev/) (Safe, scalable, and reactive)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) (Declarative URL-based routing)
- **Networking**: [Dio](https://pub.dev/packages/dio) (Robust HTTP client with interceptors)
- **Local Storage**: `flutter_secure_storage` & `shared_preferences`
- **Language**: Dart

## 📂 Project Structure
The codebase follows a feature-driven architecture to keep boundaries clear and maintainable.

```text
lib/
├── core/              # Global utilities, theme, routing, networking, and l10n
├── features/          # Independent modules of the app
│   ├── auth/          # Login, Registration, Splash, Onboarding
│   ├── analytics/     # Financial charts and data visualization
│   ├── budgets/       # Budget tracking screens
│   ├── profile/       # User settings, language, theme, backups
│   ├── savings/       # Savings goals and tracking
│   └── transactions/  # Income and expense management
```

## ✨ Core Features
- **Aesthetic UI/UX**: Premium design with glassmorphism, dynamic gradients, and smooth micro-animations.
- **Smart Budgeting**: Set monthly limits and get visually intuitive warnings as you approach them.
- **AI Financial Advisor**: Integrated chat interface for personalized financial insights.
- **Fully Localized**: Seamlessly switch between English and Indonesian with instant UI updates.
- **Secure Persistence**: Encrypted local storage for sensitive tokens and preferences.

## 💻 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.5.0 or higher)
- Android Studio / Xcode for emulators

### Installation
```bash
# Get dependencies
flutter pub get

# Run code generation (if applicable)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Running the App
```bash
# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

---
*Built with ❤️ for CuanBuddy.*
