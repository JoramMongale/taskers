# Project Research Summary

**Project:** Taskers SA - Multi-Tier Task Marketplace
**Domain:** Two-sided marketplace with user verification and tier system
**Researched:** 2026-02-11
**Confidence:** MEDIUM-HIGH

## Executive Summary

This is a multi-tier task marketplace extending an existing Flutter/Firebase platform to support three user types: regular users, verified students (for shift work), and verified professionals (for licensed trades). The recommended approach is **additive architecture** - extending the existing working system with new optional fields, separate verification flows, and tier-aware components while preserving existing functionality. This allows a 1-2 week investor demo timeline without breaking production.

The critical path requires three parallel tracks: (1) Tier infrastructure with backward-compatible schema changes and migration, (2) Document verification system with proper security from day one, (3) Payment integration using Paystack for ZAR transactions. The architecture must handle dual-state user records (Firebase Auth custom claims + Firestore documents) to enable offline access and avoid performance bottlenecks from excessive permission checks.

Key risks center on schema migration breaking existing users, verification document security vulnerabilities, and payment webhook race conditions. These are all preventable through proper foundation work in Phase 1 (migration scripts, Firebase Storage security rules, webhook idempotency) before rushing to feature implementation. The research shows this is achievable in the tight timeline if scope is ruthlessly controlled to core tier differentiation only - advanced features like shift scheduling, portfolio showcases, and smart matching should be deferred to post-demo.

## Key Findings

### Recommended Stack

The existing stack is well-suited for the tier expansion: Flutter 3.x with Firebase provides the necessary authentication, database, and storage infrastructure. The critical addition is Paystack integration for ZAR payment processing with proper webhook signature verification.

**Core technologies:**
- **Flutter 3.x + Dart 3.3.0+**: Cross-platform mobile framework already in place with Material Design 3 UI
- **Firebase Suite**: Core 3.14.0, Auth 5.3.5, Firestore 5.6.9, Storage 12.4.7, Messaging 15.2.2 - provides authentication, real-time database, file storage, and push notifications
- **Paystack API**: ZAR payment gateway for tier upgrades and professional verification fees - requires HMAC-SHA512 signature generation using `crypto` 3.0.3
- **Cloud Functions 4.5.4**: Serverless backend for webhook handling, verification workflows, and custom claims management
- **WebView Flutter 4.8.0**: Embedded browser for Paystack payment pages (Android 3.16.0 + iOS WKWebView 3.13.0)

**Critical version requirements:**
- Android API 23+ minimum (current target: API 35)
- iOS 11+ deployment target
- Firebase Auth custom claims require Cloud Functions with Admin SDK
- Firestore composite indexes must be deployed before tier queries

### Expected Features

**Must have (table stakes for student tier):**
- Shift scheduling with time slots and hourly rates (not fixed-price tasks)
- Student verification via university email domain (@uct.ac.za, @wits.ac.za, etc.)
- Availability calendar showing when students can work
- Multiple worker booking (e.g., "Need 5 bartenders for Friday night")
- Shift confirmation/check-in to prove attendance
- Tier badges visible on profiles and search results

**Must have (table stakes for professional tier):**
- Credential verification with document upload (license, insurance certificates)
- License number display after verification
- Quote system (professionals assess job before committing to price)
- Job photo upload so professionals can see work before quoting
- Specialization tags (e.g., "residential electrician" vs "industrial")
- Portfolio/past work showcase

**Should have (competitive differentiation):**
- Cross-tier reputation scoring (student work ethic carries over to professional tier)
- Earnings dashboard for tax purposes
- Tier-specific cancellation policies with penalties
- Emergency/urgent job indicators for premium rates

**Defer (v2+ after demo):**
- Smart shift matching algorithms
- Instant payment for students
- Shift swap marketplace
- Background checks integration
- Automated credential verification (SA licensing bodies lack APIs)
- Bidding wars or auction mechanisms (creates race-to-bottom pricing)

### Architecture Approach

The architecture extends the existing Flutter presentation layer → Service layer → Firestore data layer with new tier-aware components. Critical pattern is **additive schema changes** - add optional fields to existing collections rather than breaking changes. This keeps existing users functional while new users select tiers during registration.

**Major components:**
1. **UserTierService (NEW)** - Manages tier selection, upgrade requests, and tier-specific feature access checks; coordinates with VerificationService
2. **VerificationService (NEW)** - Handles document uploads to Firebase Storage, manages verification state machine (pending → reviewing → verified/rejected), triggers admin review workflows
3. **ShiftService (NEW)** - Shift-specific operations separate from TaskService to avoid bloating existing code; filters by `jobType: "shift"` in Firestore
4. **PaystackService (NEW)** - Payment gateway integration with webhook signature verification and idempotency key checking to prevent race conditions
5. **Extended User Model** - Adds `userTier`, `tierDetails` optional fields; stores tier in both Firestore (detailed profile) and Firebase Auth custom claims (offline access)
6. **Extended Task Model** - Adds `jobType`, `requiredTier`, `shiftDetails` optional fields; existing tasks default to `jobType: "task"` and `requiredTier: "any"`

**Data flow pattern:**
User registers → selects tier → if student/professional, prompted for verification → uploads documents to Firebase Storage → creates verification request in Firestore → admin reviews → approval triggers custom claim update in Firebase Auth + Firestore user document update → FCM notification sent → user sees verified badge

**Critical patterns to follow:**
- Service layer abstraction (no direct Firestore queries from UI)
- Feature flags for gradual rollout (toggle incomplete features)
- Tier-aware components with safe defaults (handles null tier data gracefully)
- Verification state machine with complete transitions (no dead-end states)
- Composite Firestore indexes pre-created before deployment

### Critical Pitfalls

1. **Schema Migration Breaking Existing Users** - Adding required tier fields without backfilling causes null reference errors throughout app. Prevention: Make all new fields optional with defaults (`user.tier ?? 'regular'`), write migration script with batch processing, deploy migration BEFORE app update, test with existing production data copies.

2. **Verification Document Storage Security** - Default Firebase Storage rules expose uploaded IDs and licenses via predictable URLs. Prevention: Set strict Storage security rules tied to user auth (`allow read: if request.auth.uid == resource.metadata.userId`), use random UUID filenames (not userId + timestamp), store signed URLs in Firestore, implement document expiry for rejected submissions.

3. **Dual-State User Records (Auth vs Firestore)** - Storing tier only in Firestore requires database query on every permission check, fails offline, and creates race conditions during registration. Prevention: Store tier in both Firebase Auth custom claims (offline-capable, no query needed) AND Firestore (detailed profile), use Cloud Functions to sync both atomically, implement rollback for partial failures.

4. **Paystack Webhook Race Conditions** - Client and webhook both updating tier status simultaneously causes inconsistent financial records. Prevention: Webhook is single source of truth (client only shows loading), use Firestore transactions in webhook handler, implement idempotency keys to detect duplicate webhooks, client polls for tier change instead of updating directly.

5. **Task Visibility Logic Explosion** - Retrofitting tier filters onto existing queries creates unmaintainable conditional logic and missing composite indexes. Prevention: Add `visibleTo: ['student', 'professional']` array field on tasks (single query), define canonical visibility matrix upfront, create composite indexes in `firestore.indexes.json` before deployment, centralize filtering in service layer.

## Implications for Roadmap

Based on research, suggested phase structure for 1-2 week timeline:

### Phase 1: Foundation (Days 1-3)
**Rationale:** Tier infrastructure must be rock-solid before any feature work. Schema changes, migration, and security are irreversible decisions that cause catastrophic failures if rushed. All downstream phases depend on this foundation.

**Delivers:**
- Tier data model with backward-compatible schema
- Migration script for existing users (defaults to `tier: "regular"`)
- Firebase Storage security rules for verification documents
- UserTierService with tier selection and upgrade request methods
- Firebase Auth custom claims integration via Cloud Functions

**Addresses:**
- Core tier system (FEATURES.md: tier badges, tier identification)
- Data model extensibility (ARCHITECTURE.md: additive schema changes)

**Avoids:**
- Schema migration breaking existing users (PITFALLS.md #1)
- Verification document storage security vulnerabilities (PITFALLS.md #2)
- Dual-state user records causing offline failures (PITFALLS.md #3)

**Research needed:** None - established Firebase patterns

### Phase 2: Verification System (Days 4-5)
**Rationale:** Students and professionals can't access tier-specific features without verification. This unblocks both tier workflows simultaneously. Document upload and admin review are critical trust signals for investor demo.

**Delivers:**
- VerificationService with document upload to Firebase Storage
- Verifications collection with complete state machine (pending → reviewing → verified/rejected)
- Document upload UI with image compression
- Verification status display with resubmission flow
- Admin review screen (basic version for manual approval)

**Addresses:**
- Student verification via university email (FEATURES.md: student tier essentials)
- Professional credential verification (FEATURES.md: professional tier essentials)
- Verification state management (ARCHITECTURE.md: verification patterns)

**Avoids:**
- Incomplete verification state machine leaving users stuck (PITFALLS.md #5)
- Document storage without proper security (PITFALLS.md #2, already addressed in Phase 1 but critical here)

**Research needed:** None - standard document management patterns

### Phase 3: Tier-Aware UI (Days 6-7)
**Rationale:** With tier infrastructure and verification in place, surface the tiers to users. This makes the system visible and demonstrates differentiation for investor demo without implementing full feature workflows yet.

**Delivers:**
- Tier selection during registration
- Tier badge components (verified, pending, regular)
- Profile display with tier-specific sections
- Task/shift filtering by required tier
- Tier-aware task posting (selector for who can apply)

**Addresses:**
- Tier identification badges (FEATURES.md: cross-cutting table stakes)
- Tier-specific search filters (FEATURES.md: cross-cutting table stakes)
- Modified task posting and profiles (FEATURES.md: existing features to modify)

**Avoids:**
- Tier display inconsistency across screens (PITFALLS.md #8)
- Task visibility logic explosion (PITFALLS.md #4, foundation laid here)

**Research needed:** None - UI composition patterns

### Phase 4: Shift System OR Payment (Days 8-10) - PICK ONE
**Rationale:** Timeline forces choice between two key differentiators. Shift system demonstrates student tier workflow; payment demonstrates monetization. Recommend SHIFTS for demo because it shows complete user journey, whereas payment can be mocked for demo purposes.

**Option A: Shift System (RECOMMENDED for demo)**
**Delivers:**
- ShiftService with shift creation and acceptance
- Extended Task model with `jobType: "shift"` and `shiftDetails`
- Shift posting form (time range, hourly rate, worker count)
- Shift browsing and filtering
- Shift acceptance flow (instant booking for students)

**Addresses:**
- Shift scheduling with time slots and hourly rates (FEATURES.md: student tier table stakes)
- Multiple worker booking (FEATURES.md: student tier table stakes)
- Availability calendar (simplified: show available times in shift accept flow)

**Option B: Payment System (monetization focus)**
**Delivers:**
- PaystackService with signature generation
- Payment webhook handler with idempotency
- WebView payment flow
- Tier upgrade payment UI

**Avoids:**
- Paystack webhook race conditions (PITFALLS.md #6)

**Research needed for shifts:** None - scheduling patterns well-documented
**Research needed for payment:** Paystack API signature verification method (quick check)

### Phase 5: Polish & Demo Prep (Days 11-14)
**Rationale:** Investors notice bugs and inconsistencies. Better to ship 3 polished features than 6 half-broken ones. This phase ensures demo is reliable and impressive.

**Delivers:**
- Demo accounts in each state (pending student, verified professional, regular user)
- Pre-loaded task/shift history for realistic demo
- Feature flag cleanup (enable all completed features)
- End-to-end testing of registration → verification → tier-specific actions
- Bug fixes from integration testing
- iOS build validation on actual device
- Demo script and dry runs (3x minimum)

**Addresses:**
- Demo data matching feature states (PITFALLS.md #9)
- "Almost done" feature overcommitment (PITFALLS.md #10)
- iOS build configuration issues (PITFALLS.md #7)

**Avoids:**
- Failed demo from untested flows
- Missing composite Firestore indexes causing "Index creation required" errors during demo

**Research needed:** None - testing and validation

### Phase Ordering Rationale

1. **Foundation must come first** - Schema and security mistakes compound. No value in building features on broken foundation.

2. **Verification before UI** - Tier system is meaningless without trust/verification. Must prove users are who they claim.

3. **UI before workflows** - Show tier differentiation visually before implementing complex shift/payment flows. Validates concept for investors.

4. **Shift OR payment, not both** - 1-2 weeks cannot deliver both properly. Shifts demonstrate complete student tier journey (post → browse → accept → confirm), payment can be mocked or explained as "integrated, webhook testing in progress."

5. **Polish is non-negotiable** - Buggy demo destroys credibility. Buffer time prevents catastrophic failures.

**Dependency chain:**
```
Foundation (Phase 1)
    └──enables──> Verification (Phase 2)
                      └──enables──> Tier-aware UI (Phase 3)
                                         └──enables──> Shifts OR Payment (Phase 4)
                                                           └──requires──> Polish (Phase 5)
```

**Critical path risks:**
- iOS build issues discovered late (mitigate: validate in Phase 0 setup)
- Firestore composite indexes not deployed (mitigate: create in Phase 1, deploy immediately)
- Demo accounts not ready (mitigate: create in Phase 5, not last-minute)

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 4 (Payment):** Paystack webhook signature verification - quick API docs check needed to confirm current HMAC-SHA512 method
- **Phase 1 (Foundation):** Firebase Auth custom claims API - verify Cloud Functions syntax hasn't changed since training data cutoff

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Foundation):** Firestore schema extensions - well-documented additive pattern
- **Phase 2 (Verification):** Document upload to Firebase Storage - standard file management
- **Phase 3 (UI):** Tier-aware components - established Flutter conditional rendering
- **Phase 4 (Shifts):** Time-based scheduling - calendar patterns widely documented
- **Phase 5 (Polish):** Testing and demo prep - no research needed

**Recommendation:** Only invoke `/gsd:research-phase` if Paystack API docs are inaccessible or if Cloud Functions custom claims API has changed significantly. Otherwise, standard patterns apply.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Flutter/Firebase stack already implemented and working; Paystack integration well-documented |
| Features | MEDIUM-HIGH | Table stakes identified from established marketplace patterns (Wonolo, Upwork), but not verified against 2026 current state; SA-specific requirements derived from known university/licensing structures |
| Architecture | HIGH | Additive schema pattern is industry standard; service layer abstraction matches existing codebase; validated against actual Taskers SA codebase structure |
| Pitfalls | MEDIUM | Based on common Firebase/Flutter failure modes from training data; specific Paystack webhook issues may have changed; confidence would increase with official Paystack docs verification |

**Overall confidence:** MEDIUM-HIGH

Research is based on established patterns and validated against existing codebase. Primary uncertainty is SA market specifics (university verification methods, professional licensing APIs) and current Paystack API details. Architecture recommendations are sound regardless - risk is in implementation details, not approach.

### Gaps to Address

**During Phase 1 planning:**
- **Firebase Auth custom claims API syntax** - Quick check of Firebase Admin SDK docs to confirm `admin.auth().setCustomUserClaims()` method signature hasn't changed
- **Firestore composite index creation** - Verify indexes are deployable via `firestore.indexes.json` or must be created manually in Firebase Console

**During Phase 2 planning:**
- **SA university email domain list** - Compile complete list of valid @university.ac.za domains for student verification (currently have major ones: UCT, Wits, Stellenbosch, Rhodes, UP, UKZN)
- **Professional licensing bodies** - Validate ECSA (engineers), PIRB (plumbers), SAIEE (electricians) are current authorities for verification

**During Phase 4 planning (if Payment chosen):**
- **Paystack webhook signature verification** - Confirm current method is HMAC-SHA512 with `x-paystack-signature` header; verify ZAR currency support details
- **Paystack test mode behavior** - Understand webhook timing in test mode (instant vs delayed) to test race conditions properly

**During Phase 5 (Demo prep):**
- **Firebase test project setup** - Ensure demo doesn't use production Firebase project (separate project for investor demo data)
- **iOS provisioning profile** - Verify certificate not expiring during demo week

**Not critical for demo (defer to post-demo):**
- Manual credential verification workflow details (can be Firebase Console for MVP)
- Shift check-in mechanism (GPS vs employer confirmation) - decide post-demo based on feedback
- Background check integration options in SA market

## Sources

### Primary (HIGH confidence)
- **Existing Taskers SA codebase** - C:/Users/joram/taskers_new/.planning/codebase/STACK.md - Current Flutter 3.x + Firebase implementation with pubspec.yaml dependencies, build configs, and directory structure
- **Firebase Firestore documentation** (training data through January 2025) - Data modeling best practices, additive schema patterns, security rules, composite indexes
- **Flutter Firebase Integration** (FlutterFire documentation through January 2025) - Firebase Auth custom claims, Firestore queries, Firebase Storage integration patterns

### Secondary (MEDIUM confidence)
- **Marketplace architecture patterns** - Wonolo (student staffing), Instawork (hospitality shifts), Upwork (professional services quotes), Thumbtack (local services verification) - Feature expectations and workflow patterns derived from training data on these platforms
- **Paystack payment gateway** (training data through 2024) - Webhook patterns, signature verification methods, ZAR currency support
- **Flutter/Firebase failure modes** - Common pitfalls from Stack Overflow, GitHub issues, Flutter community discussions through training data cutoff

### Tertiary (LOW confidence, needs verification)
- **South African university email domains** - Inferred from known major universities; complete list needs validation
- **SA professional licensing bodies** - ECSA, PIRB, SAIEE, SACAP identified from training data; current API availability and verification methods unknown
- **2026 Firebase/Flutter version compatibility** - Assuming current versions (Flutter 3.x, Firebase packages ~3-15.x range) remain compatible; breaking changes possible

**Recommend verification before Phase 1:**
1. Firebase Admin SDK docs - Custom claims API syntax
2. Paystack developer docs - Webhook signature verification method
3. Flutter Firebase compatibility matrix - Check pubspec.yaml for any known breaking changes

---
*Research completed: 2026-02-11*
*Ready for roadmap: yes*
