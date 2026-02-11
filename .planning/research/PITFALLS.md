# Pitfalls Research: Task Marketplace Tier Expansion

**Domain:** Two-sided marketplace with verification and tier system
**Researched:** 2026-02-11
**Confidence:** MEDIUM (based on training data patterns, official docs not accessible)
**Timeline context:** 1-2 week sprint for investor demo

## Critical Pitfalls

### Pitfall 1: Schema Migration Breaking Existing Users

**What goes wrong:**
Adding `userType` or `tier` fields to existing user documents causes null reference errors throughout the app. Existing users suddenly can't view tasks, accept jobs, or complete transactions because the code assumes these fields exist.

**Why it happens:**
- Developers add new required fields without backfilling existing documents
- No graceful fallback when fields are missing
- Testing only with new accounts that have the fields populated
- Under time pressure, migration scripts are skipped or incomplete

**How to avoid:**
1. Make all new fields optional with sensible defaults in code
2. Write and test migration script BEFORE deploying new code
3. Use Firestore batch writes (max 500 docs) or Cloud Functions for backfill
4. Add defensive checks: `user.tier ?? 'student'` not `user.tier`
5. Deploy migration before app update, not simultaneously

**Warning signs:**
- Code review shows direct field access without null checks
- No migration script in commit
- "We'll add it in production after" mentality
- Testing only creates new users, doesn't test with existing accounts

**Phase to address:**
Phase 1 (Foundation) - Schema design and migration strategy must be bulletproof before ANY feature work

**Demo impact:** CRITICAL - Existing test accounts become unusable mid-demo

---

### Pitfall 2: Verification Document Storage Security

**What goes wrong:**
Student ID photos, professional licenses stored in Firebase Storage with public URLs or insufficient access rules. Documents leak via predictable URLs or remain accessible after user deletion.

**Why it happens:**
- Default Firebase Storage rules too permissive
- Quick implementation uses public URLs for simplicity
- File naming patterns are predictable (userId + timestamp)
- Cleanup logic not implemented for rejected verifications
- Under deadline, security rules are "TODO for later"

**How to avoid:**
1. Use Firebase Storage security rules tied to user auth: `allow read: if request.auth.uid == resource.metadata.userId`
2. Generate random UUIDs for filenames, not predictable patterns
3. Store download URLs in Firestore, don't construct from patterns
4. Implement document expiry/deletion for rejected submissions
5. Test with unauthenticated requests to verify protection

**Warning signs:**
- File paths include user IDs or sequential numbers
- Storage rules use `allow read, write: if true`
- Direct Storage URLs used in UI instead of signed URLs
- No document retention policy

**Phase to address:**
Phase 1 (Foundation) - Security MUST be in place before any verification documents are uploaded

**Demo impact:** HIGH - Security audit during investor diligence reveals exposed PII

---

### Pitfall 3: Dual-State User Records (Auth vs Firestore)

**What goes wrong:**
User tier stored only in Firestore, not in custom claims. Every action requires Firestore read to check permissions. Race conditions on registration: Firebase Auth user created but Firestore document creation fails, leaving orphaned auth accounts without tier data.

**Why it happens:**
- Misunderstanding Firebase Auth custom claims feature
- Not accounting for offline scenarios
- Registration flow doesn't handle partial failures
- No rollback mechanism when Firestore write fails after Auth creation

**How to avoid:**
1. Store tier in both Firebase Auth custom claims AND Firestore
2. Use Cloud Functions to sync: `admin.auth().setCustomUserClaims(uid, {tier: 'professional'})`
3. Read tier from ID token claims (offline-capable, no extra query)
4. Use Firestore for detailed profile, claims for access control
5. Implement proper transaction: Cloud Function creates both or rolls back

**Warning signs:**
- Every button/action starts with Firestore query to check tier
- No custom claims set during registration
- Client-side "isStudent" check queries Firestore
- "Works online but breaks offline" reports during testing

**Phase to address:**
Phase 1 (Foundation) - Auth architecture must handle dual-state from start

**Demo impact:** CRITICAL - Slow permission checks make app feel laggy; offline demo fails

---

### Pitfall 4: Task Visibility Logic Explosion

**What goes wrong:**
Adding "students can only see student-appropriate tasks" creates complex query logic that breaks existing task browsing. Queries become unmaintainable: `where('tier', 'in', ['student', 'any'])` misses edge cases. Performance degrades as multiple compound queries replace simple `orderBy('createdAt')`.

**Why it happens:**
- Retrofit tier filtering onto existing query architecture
- Not using Firestore composite indexes correctly
- Forgetting existing "featured," "nearby," "category" filters
- Each screen's query modified independently (inconsistent logic)
- Under pressure, quick fixes create technical debt

**How to avoid:**
1. Define canonical task visibility rules upfront (matrix: student sees X, professional sees Y)
2. Add `visibleTo: ['student', 'professional']` array field on tasks (single query)
3. Create composite indexes in `firestore.indexes.json` before deploying
4. Centralize filtering logic in shared repository/service layer
5. Test each user type against all existing filters (nearby + category + tier)

**Warning signs:**
- Multiple different tier-checking patterns across screens
- Console shows "index creation required" warnings in production
- Task lists show different results on different screens
- Query logic has deeply nested if/else for tier combinations

**Phase to address:**
Phase 2 (Data model) - Before ANY UI work, nail down visibility architecture

**Demo impact:** HIGH - Investors see "Index creation in progress" errors or empty task lists

---

### Pitfall 5: Incomplete Verification State Machine

**What goes wrong:**
Verification flows missing critical states. User submits document → approved/rejected only. No handling for: re-submission after rejection, document expiry, admin review queue states, user cancellation. UI shows "pending" forever with no way to check status or resubmit.

**Why it happens:**
- Implementing only happy path under time pressure
- Forgetting rejected users need re-verification path
- No admin tooling to review queue (manual Firebase Console editing)
- State transitions not thought through completely

**How to avoid:**
1. Design complete state machine BEFORE coding: `draft → pending → reviewing → approved/rejected/expired`
2. Each state has clear: UI display, user actions, admin actions, automatic transitions
3. Include re-submission flow from day one (not "later enhancement")
4. Add `verificationHistory` subcollection to track attempts and reasons
5. Build admin review screen in Phase 1 (even basic version)

**Warning signs:**
- Verification document only has `status` field (no timestamps, no history)
- No "Resubmit" button in rejected state
- Plan says "admin reviews in Firebase Console manually"
- No transition logic for expired documents

**Phase to address:**
Phase 1 (Foundation) - Complete state machine prevents rewrite

**Demo impact:** MEDIUM - Can demo happy path, but questions about edge cases reveal gaps

---

### Pitfall 6: Paystack Webhook Race Conditions

**What goes wrong:**
Payment webhook arrives before client-side confirmation. User completes tier upgrade payment, webhook updates Firestore, but client shows error because its update attempt conflicts. Or reverse: client updates first, webhook fails silently, financial records inconsistent with user tier.

**Why it happens:**
- Client and webhook both write to same document without coordination
- Not using Firestore transactions properly
- Webhook failure handling is "log and hope"
- No idempotency keys on webhook processing
- Testing only with instant payments (webhook timing varies in production)

**How to avoid:**
1. Single source of truth: Webhook is authoritative, client only shows loading state
2. Use Firestore transactions in webhook handler: read current state, validate, update
3. Implement idempotency: store `paystack_reference` to detect duplicate webhooks
4. Client polls for tier change after payment, doesn't update directly
5. Add webhook retry handling and dead letter queue for failures

**Warning signs:**
- Both client and Cloud Function have code to "mark tier as upgraded"
- No transaction wrapping in webhook handler
- Testing uses Paystack test mode with instant confirmations only
- No `processedWebhooks` collection to track duplicates

**Phase to address:**
Phase 3 (Payment integration) - Critical before connecting real payments

**Demo impact:** HIGH - Demo transactions work, but production will have payment/tier mismatches

---

### Pitfall 7: iOS Build Configuration Hell

**What goes wrong:**
Under time pressure, iOS build breaks right before demo. Signing certificates expired, provisioning profiles invalid, new Firebase entitlements not configured. Build works on one machine, fails on CI/CD or teammate's machine. "Works in simulator" but crashes on device.

**Why it happens:**
- Firebase Auth/Storage require specific iOS entitlements
- Adding CloudKit or Push Notifications changes capabilities
- Certificate management not automated
- Different Xcode versions between team members
- "Fix later" approach to build warnings

**How to avoid:**
1. Build iOS FIRST before adding features (validate baseline works)
2. Automate signing: use match (fastlane) or Xcode Cloud
3. Update `ios/Runner/Info.plist` for new Firebase services immediately
4. Document exact Xcode version team uses (in README)
5. Build on actual device daily, not just simulator
6. Address ALL Xcode warnings immediately (they cascade)

**Warning signs:**
- "iOS build broken" status for >2 days
- Manual certificate sharing via Slack
- Works on one dev's machine only
- Dozens of ignored Xcode warnings
- "We'll test on device later" during sprint

**Phase to address:**
Phase 0 (Setup) - Before sprint starts, ensure iOS builds cleanly

**Demo impact:** CRITICAL - Can't demo if app won't install on device

---

### Pitfall 8: Tier Display Inconsistency

**What goes wrong:**
User tier shown inconsistently across app. Profile screen shows "Professional," task list shows "Student," settings shows neither. After upgrading, some screens still show old tier until app restart. Cache invalidation not considered.

**Why it happens:**
- Tier data fetched independently on each screen
- No global state management for user profile
- LocalStorage/SharedPreferences not invalidated on tier change
- Some widgets read from Firestore, others from Auth claims
- Quick feature adds don't update all display locations

**How to avoid:**
1. Single source of truth in app state (Provider/Bloc/Riverpod)
2. All tier displays read from global user state, never query directly
3. Tier changes trigger full profile refresh in state management
4. Search codebase for all tier display logic before launch
5. Add E2E test: upgrade tier, navigate to every screen, verify display

**Warning signs:**
- Grep shows `user.tier` or `userDoc['tier']` in 10+ files
- No central UserProvider or UserBloc
- Tier change function doesn't update in-memory state
- Manual testing finds inconsistencies

**Phase to address:**
Phase 2 (Data model) - State management architecture prevents this

**Demo impact:** MEDIUM - Looks unpolished, investors notice lack of attention to detail

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcode "student" for all existing users | Skip migration script complexity | Manual tier assignment for every user; support burden | Never - migration is straightforward |
| Skip verification re-submission flow | Save 1-2 days development | Users stuck after rejection; support tickets flood | Never - required for usability |
| Manual admin verification in Firebase Console | No admin UI needed | Doesn't scale; slow verification times | Only for MVP with <10 verifications/day |
| Client-side tier display without server validation | Simpler code flow | Users can manipulate tier in local state | Never - security risk |
| Public Firebase Storage URLs | Faster implementation | Security vulnerability, PII exposure | Never - security critical |
| Webhook logging without retry | Simple webhook handler | Lost payments, inconsistent data | Never - financial accuracy required |
| Single "user" collection (no tier subcollections) | Simpler queries | Performance degrades with scale | Acceptable for <10k users |
| Tier stored only in Firestore (not custom claims) | One less place to update | Extra query on every permission check | Only if offline not required |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Firebase Auth custom claims | Setting claims client-side (impossible) | Use Cloud Function with Admin SDK: `admin.auth().setCustomUserClaims()` |
| Firestore compound queries | Creating query before index exists | Add indexes to `firestore.indexes.json`, deploy BEFORE code |
| Firebase Storage URLs | Constructing download URLs from path | Store signed URLs from `getDownloadURL()` in Firestore |
| Paystack webhooks | No signature verification | Validate `req.headers['x-paystack-signature']` against secret |
| Paystack test mode | Assuming instant confirmations | Test webhook delays with tools like ngrok + manual triggers |
| Flutter Firebase packages | Mixing incompatible versions | Use `firebase_core` version table, check compatibility matrix |
| iOS Firebase setup | Missing entitlements for Auth providers | Update `Info.plist` with URL schemes and entitlements |
| Firestore security rules | Rules not deployed with code | Deploy rules in CI/CD: `firebase deploy --only firestore:rules` |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Query all users to check tiers | Slow task list loading | Use `visibleTo` array field on tasks, query tasks not users | >1k users |
| Download all verification docs on admin screen | Admin page timeout | Paginate with `startAfter()`, load 20 at a time | >100 pending verifications |
| No Firestore indexes for tier queries | "Index creation required" error | Pre-create indexes in `firestore.indexes.json` | First production query |
| Fetching user profile on every screen | Excessive reads, slow navigation | Cache in app state management, refresh on change only | >50 daily active users |
| Large verification image uploads | Upload timeouts, storage costs | Compress images client-side before upload (max 2MB) | First HD photo upload |
| Synchronous verification check on task accept | UI freeze during check | Use StreamBuilder/FutureBuilder, show loading state | First task with verification |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Client-side tier checking for payments | User manipulates tier to pay lower rate | Server-side Cloud Function validates tier before Paystack charge |
| Storing payment secrets in Flutter code | Secrets exposed in APK/IPA | Use Cloud Functions for Paystack secret key operations |
| No verification expiry | Fraudulent documents stay valid forever | Add `expiresAt` field, Cloud Function cron job to expire |
| Predictable verification document filenames | Documents guessable via URL manipulation | Random UUID filenames, strict Storage security rules |
| Webhook endpoint without signature check | Fake payment confirmations | Verify `x-paystack-signature` header in webhook handler |
| Tier stored only in Firestore | Users modify tier via Console in dev environment | Also store in Auth custom claims (client can't modify) |
| Verification photo without metadata | Can't prove when/who uploaded document | Store: `uploadedAt`, `uploadedBy`, `ipAddress`, `deviceInfo` |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No loading state during verification upload | User thinks app froze, uploads multiple times | Show progress bar with percentage, "Uploading..." message |
| Rejected verification with no reason | User confused, support tickets | Require admin to select rejection reason, show in UI |
| Tier locked after payment without confirmation | User thinks payment failed | Show success modal: "Payment confirmed! You're now a Professional" |
| Verification required but not explained | User bounces at unexpected gate | Onboarding screen explains tiers and why verification needed |
| Can't preview uploaded verification photo | User uploads wrong image | Show thumbnail with "Change" option before submitting |
| No way to check verification status | Anxious users spam support | Prominent status banner: "Verification in review (typically 24h)" |
| Professional tier more expensive but benefits unclear | Low conversion rate | Comparison table showing features by tier before payment |

## "Looks Done But Isn't" Checklist

- [ ] **Tier migration:** Often missing batch processing for 500+ existing users — verify migration script handles batching
- [ ] **Verification documents:** Often missing cleanup on user deletion — verify Storage lifecycle rules or delete function
- [ ] **Payment webhooks:** Often missing duplicate detection — verify idempotency key checking
- [ ] **iOS build:** Often missing updated provisioning profile — verify builds on clean machine, not just dev laptop
- [ ] **Firestore indexes:** Often missing composite indexes for tier queries — verify `firestore.indexes.json` deployed
- [ ] **Offline support:** Often missing graceful degradation when Firestore offline — verify airplane mode behavior
- [ ] **Error handling:** Often missing user-friendly messages for verification errors — verify all error states have UI
- [ ] **Security rules:** Often missing tier-based read restrictions — verify Firestore rules deny wrong-tier access
- [ ] **Analytics:** Often missing tier upgrade tracking — verify events logged for funnel analysis
- [ ] **Rollback plan:** Often missing data restoration strategy — verify backup before migration

## Demo-Specific Pitfalls

### Pitfall 9: Demo Data Not Matching Feature States

**What goes wrong:**
Demo account is brand new (no history) but features assume usage history. Or demo shows tier upgrade flow but test payment fails during live demo. Verification status in wrong state for demo narrative.

**How to avoid:**
1. Create demo accounts in each state: pending verification, approved student, approved professional
2. Pre-load demo accounts with realistic task history
3. Use Paystack test keys with guaranteed success responses
4. Script demo flow: "First show student account, then switch to professional account"
5. Test full demo flow 3x before investor meeting

**Phase to address:**
Phase 4 (Demo prep) - Week before demo

**Demo impact:** CRITICAL - Failed demo is worse than no demo

---

### Pitfall 10: "Almost Done" Feature Overcommitment

**What goes wrong:**
Roadmap includes shift scheduling, advanced verification, payment history, and tier comparison - too much for 1-2 weeks. Team scrambles to "finish" everything, ships half-baked features that break during demo.

**How to avoid:**
1. Cut scope ruthlessly: Student/Professional tier + basic verification + payment is ENOUGH
2. Polish what ships: 3 features done well > 6 features barely working
3. Hide incomplete features with feature flags, don't rush to production
4. "Better to apologize for not having it than apologize for it breaking"
5. Investor demo shows vision (mockups) for future features, working product for core

**Phase to address:**
Phase 0 (Planning) - Before sprint starts

**Demo impact:** CRITICAL - Buggy demo kills credibility

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Broke existing users with schema change | HIGH - emergency fix needed | 1. Rollback app version immediately 2. Run backfill script 3. Redeploy with null checks 4. Manual testing with old accounts |
| Verification documents exposed publicly | HIGH - security incident | 1. Update Storage rules immediately 2. Rotate all URLs in Firestore 3. Audit access logs 4. Notify affected users |
| Payment webhook missed (tier not upgraded) | MEDIUM - support ticket | 1. Verify payment in Paystack dashboard 2. Manually trigger webhook replay 3. If impossible, run Cloud Function with payment reference |
| iOS build broken before demo | MEDIUM - can demo Android | 1. Use Android device for demo 2. Post-demo: revert to last working commit 3. Re-apply changes incrementally |
| Tier display inconsistent | LOW - visual bug only | 1. Quick fix: force app restart after tier change 2. Proper fix: centralize state management in next sprint |
| Demo account in wrong state | LOW - setup issue | 1. Keep backup demo accounts in all states 2. Switch account during demo if needed 3. Pre-test before investor arrives |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Schema migration breaking existing users | Phase 1: Foundation | Test with existing production data copy; migration runs successfully |
| Verification document storage security | Phase 1: Foundation | Unauthenticated API request to Storage URL returns 403 |
| Dual-state user records (Auth vs Firestore) | Phase 1: Foundation | Offline mode shows correct tier; custom claims set on registration |
| Task visibility logic explosion | Phase 2: Data Model | Single query with `where('visibleTo', 'array-contains')` works for all cases |
| Incomplete verification state machine | Phase 1: Foundation | State diagram covers all transitions; UI exists for each state |
| Paystack webhook race conditions | Phase 3: Payment Integration | Concurrent webhook + client update result in consistent state |
| iOS build configuration hell | Phase 0: Setup | Clean build on CI/CD passes before feature work starts |
| Tier display inconsistency | Phase 2: Data Model | Automated test: upgrade tier, check all screens show new tier |
| Demo data not matching feature states | Phase 4: Demo Prep | Dry-run demo 3 times successfully |
| "Almost done" feature overcommitment | Phase 0: Planning | Roadmap has max 3 core features for 2-week sprint |

## Phase Structure Recommendations

Based on pitfall analysis, phases should be:

1. **Phase 0 (Setup):** iOS build validation, scope lock-in
2. **Phase 1 (Foundation):** Schema design, migration, security, auth architecture
3. **Phase 2 (Data Model):** Tier visibility logic, state management
4. **Phase 3 (Payment):** Paystack integration with proper webhook handling
5. **Phase 4 (Demo Prep):** Demo accounts, dry runs, edge case polish

**DO NOT start Phase 2 until Phase 1 is solid.** Temptation under deadline will be to parallelize, but foundation cracks cause catastrophic demo failures.

## Sources

**Confidence level: MEDIUM-LOW**

Research based on training data patterns (no official docs accessed due to tool restrictions). Key knowledge areas:

- Firebase/Firestore data modeling patterns (training data through 2024)
- Two-sided marketplace architectures (general software engineering knowledge)
- Flutter + Firebase integration patterns (SDK documentation up to training cutoff)
- Paystack integration patterns (payment gateway best practices)
- Mobile build/deployment pitfalls (iOS/Android development experience)

**Verification needed:**
- Current Firebase Auth custom claims API (may have changed)
- Latest Paystack webhook signature verification method
- Flutter Firebase package compatibility matrix for 2026
- Current Firestore security rules syntax

**Recommend:**
- Official Firebase docs verification before Phase 1
- Paystack developer documentation review
- Flutter Firebase package compatibility check in pubspec.yaml

---

*Pitfalls research for: Task Marketplace Tier Expansion*
*Researched: 2026-02-11*
*Scope: 1-2 week investor demo sprint*
