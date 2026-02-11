# External Integrations

**Analysis Date:** 2026-02-11

## APIs & External Services

**Payment Processing:**
- Paystack - Payment gateway for transaction processing
  - SDK/Client: `http` client with custom PaystackService wrapper
  - Auth: API keys hardcoded in `lib/services/paystack_service.dart`
    - Public Test Key: `pk_test_[REDACTED]`
    - Secret Test Key: `sk_test_[REDACTED]`
  - Endpoint: `https://api.paystack.co/transaction/initialize` (POST)
  - Verification: `https://api.paystack.co/transaction/verify/{reference}` (GET)
  - Supported payment methods: Card, Bank Transfer, USSD, QR
  - Currency: ZAR (South African Rand)
  - Implementation: `lib/services/paystack_service.dart`

**External Web Content:**
- WebView Integration for payment pages
  - Package: `webview_flutter` 4.8.0
  - Platform-specific: Android (`webview_flutter_android` 3.16.0), iOS (`webview_flutter_wkwebview` 3.13.0)
  - Use case: Embedded payment forms and external merchant pages
  - Implementation: `lib/screens/payments/web_payment_screen.dart`

## Data Storage

**Databases:**
- Firebase Firestore (NoSQL, document-based)
  - Connection: Configured via Firebase project settings in `lib/firebase_options.dart`
  - Project ID: `taskers-default` (configurable via environment)
  - Client: FlutterFire - `cloud_firestore` 5.6.9
  - Collections:
    - `users` - User profiles and account data
    - `tasks` - Task postings and details
    - `conversations` - Messaging between posters and taskers
    - `messages` - Individual messages in conversations
    - `transactions` - Payment and transaction records
  - Real-time listeners implemented across app for live updates

**File Storage:**
- Firebase Storage
  - Package: `firebase_storage` 12.4.7
  - Use case: Profile pictures, task images, document uploads
  - Bucket: Configured via Firebase project

**Caching:**
- Local Device Cache
  - Package: `cached_network_image` 3.3.0 - HTTP image caching
  - Package: `shared_preferences` 2.2.3 - Key-value persistent storage
  - Use cases:
    - User session data (types, current role)
    - Cached user preferences
    - Device-specific configuration

## Authentication & Identity

**Auth Provider:**
- Firebase Authentication
  - Method: Email/Password authentication
  - Services: `lib/services/auth_service.dart`
  - Features:
    - User registration with email verification
    - Email/password sign-in
    - Password reset (forgot password flow)
    - Session management via FirebaseAuth instance
    - User roles/types stored in Firestore (user can have multiple roles: "poster", "tasker")
  - Email verification required before app access
  - Last login timestamp tracked in Firestore

## Monitoring & Observability

**Error Tracking:**
- Console logging (print statements throughout codebase)
- Firestore query monitoring for transaction/payment issues
- No external error tracking service detected (e.g., Sentry, Firebase Crashlytics not configured)

**Logs:**
- Console logs with emoji prefixes for debugging (e.g., 🔵, ✅, ❌, 💥)
- Device logs captured during development
- No centralized logging service configured

## CI/CD & Deployment

**Hosting:**
- Mobile-first deployment: Android (Google Play), iOS (App Store)
- Web support: Flutter web capability configured
- Desktop platforms: Linux, macOS, Windows support in project structure

**CI Pipeline:**
- No CI/CD configuration detected in codebase
- Manual build process likely required

## Environment Configuration

**Required env vars:**
- `FIREBASE_API_KEY` - Firebase web API key (default in code: `'your-default-key-here'`)
- `FIREBASE_PROJECT_ID` - Firebase project ID (default in code: `'taskers-default'`)
- Paystack keys hardcoded (should be environment variables in production)

**Secrets location:**
- Firebase configuration: `lib/firebase_options.dart` (embedded, platform-specific)
- Paystack keys: `lib/services/paystack_service.dart` (hardcoded - **SECURITY RISK**)
- Google Services: `android/app/google-services.json` (Firebase config file)
- iOS: Firebase config embedded via CocoaPods/Firebase pod

**Security Notes:**
- Test Paystack API keys are committed to source code (should use env vars)
- Firebase API keys embedded in config files (standard for Flutter)

## Webhooks & Callbacks

**Incoming:**
- Paystack Callback: `callback_url` configured in payment initialization
  - Default: `https://your-app.com/payment/callback` (placeholder URL)
  - Implementation: Requires backend webhook handler in Cloud Functions

**Outgoing:**
- Firebase Cloud Functions calls (not explicitly shown in sampled code)
- Potential webhooks via Cloud Functions for payment events
- No explicit webhook implementation visible in examined services

## Data Flow Architecture

**User Registration & Auth Flow:**
1. User enters email/password in `lib/screens/auth/register_form.dart`
2. AuthService calls Firebase Auth to create account
3. Verification email sent to user
4. User data document created in Firestore `users` collection
5. User types stored in Firestore and local SharedPreferences

**Payment Flow:**
1. Task poster initiates payment from task completion screen
2. PaymentService creates transaction document in Firestore
3. PaystackService initializes payment via HTTP POST to Paystack API
4. User redirected to Paystack payment URL via WebView
5. Paystack handles payment processing
6. Success/failure callback triggers verification
7. Transaction status updated in Firestore

**Messaging Flow:**
1. Tasker starts conversation with poster about task
2. MessagingService creates conversation document in Firestore
3. Initial message sent to Firestore `messages` collection
4. Real-time listener pushes new messages to UI
5. Firebase Messaging sends FCM notifications for new messages
6. Local notifications displayed on device

**Notification Flow:**
1. Message/payment event triggers notification in backend (Cloud Function)
2. Firebase Messaging sends FCM payload to device
3. NotificationService receives message in foreground/background
4. Local notification displayed via flutter_local_notifications
5. User can tap notification to navigate to relevant screen

---

*Integration audit: 2026-02-11*
