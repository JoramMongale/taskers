# Technology Stack

**Analysis Date:** 2026-02-11

## Languages

**Primary:**
- Dart 3.3.0+ - Flutter application logic and UI
- Kotlin 1.7+ - Android native integration
- Swift - iOS native integration

**Secondary:**
- Java - Android support libraries
- Objective-C - iOS support libraries

## Runtime

**Environment:**
- Flutter 3.x+ - Cross-platform mobile framework (Android, iOS, Web)
- Dart SDK - Language runtime for Flutter

**Package Manager:**
- pub (Dart Package Manager) - Primary dependency manager
- Lockfile: `pubspec.lock` - present, ensures reproducible builds

## Frameworks

**Core:**
- Flutter 3.x+ - UI framework for Android, iOS, Web, Linux, macOS, Windows
- Material Design 3 - UI components and theming

**Backend & Database:**
- Firebase Core 3.14.0 - Backend infrastructure
- Cloud Firestore 5.6.9 - NoSQL database (real-time, document-based)
- Firebase Auth 5.3.5 - Authentication and user management
- Firebase Storage 12.4.7 - File and image storage
- Cloud Functions 4.5.4 - Serverless function backend

**Messaging & Notifications:**
- Firebase Messaging 15.2.2 - Cloud Messaging (FCM) for push notifications
- Flutter Local Notifications 19.3.0 - Local notification handling (Android/iOS)

**Testing:**
- flutter_test (built-in) - Unit and widget testing framework
- flutter_lints 4.0.0 - Linting and code quality rules

**Build/Dev:**
- Flutter SDK - Build and development tooling

## Key Dependencies

**Critical:**
- `firebase_core` 3.14.0 - Required for all Firebase services
- `firebase_auth` 5.3.5 - User authentication and session management
- `cloud_firestore` 5.6.9 - Primary data persistence layer
- `firebase_messaging` 15.2.2 - Push notifications infrastructure

**Infrastructure:**
- `http` 1.2.0 - HTTP client for payment gateway API calls
- `crypto` 3.0.3 - Cryptographic operations (signature generation for payments)

**UI & User Experience:**
- `cached_network_image` 3.3.0 - Image caching and optimization
- `shimmer` 3.0.0 - Loading placeholders
- `timeago` 3.7.0 - Human-readable time formatting (e.g., "2 hours ago")
- `fluttertoast` 8.2.8 - Toast notifications

**Data & State:**
- `shared_preferences` 2.2.3 - Local persistent key-value storage
- `intl` 0.19.0 - Internationalization and localization

**Payments & E-Commerce:**
- `webview_flutter` 4.8.0 - Embedded web browser for payment pages
- `webview_flutter_android` 3.16.0 - Android WebView support
- `webview_flutter_wkwebview` 3.13.0 - iOS WebView support
- `url_launcher` 6.2.5 - Launch URLs (payment redirects)

**Device Access & Permissions:**
- `permission_handler` 11.3.1 - Runtime permission management
- `image_picker` 1.1.2 - Camera and gallery image selection
- `file_picker` 8.1.2 - File selection from device storage
- `geolocator` 10.1.0 - GPS location services
- `path_provider` 2.1.4 - Device file system paths

**Utilities:**
- `timezone` 0.10.1 - Timezone handling for scheduled notifications

## Configuration

**Environment:**
- Configuration primarily via Firebase project ID and API keys
- `google-services.json` - Firebase configuration for Android (in `android/app/`)
- Environment variables can be passed via Dart's `String.fromEnvironment()` for API keys
- Default values embedded in `lib/config/firebase_config.dart` for development

**Build:**
- Android: `android/app/build.gradle.kts` - Kotlin build configuration
- iOS: `ios/Runner.xcworkspace` - Xcode workspace
- `pubspec.yaml` - Dart dependencies and Flutter configuration
- `analysis_options.yaml` - Linting rules for Dart analyzer

## Platform Requirements

**Development:**
- Flutter SDK 3.x+
- Dart 3.3.0 - 3.x
- Android Studio or VS Code with Flutter extension
- Xcode 14+ (for iOS)
- iOS 11+ deployment target
- Android API 23+ (minSdk), target 35 (targetSdk)

**Production:**
- Android: API 23 (Android 6.0) minimum, compiled for API 35 (Android 15)
- iOS: iOS 11+ (standard Flutter minimum)
- Google Play & App Store distribution targets
- Firebase project with valid credentials
- Paystack merchant account for payments (test and production keys)

**Server Requirements:**
- Firebase project with Firestore database enabled
- Firebase Authentication enabled (email/password method)
- Firebase Storage bucket configured
- Firebase Cloud Messaging (FCM) for notifications
- Firebase Cloud Functions for backend logic

---

*Stack analysis: 2026-02-11*
