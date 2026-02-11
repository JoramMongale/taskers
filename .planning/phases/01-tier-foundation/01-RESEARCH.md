# Phase 1: Tier Foundation - Research

**Researched:** 2026-02-11
**Domain:** Flutter + Firebase Authentication & Firestore (Tier-based User Classification)
**Confidence:** HIGH

## Summary

Phase 1 implements a three-tier marketplace system (Regular, Student, Professional) for a Flutter app using Firebase Auth custom claims as the primary tier storage mechanism, backed by Firestore for extended tier metadata. The architecture leverages Firebase's built-in role-based access control (RBAC) capabilities through custom claims, which propagate automatically to security rules and are accessible client-side through ID tokens.

The implementation requires careful attention to three critical domains: (1) **Dual-state storage** using both Firebase Auth custom claims (for access control) and Firestore (for profile data), (2) **Zero-downtime migration** of existing users to "regular" tier using Cloud Functions triggers or batch writes, and (3) **Registration flow modification** to capture tier selection during signup using Flutter's Stepper or dropdown widgets with enum-based type safety.

The existing codebase uses Firebase Auth + Firestore with a UserModel that already includes flexible fields (status, isVerified), making tier addition straightforward through additive changes rather than breaking migrations. Firebase SDK versions are current (firebase_auth: ^5.3.5, cloud_firestore: ^5.6.9), supporting all required features including custom claims, batch writes, and onCreate triggers.

**Primary recommendation:** Use Firebase Cloud Functions onCreate trigger to set default "regular" tier custom claims for all new users, implement dual-state storage pattern (custom claims + Firestore), add tier enum to registration form using DropdownButtonFormField, and perform one-time batch migration for existing users during deployment.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| firebase_auth | ^5.3.5 | Authentication + Custom Claims | Official Flutter Firebase plugin, handles custom claims in ID tokens |
| cloud_firestore | ^5.6.9 | User data storage | Official Firestore plugin, required for user profile documents |
| cloud_functions | ^4.5.4 | Server-side tier management | Required for Admin SDK operations (custom claims can only be set server-side) |
| firebase_admin (Node.js) | latest | Custom claims modification | Only way to set custom claims securely from Cloud Functions |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter/material (Badge) | Built-in | Tier badge display | For notification-style badges on profiles |
| shared_preferences | ^2.2.3 (already installed) | Local tier caching | Quick tier access without token parsing |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom Claims | Firestore-only storage | Loses Firebase security rules integration, requires manual role checks everywhere |
| Cloud Functions onCreate | Client-side tier setting | Insecure - clients can't modify custom claims, only Admin SDK can |
| DropdownButtonFormField | Custom multi-select UI | More work, dropdown is Material Design standard for single-selection |
| Badge widget | Chip widget | Chips better for interactive/selectable items, badges better for status display |

**Installation:**
```bash
# Flutter dependencies (already installed)
flutter pub add firebase_auth cloud_firestore cloud_functions

# Cloud Functions setup (if not exists)
firebase init functions
cd functions && npm install firebase-admin firebase-functions
```

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── models/
│   ├── user_model.dart           # Add tier + tierStatus fields
│   └── user_tier.dart             # NEW: enum UserTier, enum TierStatus
├── services/
│   ├── auth_service.dart          # Update registration to include tier
│   └── tier_service.dart          # NEW: Tier management + token refresh
├── screens/auth/
│   └── register_form.dart         # Add tier selection dropdown
├── widgets/
│   ├── tier_badge.dart            # NEW: Display tier badge with verification status
│   └── tier_filter_chips.dart     # NEW: Task filtering by tier
└── screens/tasks/
    └── task_browser_screen.dart   # Add tier filtering

functions/
├── src/
│   ├── index.ts
│   ├── onUserCreate.ts            # NEW: Set default tier on signup
│   └── setCustomClaims.ts         # NEW: Update tier custom claims
└── package.json
```

### Pattern 1: Dual-State Storage (Custom Claims + Firestore)

**What:** Store tier in BOTH Firebase Auth custom claims AND Firestore user document.

**When to use:** Always for tier data. Custom claims enable security rules, Firestore enables queries and UI display.

**Why dual-state:**
- Custom claims: Used by Firebase Security Rules (e.g., "only professionals can bid on professional tasks")
- Firestore: Used for queries (e.g., "show me all students") and profile UI
- Custom claims limited to 1000 bytes (store minimal data)
- Firestore unlimited (store full tier metadata like verification documents)

**Example:**
```dart
// Firestore user document
{
  "uid": "user123",
  "email": "student@example.com",
  "tier": "student",           // Queryable
  "tierStatus": "pending",     // Verification status
  "studentIdUrl": "gs://...",  // Verification document
  "createdAt": Timestamp
}

// Firebase Auth custom claims (set via Cloud Functions)
{
  "tier": "student",
  "tierStatus": "pending"
}
```

**Source:** [Patterns for security with Firebase: supercharged custom claims with Firestore and Cloud Functions](https://medium.com/firebase-developers/patterns-for-security-with-firebase-supercharged-custom-claims-with-firestore-and-cloud-functions-bb8f46b24e11)

### Pattern 2: Enum-Based Type Safety for Tiers

**What:** Use Dart enums for tier and status values to prevent invalid states.

**When to use:** Always for tier-related fields in models, forms, and filters.

**Example:**
```dart
// lib/models/user_tier.dart
enum UserTier {
  regular,
  student,
  professional;

  String get displayName {
    switch (this) {
      case UserTier.regular: return 'Regular';
      case UserTier.student: return 'Student';
      case UserTier.professional: return 'Professional';
    }
  }

  // For Firestore serialization
  static UserTier fromString(String value) {
    return UserTier.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserTier.regular,
    );
  }
}

enum TierStatus {
  none,        // Regular tier (no verification needed)
  pending,     // Verification submitted, awaiting review
  verified;    // Verification approved

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

// Usage in UserModel
class UserModel {
  // Existing fields...
  UserTier tier;
  TierStatus tierStatus;

  // Serialize to Firestore (use .name for strings)
  Map<String, dynamic> toJson() {
    return {
      // existing fields...
      'tier': tier.name,           // "regular", "student", "professional"
      'tierStatus': tierStatus.name, // "none", "pending", "verified"
    };
  }

  // Deserialize from Firestore
  UserModel.fromJson(Map<String, dynamic> json) {
    // existing fields...
    tier = UserTier.fromString(json['tier'] ?? 'regular');
    tierStatus = TierStatus.fromString(json['tierStatus'] ?? 'none');
  }
}
```

**Why enums:**
- Compile-time type safety (no typos like "studnt" vs "student")
- IDE autocomplete for all valid values
- Exhaustive switch statements (compiler warns if you miss a case)
- Self-documenting code

**Sources:**
- [Mastering enum in Flutter – Clean, Scalable & Pro-Level Usage](https://medium.com/@ravi-pai/mastering-enum-in-flutter-clean-scalable-pro-level-usage-32293a294be4)
- [How to Serialize and Deserialize Enum Properties in Dart/Flutter for Firestore](https://www.w3tutorials.net/blog/how-to-manage-serialize-deserialize-an-enum-property-with-dart-flutter-to-firestore/)

### Pattern 3: Zero-Downtime Migration (Lazy Migration)

**What:** Migrate existing users to "regular" tier on-demand during login, not via bulk update.

**When to use:** When you have existing production users and need to add new required fields.

**Why lazy migration:**
- Zero downtime (no maintenance window needed)
- Gradual rollout reduces risk
- Automatically handles inactive users (they migrate when they return)
- No need to track "who's been migrated"

**Example:**
```dart
// lib/services/auth_service.dart
static Future<AuthResult> signInWithEmailAndPassword({
  required String email,
  required String password,
}) async {
  UserCredential result = await _auth.signInWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  if (result.user != null) {
    // Check if user needs migration
    DocumentSnapshot userDoc = await _firestore
      .collection('users')
      .doc(result.user!.uid)
      .get();

    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    // If tier field doesn't exist, migrate user to regular
    if (userData != null && !userData.containsKey('tier')) {
      await _migrateUserToRegularTier(result.user!.uid);
    }

    return AuthResult.success(result.user!);
  }

  return AuthResult.failure("Login failed");
}

static Future<void> _migrateUserToRegularTier(String uid) async {
  // Update Firestore
  await _firestore.collection('users').doc(uid).update({
    'tier': 'regular',
    'tierStatus': 'none',
  });

  // Trigger Cloud Function to update custom claims
  await FirebaseFunctions.instance
    .httpsCallable('setUserTierClaims')
    .call({'uid': uid, 'tier': 'regular', 'tierStatus': 'none'});
}
```

**Alternative: Batch migration for immediate consistency:**
```typescript
// functions/src/migrateExistingUsers.ts (run once via Firebase CLI)
export const migrateExistingUsers = functions.https.onCall(async (data, context) => {
  // Require admin privileges
  if (!context.auth?.token?.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  const usersSnapshot = await admin.firestore().collection('users').get();
  const batch = admin.firestore().batch();

  for (const doc of usersSnapshot.docs) {
    const userData = doc.data();

    // Only migrate users without tier field
    if (!userData.tier) {
      batch.update(doc.ref, {
        tier: 'regular',
        tierStatus: 'none',
      });

      // Set custom claims
      await admin.auth().setCustomUserClaims(doc.id, {
        tier: 'regular',
        tierStatus: 'none',
      });
    }
  }

  await batch.commit();
  return { migrated: usersSnapshot.size };
});

// Call via Firebase CLI: firebase functions:call migrateExistingUsers
```

**Sources:**
- [Migrating users without downtime in your service (The Lazy Migration Strategy)](https://supertokens.com/blog/migrating-users-without-downtime-in-your-service)
- [Cloud Firestore Batch Transactions: How to migrate a large amounts of data](https://medium.com/@hmurari/cloud-firestore-batch-transactions-how-to-migrate-a-large-amounts-of-data-336e61efbe7c)

### Pattern 4: Registration Form with Tier Selection

**What:** Add tier dropdown to registration form using Flutter's DropdownButtonFormField.

**When to use:** During user registration flow, before account creation.

**Example:**
```dart
// lib/screens/auth/register_form.dart
class _RegisterFormState extends State<RegisterForm> {
  // Existing controllers...
  UserTier selectedTier = UserTier.regular; // Default

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Existing fields (name, email, phone, password)...

          const SizedBox(height: 16),

          // NEW: Tier selection dropdown
          DropdownButtonFormField<UserTier>(
            value: selectedTier,
            decoration: InputDecoration(
              labelText: 'Account Type',
              hintText: 'Select your account type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: UserTier.values.map((tier) {
              return DropdownMenuItem<UserTier>(
                value: tier,
                child: Row(
                  children: [
                    Icon(_getTierIcon(tier), size: 20),
                    SizedBox(width: 12),
                    Text(tier.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (UserTier? newTier) {
              if (newTier != null) {
                setState(() => selectedTier = newTier);
              }
            },
            validator: (value) {
              if (value == null) return 'Please select an account type';
              return null;
            },
          ),

          // Info text explaining tiers
          if (selectedTier == UserTier.student || selectedTier == UserTier.professional)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _getTierDescription(selectedTier),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),

          const SizedBox(height: 24),

          // Existing submit button...
        ],
      ),
    );
  }

  IconData _getTierIcon(UserTier tier) {
    switch (tier) {
      case UserTier.regular: return Icons.person;
      case UserTier.student: return Icons.school;
      case UserTier.professional: return Icons.work;
    }
  }

  String _getTierDescription(UserTier tier) {
    switch (tier) {
      case UserTier.regular: return 'Full access to post and complete tasks';
      case UserTier.student: return 'Student verification required. Access to student-exclusive opportunities.';
      case UserTier.professional: return 'Professional verification required. Higher-paying professional tasks.';
    }
  }
}
```

**Sources:**
- [DropdownButtonFormField Flutter Documentation](https://api.flutter.dev/flutter/material/DropdownButton-class.html)
- [Creating a multi-step form in Flutter using the Stepper widget](https://blog.logrocket.com/creating-multi-step-form-flutter-stepper-widget/)

### Pattern 5: Cloud Functions onCreate Trigger for Default Tier

**What:** Automatically set tier custom claims when a new user registers.

**When to use:** Always - ensures every user has tier claims from moment of account creation.

**Example:**
```typescript
// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Automatically set tier custom claims when user is created
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;

  // Read tier from Firestore user document (set by registration form)
  const userDoc = await admin.firestore().collection('users').doc(uid).get();
  const userData = userDoc.data();

  const tier = userData?.tier || 'regular';
  const tierStatus = userData?.tierStatus || 'none';

  // Set custom claims
  await admin.auth().setCustomUserClaims(uid, {
    tier: tier,
    tierStatus: tierStatus,
  });

  console.log(`Set custom claims for user ${uid}: tier=${tier}, status=${tierStatus}`);
});

// Callable function to update tier claims (for admin/verification flows)
export const setUserTierClaims = functions.https.onCall(async (data, context) => {
  // Verify caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { uid, tier, tierStatus } = data;

  // Update custom claims
  await admin.auth().setCustomUserClaims(uid, {
    tier: tier,
    tierStatus: tierStatus,
  });

  // Update Firestore (keep in sync)
  await admin.firestore().collection('users').doc(uid).update({
    tier: tier,
    tierStatus: tierStatus,
  });

  return { success: true };
});
```

**Token refresh client-side (after claims update):**
```dart
// lib/services/tier_service.dart
class TierService {
  static Future<void> refreshUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Force token refresh to get updated custom claims
      await user.getIdToken(true);

      // Reload user to get fresh token
      await user.reload();

      print('User token refreshed with latest custom claims');
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUserClaims() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final idTokenResult = await user.getIdTokenResult();
      return idTokenResult.claims;
    }
    return null;
  }
}
```

**Sources:**
- [Firebase Authentication triggers | Cloud Functions for Firebase](https://firebase.google.com/docs/functions/1st-gen/auth-events)
- [Control Access with Custom Claims and Security Rules | Firebase Authentication](https://firebase.google.com/docs/auth/admin/custom-claims)

### Pattern 6: Tier Badge Widget

**What:** Reusable widget to display tier badge with verification status on user profiles.

**When to use:** User profile screens, task poster/tasker cards, anywhere user tier is displayed.

**Example:**
```dart
// lib/widgets/tier_badge.dart
import 'package:flutter/material.dart';
import '../models/user_tier.dart';

class TierBadge extends StatelessWidget {
  final UserTier tier;
  final TierStatus status;
  final bool showLabel;

  const TierBadge({
    Key? key,
    required this.tier,
    required this.status,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBadgeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getBadgeColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getTierIcon(), size: 16, color: _getBadgeColor()),
          if (showLabel) ...[
            SizedBox(width: 6),
            Text(
              _getBadgeText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getBadgeColor(),
              ),
            ),
          ],
          if (status == TierStatus.verified) ...[
            SizedBox(width: 4),
            Icon(Icons.verified, size: 14, color: Colors.blue),
          ],
        ],
      ),
    );
  }

  Color _getBadgeColor() {
    switch (tier) {
      case UserTier.regular: return Colors.grey;
      case UserTier.student: return Colors.blue;
      case UserTier.professional: return Colors.purple;
    }
  }

  IconData _getTierIcon() {
    switch (tier) {
      case UserTier.regular: return Icons.person;
      case UserTier.student: return Icons.school;
      case UserTier.professional: return Icons.work;
    }
  }

  String _getBadgeText() {
    final tierName = tier.displayName;
    if (tier == UserTier.regular) return tierName;

    switch (status) {
      case TierStatus.none: return tierName;
      case TierStatus.pending: return '$tierName (Pending)';
      case TierStatus.verified: return tierName;
    }
  }
}

// Usage:
TierBadge(
  tier: UserTier.student,
  status: TierStatus.verified,
  showLabel: true,
)
```

**Sources:**
- [Badge class - material library - Dart API](https://api.flutter.dev/flutter/material/Badge-class.html)
- [How to Create Custom Flutter Badge Widget](https://www.getwidget.dev/blog/flutter-badge-widget-component/)

### Pattern 7: Task Filtering by Tier

**What:** Filter task list by required tier using Firestore queries.

**When to use:** Task browser screen, where workers search for eligible tasks.

**Example:**
```dart
// lib/screens/tasks/task_browser_screen.dart
class TaskBrowserScreen extends StatefulWidget {
  @override
  _TaskBrowserScreenState createState() => _TaskBrowserScreenState();
}

class _TaskBrowserScreenState extends State<TaskBrowserScreen> {
  UserTier? selectedTierFilter;

  Stream<List<Task>> _getTasksStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection('tasks')
      .where('status', isEqualTo: 'posted');

    // Filter by required tier if selected
    if (selectedTierFilter != null) {
      query = query.where('requiredTier', isEqualTo: selectedTierFilter!.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Browse Tasks'),
        actions: [
          // Tier filter dropdown
          PopupMenuButton<UserTier?>(
            icon: Icon(Icons.filter_list),
            onSelected: (tier) {
              setState(() => selectedTierFilter = tier);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: null, child: Text('All Tasks')),
              ...UserTier.values.map((tier) {
                return PopupMenuItem(
                  value: tier,
                  child: Row(
                    children: [
                      Icon(_getTierIcon(tier), size: 18),
                      SizedBox(width: 8),
                      Text('${tier.displayName} Only'),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Task>>(
        stream: _getTasksStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final tasks = snapshot.data!;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return TaskCard(task: tasks[index]);
            },
          );
        },
      ),
    );
  }
}
```

**Firestore index requirement:**
```
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "requiredTier", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Sources:**
- [Cloud Firestore | FlutterFire](https://firebase.flutter.dev/docs/firestore/usage/)
- [Best Approach for Filtering & Pagination in FlutterFlow with Firebase](https://community.flutterflow.io/ask-the-community/post/best-approach-for-filtering-pagination-in-flutterflow-with-firebase-LGLFUhrK2hGUoTh)

### Anti-Patterns to Avoid

**❌ Setting custom claims client-side:**
```dart
// NEVER DO THIS - will fail, only Admin SDK can set claims
await FirebaseAuth.instance.currentUser!.setCustomClaims({'tier': 'admin'}); // Doesn't exist
```
**✅ Always set custom claims via Cloud Functions** using Firebase Admin SDK.

**❌ Storing large tier data in custom claims:**
```typescript
// BAD - exceeds 1000 byte limit
await admin.auth().setCustomUserClaims(uid, {
  tier: 'student',
  studentIdDocument: '<base64 image>', // Way too large!
  transcripts: [...] // Too much data
});
```
**✅ Store only access control data** in claims (tier name, status). Store documents/metadata in Firestore.

**❌ Not refreshing token after claims update:**
```dart
// BAD - user won't see new tier until next login (up to 1 hour)
await _callUpdateTierCloudFunction(uid);
// No token refresh - stale claims!
```
**✅ Always force token refresh** after updating claims:
```dart
await _callUpdateTierCloudFunction(uid);
await FirebaseAuth.instance.currentUser!.getIdToken(true); // Force refresh
```

**❌ Using strings instead of enums for tier values:**
```dart
// BAD - typos cause bugs
String tier = 'studnet'; // Typo!
if (tier == 'student') { ... } // Never matches
```
**✅ Use enums** for compile-time safety:
```dart
UserTier tier = UserTier.student; // Typos caught at compile time
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Role-based access control | Custom role checking logic everywhere | Firebase custom claims + Security Rules | Custom claims automatically propagate to security rules; hand-rolled logic is error-prone and must be duplicated |
| User migration | Custom migration tracking table | Lazy migration (check-and-migrate on login) | Migration tracking adds complexity; lazy migration is self-healing and zero-maintenance |
| Tier badge UI | Custom Container with manual styling | Flutter Badge widget or Chip | Material Design compliance, accessibility, built-in theming |
| Enum serialization | Manual string parsing with if/switch | enum.name + fromString helper | Built-in enum.name property is standard, reduces boilerplate |
| Token refresh | Manual timer-based refresh | getIdToken(true) after claims update | Firebase SDK handles token lifecycle; manual refresh risks race conditions |

**Key insight:** Firebase custom claims are PURPOSE-BUILT for access control. Attempting to replicate this with Firestore-only storage means reimplementing authentication, security rules, and token management—a massive undertaking prone to security holes. Always prefer platform features over custom solutions for authentication/authorization.

## Common Pitfalls

### Pitfall 1: Custom Claims Don't Update Immediately

**What goes wrong:** Admin updates user's tier via Cloud Function, but client still sees old tier for up to 1 hour.

**Why it happens:** Firebase Auth ID tokens are JWTs with 1-hour expiry. Custom claims are embedded in the token and don't refresh until token expires or is manually refreshed.

**How to avoid:**
1. Always call `getIdToken(true)` after updating claims server-side
2. Notify client to refresh token (via Cloud Messaging or Firestore listener)
3. For immediate UI updates, read from Firestore (don't rely solely on claims)

**Warning signs:**
- User completes verification but still sees "pending" badge
- Security rules deny access despite tier being updated in Firestore

**Example fix:**
```dart
// After admin approves student verification
await FirebaseFunctions.instance
  .httpsCallable('approveStudentVerification')
  .call({'uid': userId});

// CRITICAL: Force token refresh
await FirebaseAuth.instance.currentUser!.getIdToken(true);
await FirebaseAuth.instance.currentUser!.reload();

// Now claims are fresh
final claims = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
print('Updated tier: ${claims.claims?['tier']}');
```

**Source:** [Control Access with Custom Claims and Security Rules | Firebase Authentication](https://firebase.google.com/docs/auth/admin/custom-claims)

### Pitfall 2: Exceeding 1000-Byte Custom Claims Limit

**What goes wrong:** Cloud Function throws error when setting custom claims: "Custom claims payload should not exceed 1000 bytes."

**Why it happens:** Developers store too much data in claims (verification documents, full profile data, arrays of permissions).

**How to avoid:**
- Store ONLY access control data in claims: tier name, verification status
- Store everything else in Firestore: documents, metadata, history
- Use short string values: "reg" instead of "regular_unverified_account"

**Warning signs:**
- Cloud Function errors when setting claims
- Claims work for regular users but fail for professional users (who have more data)

**Example:**
```typescript
// ❌ BAD - will exceed 1000 bytes
await admin.auth().setCustomUserClaims(uid, {
  tier: 'professional',
  tierStatus: 'verified',
  verificationDocuments: [...], // Too large
  companyInfo: {...},           // Too large
  permissions: [...],           // Too many
});

// ✅ GOOD - minimal claims
await admin.auth().setCustomUserClaims(uid, {
  tier: 'pro',        // Short strings
  status: 'v',        // Single character
});
```

**Source:** [Control Access with Custom Claims and Security Rules | Firebase Authentication](https://firebase.google.com/docs/auth/admin/custom-claims)

### Pitfall 3: Breaking Existing Users During Migration

**What goes wrong:** After deploying tier feature, existing users can't access app—crashes due to missing tier field.

**Why it happens:** New code expects tier field, but existing user documents don't have it.

**How to avoid:**
1. Make tier field nullable initially: `UserTier? tier`
2. Provide fallback: `tier ?? UserTier.regular`
3. Run migration BEFORE deploying code that requires tier
4. Use lazy migration (migrate on login) for zero downtime

**Warning signs:**
- Existing users see crashes on login
- Firestore queries return 0 results after migration
- Security rules deny access to all existing users

**Example safe migration:**
```dart
// BEFORE (existing code)
class UserModel {
  String uid;
  String email;
}

// AFTER (Phase 1 - safe)
class UserModel {
  String uid;
  String email;
  UserTier tier;  // ❌ Breaking change - existing users don't have this!
}

// CORRECT (Phase 1 - backward compatible)
class UserModel {
  String uid;
  String email;
  UserTier? tier;  // ✅ Nullable - won't crash on missing field

  UserModel.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    email = json['email'];
    // Fallback to regular if tier missing (for existing users)
    tier = json['tier'] != null
      ? UserTier.fromString(json['tier'])
      : UserTier.regular;
  }
}
```

**Source:** [Migration Guide | FlutterFire](https://firebase.flutter.dev/docs/migration/)

### Pitfall 4: Forgetting to Update Both Custom Claims AND Firestore

**What goes wrong:** User's tier shows as "verified" in profile (Firestore) but security rules still deny access (custom claims out of sync).

**Why it happens:** Developer updates Firestore document but forgets to update custom claims, or vice versa.

**How to avoid:**
1. Always update both in Cloud Functions (atomic operation)
2. Create helper function that updates both
3. Use Firestore trigger to sync claims when document changes

**Warning signs:**
- User sees correct tier in profile but can't access tier-restricted features
- Security rules logs show "permission denied" despite correct tier in Firestore
- Query results don't match security rule behavior

**Example fix:**
```typescript
// ❌ BAD - only updates one
export const updateUserTier = functions.https.onCall(async (data, context) => {
  const { uid, tier, status } = data;

  // Only updates Firestore - custom claims stale!
  await admin.firestore().collection('users').doc(uid).update({
    tier: tier,
    tierStatus: status,
  });
});

// ✅ GOOD - updates both atomically
export const updateUserTier = functions.https.onCall(async (data, context) => {
  const { uid, tier, status } = data;

  // Update BOTH in same function
  await Promise.all([
    // Update Firestore
    admin.firestore().collection('users').doc(uid).update({
      tier: tier,
      tierStatus: status,
    }),
    // Update custom claims
    admin.auth().setCustomUserClaims(uid, {
      tier: tier,
      tierStatus: status,
    }),
  ]);

  return { success: true };
});
```

**Source:** [Patterns for security with Firebase: supercharged custom claims with Firestore and Cloud Functions](https://medium.com/firebase-developers/patterns-for-security-with-firebase-supercharged-custom-claims-with-firestore-and-cloud-functions-bb8f46b24e11)

### Pitfall 5: Using Custom Claims for UI Logic Without Firestore Fallback

**What goes wrong:** UI shows loading spinner forever when custom claims aren't available yet (new user just signed up, token not refreshed).

**Why it happens:** Developer relies solely on custom claims for UI display, but claims may not be immediately available after registration or updates.

**How to avoid:**
1. Use Firestore as source of truth for UI display
2. Use custom claims only for security rules
3. Implement proper loading states with Firestore fallback

**Warning signs:**
- New users see infinite loading after registration
- Tier badge doesn't appear until user logs out and back in
- Profile screen shows blank/loading state for extended periods

**Example fix:**
```dart
// ❌ BAD - only reads from claims
class ProfileScreen extends StatelessWidget {
  Future<UserTier> _getUserTier() async {
    final claims = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
    return UserTier.fromString(claims.claims?['tier'] ?? 'regular');
  }
}

// ✅ GOOD - reads from Firestore (always up-to-date)
class ProfileScreen extends StatelessWidget {
  Stream<UserTier> _getUserTierStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        return UserTier.fromString(data?['tier'] ?? 'regular');
      });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserTier>(
      stream: _getUserTierStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final tier = snapshot.data!;
        return TierBadge(tier: tier);
      },
    );
  }
}
```

**Source:** [Using Firebase Authentication | FlutterFire](https://firebase.flutter.dev/docs/auth/usage/)

### Pitfall 6: Not Indexing requiredTier Field in Firestore

**What goes wrong:** Task filtering by tier is extremely slow or fails with "requires an index" error.

**Why it happens:** Firestore requires composite indexes for queries with multiple where clauses or orderBy.

**How to avoid:**
1. Create Firestore indexes BEFORE deploying filtering feature
2. Use Firebase console auto-generated index links during development
3. Define indexes in firestore.indexes.json for production

**Warning signs:**
- Task browser screen shows error: "The query requires an index"
- Task list loads slowly (> 2 seconds) even with few tasks
- Filter changes cause long delays

**Example fix:**
```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "requiredTier", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "requiredTier", "order": "ASCENDING" },
        { "fieldPath": "budgetAmount", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Deploy indexes:**
```bash
firebase deploy --only firestore:indexes
```

**Source:** [Best practices for Cloud Firestore | Firebase](https://firebase.google.com/docs/firestore/best-practices)

## Code Examples

Verified patterns from official sources:

### Reading Custom Claims in Flutter
```dart
// Source: https://firebase.flutter.dev/docs/auth/usage/
Future<Map<String, dynamic>?> getUserClaims() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final idTokenResult = await user.getIdTokenResult();
    return idTokenResult.claims;
  }
  return null;
}

// Usage
final claims = await getUserClaims();
final tier = claims?['tier'] ?? 'regular';
final tierStatus = claims?['tierStatus'] ?? 'none';
```

### Setting Custom Claims in Cloud Functions
```typescript
// Source: https://firebase.google.com/docs/auth/admin/custom-claims
import * as admin from 'firebase-admin';

// Set custom claims for a user
await admin.auth().setCustomUserClaims(userId, {
  tier: 'student',
  tierStatus: 'verified'
});

// Verify claims were set
const user = await admin.auth().getUser(userId);
console.log(user.customClaims); // { tier: 'student', tierStatus: 'verified' }
```

### Firestore Security Rules with Custom Claims
```javascript
// Source: https://firebase.google.com/docs/rules/rules-and-auth
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only verified professionals can create professional-tier tasks
    match /tasks/{taskId} {
      allow create: if request.auth != null &&
        (request.resource.data.requiredTier == 'professional'
          ? request.auth.token.tier == 'professional' &&
            request.auth.token.tierStatus == 'verified'
          : true);

      // Only users with matching tier can apply to tasks
      allow update: if request.auth != null &&
        resource.data.requiredTier in ['any', request.auth.token.tier];
    }

    // Users can only read their own tier documents
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId &&
        // Prevent users from changing their own tier
        request.resource.data.tier == resource.data.tier;
    }
  }
}
```

### Firestore Query for Tasks by Tier
```dart
// Source: https://firebase.flutter.dev/docs/firestore/usage/
Query<Map<String, dynamic>> getTasksByTier(UserTier tier) {
  return FirebaseFirestore.instance
    .collection('tasks')
    .where('status', isEqualTo: 'posted')
    .where('requiredTier', whereIn: ['any', tier.name])
    .orderBy('createdAt', descending: true);
}

// Usage
Stream<List<Task>> tasksStream = getTasksByTier(UserTier.student)
  .snapshots()
  .map((snapshot) => snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList());
```

### Batch Migration of Existing Users
```typescript
// Source: https://firebase.google.com/docs/firestore/manage-data/transactions
import * as admin from 'firebase-admin';

async function migrateUsersToRegularTier() {
  const usersSnapshot = await admin.firestore().collection('users').get();
  const batch = admin.firestore().batch();
  let count = 0;

  for (const doc of usersSnapshot.docs) {
    const userData = doc.data();

    // Only update users without tier field
    if (!userData.tier) {
      batch.update(doc.ref, {
        tier: 'regular',
        tierStatus: 'none',
      });

      // Set custom claims (can't be batched, must be individual)
      await admin.auth().setCustomUserClaims(doc.id, {
        tier: 'regular',
        tierStatus: 'none',
      });

      count++;

      // Firestore batches limited to 500 operations
      if (count % 500 === 0) {
        await batch.commit();
        console.log(`Migrated ${count} users so far...`);
      }
    }
  }

  // Commit remaining operations
  await batch.commit();
  console.log(`Migration complete. Migrated ${count} users total.`);
}
```

### Force Token Refresh After Claims Update
```dart
// Source: https://firebase.flutter.dev/docs/auth/usage/
Future<void> refreshUserToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Force token refresh (pass true to force)
    await user.getIdToken(true);

    // Reload user object
    await user.reload();

    print('Token refreshed with latest custom claims');
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Firestore-only role storage | Custom claims + Firestore dual-state | 2019 (custom claims GA) | Security rules can now check roles without Firestore read (faster, cheaper) |
| Manual enum serialization | Built-in enum.name property | Dart 2.15 (2021) | No more manual toString/fromString boilerplate |
| Provider state management | Riverpod 3.0 | 2024-2025 | Compile-time safety, auto-dispose, less boilerplate |
| Manual form validation | DropdownButtonFormField | Always available | Built-in Form integration, consistent UX |
| Manual JSON parsing | fromJson/toJson generators (json_serializable) | Available since Flutter 1.0 | Type safety, reduces human error |

**Deprecated/outdated:**
- **firebase_core ^2.x**: Old initialization method required platform-specific config files. Current version (^3.14.0) supports Dart-only init with `firebase_options.dart`.
- **String-based enum parsing**: Previously required custom `switch` statements. Now use `enum.name` property (Dart 2.15+).
- **InheritedWidget for state**: Still works but verbose. Provider (v6.1.5) or Riverpod (v3.0) are current standards.
- **Functions v1 API**: Cloud Functions for Firebase 2nd gen now available (better performance, lower cost). Prefer `onCall` over `https.onRequest` for callable functions.

## Open Questions

### 1. **Should we implement phone verification for students instead of document upload?**
   - **What we know:** South African students have .ac.za email addresses (verifiable domain)
   - **What's unclear:** Is email domain verification sufficient, or do we need additional proof?
   - **Recommendation:** Phase 1 uses tier selection only (no verification). Phase 2 adds verification. Start with email domain check (.ac.za) as it's instant and free. Add document upload as fallback for non-.ac.za students.

### 2. **How should tier filter interact with location filter in task browser?**
   - **What we know:** Task queries need `status`, `requiredTier`, `location`, `createdAt` fields
   - **What's unclear:** Firestore composite indexes can get expensive with many combinations
   - **Recommendation:** Create indexes for most common query patterns. Use client-side filtering for rare combinations. Monitor Firestore usage to optimize.

### 3. **Should "regular" tier have an explicit badge or no badge?**
   - **What we know:** UI patterns vary - some apps show all badges, others only show special tiers
   - **What's unclear:** User research needed on South African market preferences
   - **Recommendation:** Phase 1 shows badge for all tiers (consistency). A/B test in Phase 2 to see if hiding regular badge increases student/professional conversions.

### 4. **What happens to tasks in-progress when user upgrades tier?**
   - **What we know:** User might be working on a task, then get tier upgraded mid-task
   - **What's unclear:** Should tier change affect existing task assignments?
   - **Recommendation:** Tier changes only affect NEW task eligibility. Existing assignments unaffected. This prevents disruption and maintains trust.

### 5. **Should custom claims include timestamp of last verification?**
   - **What we know:** Custom claims limited to 1000 bytes
   - **What's unclear:** Is verification timestamp needed for security rules? (e.g., "verified in last 12 months")
   - **Recommendation:** Phase 1: No timestamp in claims. Store in Firestore only. Phase 2: Add if security rules need it (use Unix timestamp to save bytes).

## Sources

### Primary (HIGH confidence)
- [Control Access with Custom Claims and Security Rules | Firebase Authentication](https://firebase.google.com/docs/auth/admin/custom-claims) - Official Firebase docs on custom claims, verified February 2026
- [Using Firebase Authentication | FlutterFire](https://firebase.flutter.dev/docs/auth/usage/) - Official Flutter Firebase plugin docs
- [Cloud Firestore | FlutterFire](https://firebase.flutter.dev/docs/firestore/usage/) - Official Firestore Flutter docs
- [Firebase Authentication triggers | Cloud Functions](https://firebase.google.com/docs/functions/1st-gen/auth-events) - Official Cloud Functions docs
- [Transactions and batched writes | Firestore](https://firebase.google.com/docs/firestore/manage-data/transactions) - Official batch operations docs
- [DropdownButton class - material library - Dart API](https://api.flutter.dev/flutter/material/DropdownButton-class.html) - Official Flutter Material docs
- [Badge class - material library - Dart API](https://api.flutter.dev/flutter/material/Badge-class.html) - Official Flutter Badge widget docs

### Secondary (MEDIUM confidence)
- [Patterns for security with Firebase: supercharged custom claims with Firestore and Cloud Functions](https://medium.com/firebase-developers/patterns-for-security-with-firebase-supercharged-custom-claims-with-firestore-and-cloud-functions-bb8f46b24e11) - Firebase Developer Relations (Doug Stevenson), architectural patterns
- [Tutorial: Advanced Firebase Auth with Custom Claims | Fireship.io](https://fireship.io/lessons/firebase-custom-claims-role-based-auth/) - Verified tutorial from Firebase community expert
- [How to Create Role-Based Access Control (RBAC) with Custom Claims Using Firebase Rules](https://www.freecodecamp.org/news/firebase-rbac-custom-claims-rules/) - FreeCodeCamp verified tutorial
- [Mastering enum in Flutter – Clean, Scalable & Pro-Level Usage](https://medium.com/@ravi-pai/mastering-enum-in-flutter-clean-scalable-pro-level-usage-32293a294be4) - Community best practices for enums
- [How to Serialize and Deserialize Enum Properties in Dart/Flutter for Firestore](https://www.w3tutorials.net/blog/how-to-manage-serialize-deserialize-an-enum-property-with-dart-flutter-to-firestore/) - Firestore enum serialization patterns
- [Creating a multi-step form in Flutter using the Stepper widget](https://blog.logrocket.com/creating-multi-step-form-flutter-stepper-widget/) - LogRocket tutorial on multi-step forms
- [Migrating users without downtime in your service (The Lazy Migration Strategy)](https://supertokens.com/blog/migrating-users-without-downtime-in-your-service) - Zero-downtime migration patterns
- [Cloud Firestore Batch Transactions: How to migrate a large amounts of data](https://medium.com/@hmurari/cloud-firestore-batch-transactions-how-to-migrate-a-large-amounts-of-data-336e61efbe7c) - Batch migration strategies

### Tertiary (LOW confidence - requires validation)
- [Best Flutter State Management Libraries 2026](https://foresightmobile.com/blog/best-flutter-state-management) - Market analysis (mentions Riverpod 3.0, Provider legacy status)
- [Top Flutter Widget Badge packages | Flutter Gems](https://fluttergems.dev/badge/) - Community package directory (package popularity, not official recommendations)

## Metadata

**Confidence breakdown:**
- **Standard stack: HIGH** - All libraries are official Firebase/Flutter packages with verified version numbers from existing pubspec.yaml
- **Architecture patterns: HIGH** - All patterns sourced from official Firebase docs and verified community experts (Fireship, Firebase DevRel)
- **Pitfalls: MEDIUM-HIGH** - Based on official documentation warnings + community experience (Fireship, Medium articles). Token refresh latency verified in official docs, others based on common reported issues.
- **Code examples: HIGH** - All examples adapted from official Firebase/Flutter documentation with source URLs provided

**Existing codebase analysis:**
- Flutter SDK: 3.3.0+ (current)
- Firebase packages: Up-to-date as of July 2025 (firebase_auth ^5.3.5, cloud_firestore ^5.6.9)
- Existing UserModel: Has flexible structure (nullable fields, extensible), supports additive changes
- Existing auth flow: Email/password with verification, uses SharedPreferences for caching
- No Cloud Functions directory found - will need `firebase init functions`

**Research date:** 2026-02-11
**Valid until:** 2026-04-11 (60 days - Firebase/Flutter are stable ecosystems with infrequent breaking changes)
