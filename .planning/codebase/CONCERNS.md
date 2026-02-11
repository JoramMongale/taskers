# Codebase Concerns

**Analysis Date:** 2026-02-11

## Tech Debt

**Hardcoded Test Credentials Exposed in Production Code:**
- Issue: Test payment card numbers and credentials are hardcoded in UI and service code
- Files: `lib/screens/payments/payment_launcher.dart` (lines 197-199), `lib/services/paystack_service.dart`
- Impact: Security vulnerability - test credentials are visible in compiled app and code repository; could confuse real users; violates payment PCI compliance
- Fix approach: Move all test data to a configuration file that is excluded from commits. Implement environment-based configuration to switch between test and production payment modes. Use Firebase Remote Config or similar for runtime test mode control.

**Excessive Console Logging in Production Code:**
- Issue: Debug `print()` statements throughout service layer expose sensitive operation details
- Files: `lib/services/auth_service.dart`, `lib/services/complete_payout_service.dart`, `lib/services/escrow_automation_service.dart`, `lib/services/notification_service.dart`, and multiple screen files
- Impact: Production app logs contain sensitive information like user IDs, payment amounts, email addresses, verification status; useful information for attackers; performance overhead
- Fix approach: Replace all `print()` calls with a logging service that respects a production flag. Implement structured logging with log levels (DEBUG, INFO, ERROR). Strip DEBUG logs in production builds using Dart code obfuscation.

**Firebase Configuration with Placeholder Values:**
- Issue: `lib/config/firebase_config.dart` contains placeholder and example Firebase credentials
- Files: `lib/config/firebase_config.dart` (lines 8, 44, 52)
- Impact: Android and iOS app IDs are placeholders ('ANDROID_APP_ID', 'IOS_APP_ID'); default values in config suggest fallback configuration is incomplete
- Fix approach: Use `flutter run --dart-define` or Gradle/Xcode build configuration to inject real credentials at build time. Never commit real Firebase credentials.

**Missing Error Context in Catch Blocks:**
- Issue: Many catch blocks re-throw or log errors without enough context for debugging
- Files: `lib/services/escrow_automation_service.dart` (line 100), `lib/services/messaging_service.dart` (line 71), multiple other services
- Impact: When errors occur in production, logs don't contain sufficient information to trace the cause; makes production debugging difficult
- Fix approach: Add context to all error handling: log the operation being performed, inputs being processed, and any state data. Use a structured error class with error codes.

---

## Known Bugs

**Escrow Auto-Release N+1 Query Problem:**
- Symptoms: Slow dashboard performance when many tasks with held escrow; database query count grows linearly with task count
- Files: `lib/services/escrow_automation_service.dart` (lines 348-374 in `getEscrowSummary()`)
- Trigger: Accessing admin payment dashboard when there are more than 100 held escrow transactions
- Workaround: Limit query to last 30 days only, paginate results
- Details: The `getEscrowSummary()` function fetches all held escrow transactions then issues a separate Firestore query for each transaction to check if it's ready for auto-release. This causes 1 + N queries where N is the number of held transactions. Should use a single aggregated query with a computed field or move logic to backend Cloud Function.

**Task Service Requires Explicit orderBy After Inequality Filter:**
- Symptoms: Queries with `isNotEqualTo` filter may fail on first use or throw Firestore index errors
- Files: `lib/services/task_service.dart` (lines 66-71 in `getAvailableTasks()`)
- Trigger: First call to `getAvailableTasks()` when no composite index exists
- Workaround: Create composite Firestore indexes manually in Firebase Console
- Details: Line 70 has a workaround comment showing awareness of this issue. The `where('posterId', isNotEqualTo:)` requires an explicit `orderBy('posterId')` before other orderBy clauses. This is unintuitive and requires index setup.

**Email Verification Not Re-checked on App Return:**
- Symptoms: User can bypass email verification requirement by closing app during verification screen and reopening
- Files: `lib/main.dart` (lines 93-97), `lib/services/auth_service.dart` (lines 50-55)
- Trigger: User reaches `EmailVerificationScreen`, verifies email in email client, closes app, reopens without waiting for automatic re-check
- Workaround: Manually refresh email verification status by re-opening email verification screen
- Details: The auth state check only validates `user.emailVerified` once on app startup. If user verifies email and reopens app quickly, the field may not be refreshed from Firebase. Need to add explicit refresh of user metadata or periodic re-checks.

---

## Security Considerations

**Sensitive Data in Local SharedPreferences:**
- Risk: User data including email, name, user types, and roles stored unencrypted in SharedPreferences
- Files: `lib/services/auth_service.dart` (lines 291-315 in `saveUserDataLocally()`)
- Current mitigation: None - data stored as plain text
- Recommendations: Use `flutter_secure_storage` instead of `SharedPreferences` for sensitive user data. At minimum, encrypt data before storing. Review what must actually be stored locally - consider keeping only authentication tokens and fetching user profile on app launch.

**Direct Firestore Rules Reliance Without Runtime Validation:**
- Risk: Security relies entirely on Firestore security rules; no server-side validation of business logic before database writes
- Files: All service files that call `_firestore.collection().add()` or `.update()`
- Current mitigation: Firestore rules (not in codebase)
- Recommendations: Implement backend Cloud Functions to validate all financial operations (payouts, escrow releases, payment status updates) before writing to database. Current architecture allows potential race conditions in payment processing.

**Payout Amounts Not Validated Before Database Write:**
- Risk: No integrity check that payout amount matches available earnings before processing
- Files: `lib/services/complete_payout_service.dart` (lines 73-74)
- Current mitigation: Validation check exists (line 142-146) but happens before write; nothing prevents concurrent duplicate payouts
- Recommendations: Implement idempotency keys for all financial operations. Use database transactions to atomically validate and update earnings. Consider moving payout logic to backend Cloud Function.

**IP Address and Device Info Stored as Placeholders:**
- Risk: Fraud detection fields not properly captured; infrastructure for identity verification incomplete
- Files: `lib/services/complete_payout_service.dart` (lines 62-63)
- Current mitigation: Fields exist but contain placeholders ('user_ip_here', 'user_device_here')
- Recommendations: Implement proper IP capture and device fingerprinting using appropriate libraries. Store these securely only for fraud detection, not indefinitely.

**No Rate Limiting on Authentication Attempts:**
- Risk: Firebase does provide rate limiting, but app-level protections are missing
- Files: `lib/services/auth_service.dart`
- Current mitigation: Firebase rate limiting for `too-many-requests` error (line 388)
- Recommendations: Implement app-level rate limiting on login attempts. Add exponential backoff for repeated failures. Log failed attempts for security monitoring.

**Payment Verification Dialog Shows Test Instructions in Production Code:**
- Risk: Instructions for test payment flow visible to all users regardless of build variant
- Files: `lib/screens/payments/payment_launcher.dart` (lines 195-204)
- Current mitigation: None
- Recommendations: Use `kDebugMode` or build configuration to show test instructions only in debug builds. For production, remove all test card references.

---

## Performance Bottlenecks

**Monolithic Widget Files (1000+ lines):**
- Problem: Multiple screens exceed 1000 lines, making them slow to render and hard to maintain
- Files:
  - `lib/widgets/chart_widgets.dart` (1861 lines)
  - `lib/screens/tasks/create_task_screen_enhanced.dart` (1698 lines)
  - `lib/services/complete_payout_service.dart` (1215 lines)
  - `lib/screens/tasks/post_task_screen.dart` (1090 lines)
  - `lib/widgets/earnings_dialogs.dart` (1062 lines)
  - `lib/screens/admin/admin_payment_dashboard.dart` (1050 lines)
- Cause: All logic bundled in single file; UI components not extracted to separate widgets
- Improvement path: Break monolithic files into smaller focused widgets. Extract reusable components to separate files. Use composition instead of inheritance.

**Unoptimized Firestore Queries Without Pagination:**
- Problem: `getAvailableTasks()` fetches all matching tasks without limit or pagination
- Files: `lib/services/task_service.dart` (lines 66-86)
- Cause: Query uses `.get()` without `.limit()` clause; no offset implementation
- Improvement path: Add pagination with `.limit(20)` and `.startAfter()` for lazy loading. Implement scroll-to-load pattern in UI.

**Escrow Automation Runs Every 30 Minutes with Nested Queries:**
- Problem: `_checkPendingReleases()` timer runs every 30 minutes, making synchronous nested queries
- Files: `lib/services/escrow_automation_service.dart` (lines 17-19, 52-76)
- Cause: For each completed task, a separate transaction query is executed; no batching
- Improvement path: Move escrow automation to backend Cloud Function triggered on task completion. Query all pending releases in single batch. Use Firestore transactions for atomic operations.

**Missing Composite Firestore Indexes:**
- Problem: Queries with multiple `where` clauses and `orderBy` require manual index creation
- Files: Referenced in `lib/services/task_service.dart` comments
- Cause: Firestore requires explicit indexes for complex queries
- Improvement path: Document all required indexes in a migration file. Auto-generate indexes during CI/CD. Test index performance.

---

## Fragile Areas

**Payment Transaction State Machine Without Transitions Validation:**
- Files: `lib/services/payment_service.dart`, `lib/services/escrow_automation_service.dart`, `lib/screens/payments/payment_launcher.dart`
- Why fragile: Multiple services update transaction status independently; no enforcement that transitions follow valid state flow (e.g., can't go from `failed` to `captured`)
- Safe modification: Document all valid state transitions. Add validation in `updateTransactionStatus()` to reject invalid transitions. Consider using a state machine pattern library.
- Test coverage: No unit tests for payment state transitions

**Notification Service Global State with Timer:**
- Files: `lib/services/notification_service.dart` (lines 12, 147-148)
- Why fragile: Static `_automationTimer` in `EscrowAutomationService` is shared globally; no protection against double-start or stop-without-start
- Safe modification: Add state flags to track if automation is already running. Implement proper disposal/cleanup in app lifecycle. Consider using a service locator pattern instead of static variables.
- Test coverage: No tests for timer lifecycle

**User Type Switching Without State Synchronization:**
- Files: `lib/services/auth_service.dart` (lines 318-336 in `updateUserRole()`)
- Why fragile: Updates role in both local SharedPreferences and Firestore separately; no atomic operation; out-of-sync states possible between local and remote
- Safe modification: Use Firestore transactions to atomically update role. Sync local cache only after successful remote update. Implement retry logic for failed syncs.
- Test coverage: No tests for role switching edge cases

---

## Scaling Limits

**Firestore Document Limit for Escrow Summary:**
- Current capacity: Can fetch and process ~100 held escrow transactions before timeout
- Limit: At scale (1000+ concurrent tasks), the `getEscrowSummary()` query will timeout or hit memory limits
- Scaling path: Move escrow summary aggregation to backend Cloud Function with proper indexing and caching. Pre-compute summary statistics every 5 minutes rather than computing on-demand. Use Firestore's aggregation queries (if available in version used).

**FCM Token Refresh Not Handled:**
- Current capacity: FCM tokens are saved once at login but never refreshed
- Limit: FCM tokens expire after ~60 days; without refresh, push notifications stop working
- Scaling path: Implement periodic FCM token refresh (monthly). Listen to FCM token refresh events and update Firestore whenever token changes. Test with real devices over 60+ days.

**SharedPreferences Key-Value Pairs Per User:**
- Current capacity: Storing ~8 user profile fields plus potential future fields
- Limit: SharedPreferences has no built-in limit but becomes slow beyond ~1MB of total data
- Scaling path: Don't store large user data in SharedPreferences. Keep only authentication credentials and minimal metadata. Fetch profile data from Firestore on app launch.

---

## Dependencies at Risk

**firebase_messaging (^15.2.2) - Platform Instability:**
- Risk: Firebase Messaging has frequent breaking changes between major versions; current pinned version may become outdated
- Impact: Push notifications may fail after OS updates or Flutter SDK updates; upgrading requires careful testing
- Migration plan: Regularly audit Firebase package versions against latest stable releases. Test notification flow on real devices after any version bump. Consider abstraction layer for notifications to reduce migration pain.

**webview_flutter (^4.8.0) - Security & Deprecation Risk:**
- Risk: WebView has known security vulnerabilities; package frequently requires platform-specific updates
- Impact: Payment page (sensitive data) loaded in WebView; must stay updated for security patches
- Migration plan: Monitor WebView security advisories. Update immediately on patch releases. Consider using platform-specific payment solutions instead of WebView.

**permissison_handler (^11.3.1) - Fragmented Platform Support:**
- Risk: Android and iOS permissions change frequently; package may lag behind OS changes
- Impact: Notification and location permissions may silently fail on newer Android/iOS versions
- Migration plan: Test permission requests on devices running latest OS versions. Have fallback behavior when permissions are denied.

---

## Missing Critical Features

**No Offline Mode:**
- Problem: App is entirely online-dependent; no caching of tasks, user data, or messages
- Blocks: Users can't browse tasks or view their profile without internet connection
- Scope: Large feature requiring: local database (Hive/sqlite), sync queue, conflict resolution

**No Dispute/Escrow Resolution System:**
- Problem: Code mentions disputes (line 111 in `escrow_automation_service.dart`) but no dispute creation or resolution UI exists
- Blocks: Users can't report problems with completed tasks; no mechanism to hold escrow when dispute exists
- Scope: Medium feature requiring: dispute creation screens, dispute evidence upload, admin review interface

**No Analytics Integration:**
- Problem: No tracking of user behavior, funnel conversion, or error rates
- Blocks: Can't identify bottlenecks or optimize user experience
- Scope: Medium feature requiring: Firebase Analytics integration, custom event tracking, dashboard

**No Rate Limiting on Payout Requests:**
- Problem: Users could request multiple payouts in rapid succession; only daily limit exists
- Blocks: Spam or abuse possibility; no per-request cooldown
- Scope: Small feature requiring: add minimum time between payout requests, validate in service layer

---

## Test Coverage Gaps

**Zero Unit Tests for Services:**
- What's not tested: All business logic in `complete_payout_service.dart`, `escrow_automation_service.dart`, `task_service.dart`, `auth_service.dart`
- Files: `test/widget_test.dart` contains only placeholder test
- Risk: Payment logic bugs won't be caught before production. Escrow automation errors have financial impact.
- Priority: High - Payment and escrow services should have 90%+ coverage

**Zero Integration Tests for Firestore Operations:**
- What's not tested: Database queries, transaction handling, field updates
- Files: No integration tests exist
- Risk: Database refactoring or query changes could silently break functionality
- Priority: High - All Firestore queries should have integration tests

**No Widget Tests for Payment Flow:**
- What's not tested: Payment launcher navigation, verification dialog interaction, error handling
- Files: `lib/screens/payments/payment_launcher.dart` has no tests
- Risk: Payment UI breaking changes won't be caught
- Priority: Medium - Critical user flows should be tested

**No Escrow Automation Tests:**
- What's not tested: Timer lifecycle, auto-release logic, concurrent release prevention
- Files: `lib/services/escrow_automation_service.dart` has no tests
- Risk: Race conditions or logic bugs in financial automation won't be caught
- Priority: Critical - Escrow automation must be thoroughly tested before production

---

*Concerns audit: 2026-02-11*
