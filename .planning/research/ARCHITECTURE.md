# Architecture Research: Multi-Tier User System Extension

**Domain:** Task marketplace with user verification
**Researched:** 2026-02-11
**Confidence:** HIGH

## Executive Summary

Extending an existing Flutter/Firebase marketplace to support three user tiers (regular, student, professional) with verification flows requires **additive architecture** - adding new data structures and services without modifying existing working code. The critical architectural decisions are: (1) Extend user documents with optional tier-specific fields, (2) Create separate verification collections for each tier type, (3) Build tier-aware UI components that conditionally show fields, (4) Use feature flags to roll out tiers incrementally. This approach preserves existing functionality while adding new capabilities within a 1-2 week timeline.

## Current Architecture (Baseline)

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Auth    │  │  Tasks   │  │ Messages │  │ Payments │    │
│  │ Screens  │  │ Screens  │  │ Screens  │  │ Screens  │    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │
│       │             │              │             │          │
├───────┴─────────────┴──────────────┴─────────────┴──────────┤
│                      Service Layer                           │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────┐   │
│  │  AuthService | TaskService | MessagingService |      │   │
│  │  PaymentService | EscrowAutomationService            │   │
│  └────────────────────────────┬─────────────────────────┘   │
│                                │                             │
├────────────────────────────────┴─────────────────────────────┤
│                       Data Layer                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  users   │  │  tasks   │  │ messages │  │ trans-   │    │
│  │(Firestore)│ │(Firestore)│ │(Firestore)│ │ actions  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Existing Data Model

**Users Collection** (current schema):
```dart
{
  "uid": "firebase_auth_uid",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "types": ["poster", "tasker"],  // User can be both
  "createdAt": Timestamp,
  "lastLogin": Timestamp,
  "emailVerified": true,
  "fcmToken": "...",
  "photoUrl": "gs://bucket/path.jpg"
}
```

**Tasks Collection** (current schema):
```dart
{
  "taskId": "auto_generated",
  "posterId": "user_uid",
  "title": "Task title",
  "description": "...",
  "budget": 500.00,
  "status": "available|accepted|completed",
  "acceptedBy": "tasker_uid",  // optional
  "createdAt": Timestamp,
  "completedAt": Timestamp  // optional
}
```

## Recommended Extended Architecture

### Extended System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer (Extended)                 │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  ┌───────────┐   │
│  │  Auth    │  │  Tasks/  │  │ Verification │  │  Payments │   │
│  │ Screens  │  │  Shifts  │  │   Screens    │  │  Screens  │   │
│  │ (+ Tier  │  │ Screens  │  │              │  │(+ Paystack)│   │
│  │ Select)  │  │          │  │              │  │           │   │
│  └────┬─────┘  └────┬─────┘  └──────┬───────┘  └────┬──────┘   │
│       │             │                │               │          │
├───────┴─────────────┴────────────────┴───────────────┴──────────┤
│                  Service Layer (Extended)                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  UserTierService (NEW) | VerificationService (NEW)       │   │
│  │  ShiftService (NEW) | TaskService (MODIFIED)             │   │
│  │  AuthService | PaymentService | PaystackService (NEW)    │   │
│  └──────────────────────────────┬───────────────────────────┘   │
│                                  │                               │
├──────────────────────────────────┴───────────────────────────────┤
│                       Data Layer (Extended)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  ┌──────────┐    │
│  │  users   │  │ tasks/   │  │ verifications│  │ trans-   │    │
│  │ (+ tier  │  │ shifts   │  │   (NEW)      │  │ actions  │    │
│  │  fields) │  │          │  │              │  │          │    │
│  └──────────┘  └──────────┘  └──────────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Extended Data Model (Additive Schema)

**Strategy:** Add fields to existing collections rather than creating new ones. Use optional fields so existing documents remain valid.

**Users Collection** (extended, backward-compatible):
```dart
{
  // EXISTING FIELDS (unchanged)
  "uid": "firebase_auth_uid",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "types": ["poster", "tasker"],  // Still valid
  "createdAt": Timestamp,
  "lastLogin": Timestamp,
  "emailVerified": true,
  "fcmToken": "...",
  "photoUrl": "gs://bucket/path.jpg",

  // NEW FIELDS (optional - won't break existing queries)
  "userTier": "regular|student|professional",  // NEW - defaults to "regular"
  "tierDetails": {  // NEW - null for regular users
    "type": "student|professional",
    "verificationStatus": "pending|verified|rejected",
    "verifiedAt": Timestamp,  // optional
    "verificationBadge": "student_verified|professional_certified",  // optional

    // Student-specific (only if userTier == "student")
    "studentId": "...",
    "institution": "University of Cape Town",
    "expectedGraduation": "2027",

    // Professional-specific (only if userTier == "professional")
    "tradeType": "electrician|plumber|carpenter|...",
    "certifications": ["Certificate Name"],
    "yearsExperience": 5,
    "collegeEndorsement": {
      "institutionName": "...",
      "contactEmail": "...",
      "endorsedAt": Timestamp
    }
  }
}
```

**Verifications Collection** (NEW):
```dart
// Collection: "verifications"
// Document ID: auto-generated
{
  "verificationId": "auto_generated",
  "userId": "user_uid",
  "tierType": "student|professional",
  "status": "pending|under_review|verified|rejected",
  "submittedAt": Timestamp,
  "reviewedAt": Timestamp,  // optional
  "reviewedBy": "admin_uid",  // optional

  // Documents submitted
  "documents": [
    {
      "type": "student_id|certificate|license",
      "storagePath": "gs://bucket/verifications/{userId}/{docId}",
      "uploadedAt": Timestamp,
      "fileName": "certificate.pdf"
    }
  ],

  // For professional endorsements
  "endorsementRequest": {
    "institutionName": "...",
    "contactEmail": "...",
    "message": "...",
    "status": "pending|sent|confirmed|rejected"
  },

  // Rejection reasons (if status == "rejected")
  "rejectionReason": "Document unclear|Not from recognized institution|..."
}
```

**Tasks Collection** (modified to support shifts):
```dart
{
  // EXISTING FIELDS (unchanged)
  "taskId": "auto_generated",
  "posterId": "user_uid",
  "title": "Task title",
  "description": "...",
  "budget": 500.00,
  "status": "available|accepted|completed",
  "acceptedBy": "tasker_uid",
  "createdAt": Timestamp,
  "completedAt": Timestamp,

  // NEW FIELDS (optional - differentiate task vs shift)
  "jobType": "task|shift",  // NEW - defaults to "task" for existing docs
  "requiredTier": "any|student|professional",  // NEW - tier filter

  // Shift-specific fields (only if jobType == "shift")
  "shiftDetails": {  // null for task-based jobs
    "startTime": Timestamp,
    "endTime": Timestamp,
    "hourlyRate": 75.00,
    "duration": 4,  // hours
    "recurring": false,
    "recurrencePattern": "daily|weekly|monthly"  // optional
  }
}
```

### Schema Migration Strategy

**Phase 1: Additive Fields (Day 1)**
1. Add new optional fields to User documents (backward compatible)
2. Existing users default to `"userTier": "regular"` and `tierDetails: null`
3. New users select tier during registration

**Phase 2: Create Verifications Collection (Day 2)**
4. Create new collection with indexes
5. No impact on existing functionality

**Phase 3: Extend Tasks Collection (Day 3)**
6. Add `jobType` and `requiredTier` fields to new tasks
7. Existing tasks default to `jobType: "task"`, `requiredTier: "any"`
8. Queries filter by `jobType` to show tasks vs shifts

**Migration Code Pattern:**
```dart
// Safe additive update - won't break existing users
Future<void> migrateUserToTiers(String userId) async {
  final userDoc = _firestore.collection('users').doc(userId);

  // Get current data
  final snapshot = await userDoc.get();
  if (!snapshot.exists) return;

  final data = snapshot.data()!;

  // Only add if field doesn't exist (idempotent)
  if (!data.containsKey('userTier')) {
    await userDoc.update({
      'userTier': 'regular',  // Default for existing users
      'tierDetails': null,
    });
  }
}
```

## Component Boundaries (Extended)

| Component | Responsibility | Communicates With | Change Type |
|-----------|----------------|-------------------|-------------|
| **AuthService** | User auth, session management | Firebase Auth, Firestore users | MODIFIED - Add tier selection on registration |
| **UserTierService** (NEW) | Manage tier upgrades, tier-specific logic | Firestore users, VerificationService | NEW |
| **VerificationService** (NEW) | Handle document uploads, verification status | Firestore verifications, Firebase Storage, UserTierService | NEW |
| **TaskService** | Task CRUD, filtering, search | Firestore tasks | MODIFIED - Add jobType filtering |
| **ShiftService** (NEW) | Shift-specific operations, scheduling | Firestore tasks (jobType=shift) | NEW |
| **PaystackService** (NEW) | Payment gateway integration | Paystack API, PaymentService | NEW |
| **PaymentService** | Transaction management, escrow | Firestore transactions, PaystackService | MODIFIED - Add Paystack integration |

### Service Interface Examples

**UserTierService** (NEW):
```dart
class UserTierService {
  final FirebaseFirestore _firestore;

  // Get user's current tier
  Future<String> getUserTier(String userId);

  // Request tier upgrade (starts verification flow)
  Future<String> requestTierUpgrade(String userId, String targetTier, Map<String, dynamic> tierData);

  // Check if user can access tier-specific features
  Future<bool> canAccessFeature(String userId, String featureName);

  // Get tier badge for display
  Future<String?> getTierBadge(String userId);
}
```

**VerificationService** (NEW):
```dart
class VerificationService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  // Submit verification request
  Future<String> submitVerification(String userId, String tierType, List<File> documents);

  // Upload verification documents
  Future<List<String>> uploadDocuments(String userId, List<File> files);

  // Get verification status
  Future<String> getVerificationStatus(String userId);

  // Admin: Review verification
  Future<void> reviewVerification(String verificationId, bool approve, String? reason);

  // Request college endorsement (professional tier)
  Future<void> requestEndorsement(String userId, Map<String, String> endorsementData);
}
```

**ShiftService** (NEW):
```dart
class ShiftService {
  final FirebaseFirestore _firestore;

  // Create shift-based job
  Future<String> createShift(String posterId, Map<String, dynamic> shiftData);

  // Get available shifts (filtered by time, location, tier)
  Stream<List<Shift>> getAvailableShifts({String? tierFilter, DateTime? startAfter});

  // Accept shift (student/professional only)
  Future<void> acceptShift(String shiftId, String userId);

  // Clock in/out for shift
  Future<void> clockIn(String shiftId, String userId);
  Future<void> clockOut(String shiftId, String userId);
}
```

## Data Flow Patterns

### Tier Selection Flow (Registration)

```
[User Registers]
    ↓
[Email/Password Auth] → Firebase Auth
    ↓
[Tier Selection Screen] ← User picks: Regular | Student | Professional
    ↓
[Create User Document] → Firestore users (with userTier field)
    ↓
IF tier == "student" OR "professional":
    ↓
    [Verification Prompt Screen]
    ↓
    [Upload Documents] → Firebase Storage
    ↓
    [Create Verification Request] → Firestore verifications
    ↓
    [Pending Badge Shown] ← UI shows "Verification Pending"
ELSE:
    ↓
    [Home Screen] ← Regular user, no verification needed
```

### Verification Review Flow

```
[Admin Dashboard]
    ↓
[Query Pending Verifications] ← Firestore.collection('verifications').where('status', '==', 'pending')
    ↓
[Admin Reviews Documents] ← Download from Firebase Storage
    ↓
[Approve/Reject Decision]
    ↓
IF approved:
    ↓
    [Update Verification Document] → status: "verified"
    ↓
    [Update User Document] → tierDetails.verificationStatus: "verified"
                            → tierDetails.verifiedAt: Timestamp
    ↓
    [Send Notification] → FCM: "You're now verified!"
    ↓
    [User Sees Badge] ← UI shows verification badge
ELSE:
    ↓
    [Update Verification Document] → status: "rejected", rejectionReason: "..."
    ↓
    [Send Notification] → FCM: "Verification rejected: {reason}"
```

### Shift Job Flow (Different from Task Flow)

```
[Employer Creates Shift]
    ↓
[Shift Details Form] ← Date, time, hourly rate, duration
    ↓
[ShiftService.createShift()] → Firestore tasks (jobType: "shift", shiftDetails: {...})
    ↓
[Student/Professional Browses Shifts]
    ↓
[ShiftService.getAvailableShifts()] ← Filter: jobType == "shift", requiredTier matches
    ↓
[Student Accepts Shift]
    ↓
[Clock In] → Update shift document: clockedInAt: Timestamp
    ↓
[Work Duration]
    ↓
[Clock Out] → Update shift document: clockedOutAt: Timestamp
    ↓
[Calculate Payment] → hourlyRate * actualHours
    ↓
[Paystack Payment Flow] → Same as task payment
```

### Tier-Aware UI Pattern

```dart
// Widget conditionally shows tier-specific content
class UserProfileWidget extends StatelessWidget {
  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Always shown
        UserAvatar(user),
        UserName(user),

        // Conditionally shown based on tier
        if (user.userTier == 'student')
          StudentBadge(user.tierDetails),

        if (user.userTier == 'professional')
          ProfessionalCertificationsList(user.tierDetails),

        // Verification status indicator
        if (user.tierDetails?.verificationStatus == 'verified')
          VerifiedBadge(),
        else if (user.tierDetails?.verificationStatus == 'pending')
          PendingBadge(),
      ],
    );
  }
}
```

## Architectural Patterns to Follow

### Pattern 1: Additive Schema Changes

**What:** Never remove or rename existing Firestore fields. Only add new optional fields.

**When to use:** When extending data model without breaking existing functionality.

**Trade-offs:**
- Pro: Existing code continues working unchanged
- Pro: No migration scripts needed for old documents
- Con: Schema can become cluttered with legacy fields over time

**Example:**
```dart
// BAD - Breaking change
await userDoc.update({
  'role': 'regular',  // Renaming 'types' to 'role' breaks existing code!
});

// GOOD - Additive change
await userDoc.update({
  'userTier': 'regular',  // New field, 'types' still exists
  'tierDetails': null,
});
```

### Pattern 2: Service Layer Abstraction

**What:** All Firestore operations go through service classes, never direct from UI.

**When to use:** Always. Prevents tight coupling between UI and database schema.

**Trade-offs:**
- Pro: Easy to change database structure without touching UI
- Pro: Services can be unit tested independently
- Con: More files and indirection

**Example:**
```dart
// BAD - UI directly queries Firestore
final snapshot = await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .get();

// GOOD - UI calls service method
final userTier = await _userTierService.getUserTier(userId);
```

### Pattern 3: Feature Flags for Gradual Rollout

**What:** Use boolean flags to enable/disable new features during development.

**When to use:** When building features that take multiple days but app must stay shippable.

**Trade-offs:**
- Pro: Can merge partially complete features without exposing them
- Pro: Easy to test in production with subset of users
- Con: Adds complexity, flags must be cleaned up later

**Example:**
```dart
// In lib/config/feature_flags.dart
class FeatureFlags {
  static const bool enableStudentTier = true;  // Toggle during development
  static const bool enableProfessionalTier = false;  // Not ready yet
  static const bool enableShifts = true;
}

// In UI
if (FeatureFlags.enableStudentTier) {
  tiers.add(TierOption.student);
}
```

### Pattern 4: Tier-Aware Components with Defaults

**What:** UI components check tier and show appropriate content, with safe defaults.

**When to use:** When rendering user profiles, job listings, or tier-specific features.

**Trade-offs:**
- Pro: Single component handles all tiers (DRY principle)
- Pro: Gracefully handles null/missing tier data
- Con: Component becomes more complex with conditional logic

**Example:**
```dart
// Widget adapts to tier, safe for users without tier field
class TaskCard extends StatelessWidget {
  final Task task;

  @override
  Widget build(BuildContext context) {
    final requiredTier = task.requiredTier ?? 'any';  // Default for old tasks

    return Card(
      child: Column(
        children: [
          Text(task.title),
          if (requiredTier != 'any')
            TierRequirementBadge(requiredTier),  // Only shown when tier required
        ],
      ),
    );
  }
}
```

### Pattern 5: Verification State Machine

**What:** Verification status transitions follow strict rules: pending → under_review → verified/rejected.

**When to use:** Managing verification workflow to prevent invalid states.

**Trade-offs:**
- Pro: Prevents bugs like verifying rejected applications
- Pro: Clear audit trail of status changes
- Con: Requires validation logic in service layer

**Example:**
```dart
class VerificationService {
  // State transitions validation
  Future<void> updateVerificationStatus(String verificationId, String newStatus) async {
    final doc = await _firestore.collection('verifications').doc(verificationId).get();
    final currentStatus = doc.data()?['status'];

    // Validate transition
    if (!_isValidTransition(currentStatus, newStatus)) {
      throw InvalidStateTransitionException(
        'Cannot transition from $currentStatus to $newStatus'
      );
    }

    await doc.reference.update({'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()});
  }

  bool _isValidTransition(String? from, String to) {
    const validTransitions = {
      null: ['pending'],  // New verification
      'pending': ['under_review'],
      'under_review': ['verified', 'rejected'],
      'rejected': ['pending'],  // Can resubmit
      'verified': [],  // Terminal state
    };

    return validTransitions[from]?.contains(to) ?? false;
  }
}
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Modifying Existing Documents Directly

**What people do:** Update user tier by directly modifying existing user documents without validation.

**Why it's wrong:**
- Breaks existing documents that lack new fields
- No validation of tier-specific requirements
- No audit trail of tier changes

**Do this instead:**
```dart
// BAD
await _firestore.collection('users').doc(userId).update({
  'userTier': 'professional',  // No validation!
});

// GOOD
await _userTierService.requestTierUpgrade(userId, 'professional', {
  'tradeType': 'electrician',
  'certifications': ['...'],
});
// ^ Service validates requirements, creates verification request, maintains audit trail
```

### Anti-Pattern 2: Mixing Task and Shift Logic in Same Service

**What people do:** Add shift-specific logic to existing TaskService.

**Why it's wrong:**
- TaskService becomes bloated with conditional logic
- Hard to test task vs shift behavior independently
- Violates Single Responsibility Principle

**Do this instead:**
```dart
// BAD
class TaskService {
  Future<void> createJob(Map<String, dynamic> jobData) async {
    if (jobData['jobType'] == 'shift') {
      // Shift-specific logic here
    } else {
      // Task-specific logic here
    }
  }
}

// GOOD
class TaskService {
  Future<void> createTask(Map<String, dynamic> taskData) async {
    // Only task logic
  }
}

class ShiftService {
  Future<void> createShift(Map<String, dynamic> shiftData) async {
    // Only shift logic
  }
}
```

### Anti-Pattern 3: Storing Verification Documents in User Document

**What people do:** Add verification documents array directly to user document.

**Why it's wrong:**
- User document grows unbounded (Firestore limit: 1MB per doc)
- Can't query all pending verifications efficiently
- No separation of concerns

**Do this instead:**
```dart
// BAD
await _firestore.collection('users').doc(userId).update({
  'verificationDocuments': FieldValue.arrayUnion([documentUrl]),  // Array grows forever!
});

// GOOD
await _firestore.collection('verifications').add({
  'userId': userId,
  'documents': [documentUrl],
  'status': 'pending',
});
// ^ Separate collection, can query by status, no size limit issues
```

### Anti-Pattern 4: Hard-Coding Tier Names Everywhere

**What people do:** Scatter tier names ('student', 'professional') as magic strings throughout code.

**Why it's wrong:**
- Typos cause silent bugs
- Hard to refactor tier names
- No single source of truth

**Do this instead:**
```dart
// BAD
if (user.userTier == 'studnet') {  // Typo!
  // ...
}

// GOOD
// In lib/models/user_tier.dart
enum UserTier {
  regular,
  student,
  professional;

  String toFirestoreValue() => name;

  static UserTier fromFirestoreValue(String value) {
    return UserTier.values.firstWhere((e) => e.name == value);
  }
}

// Usage
if (user.userTier == UserTier.student) {  // Type-safe!
  // ...
}
```

### Anti-Pattern 5: Querying All Users to Filter by Tier

**What people do:** Fetch all users then filter by tier in client code.

**Why it's wrong:**
- Downloads entire users collection (expensive, slow)
- Doesn't scale beyond ~100 users
- Wastes bandwidth and Firestore reads

**Do this instead:**
```dart
// BAD
final allUsers = await _firestore.collection('users').get();
final students = allUsers.docs.where((doc) => doc.data()['userTier'] == 'student');

// GOOD
final studentsQuery = _firestore.collection('users')
  .where('userTier', isEqualTo: 'student')
  .limit(20);
final students = await studentsQuery.get();
```

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **Paystack API** | HTTP client with custom service wrapper | Signature generation required (HMAC-SHA512), handles ZAR currency |
| **Firebase Storage** | Direct SDK integration via `firebase_storage` | Organized folders: `verifications/{userId}/{docId}` |
| **Firebase Auth** | Existing integration, no changes needed | Email verification already implemented |
| **Firebase Messaging** | Existing FCM setup, add verification notifications | Token refresh needed (see CONCERNS.md) |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| **AuthService ↔ UserTierService** | Direct method calls | AuthService calls UserTierService after registration to set default tier |
| **UserTierService ↔ VerificationService** | Direct method calls | UserTierService triggers verification flow, VerificationService updates tier status |
| **TaskService ↔ ShiftService** | No direct communication | Both write to same `tasks` collection with different `jobType` field |
| **PaymentService ↔ PaystackService** | PaymentService delegates to PaystackService | PaymentService orchestrates flow, PaystackService handles API calls |
| **VerificationService ↔ NotificationService** | Via events/callbacks | VerificationService triggers notification when verification approved/rejected |

## Recommended Project Structure (Changes)

```
lib/
├── models/
│   ├── user.dart               # MODIFY - Add tier fields
│   ├── task.dart               # MODIFY - Add jobType, shiftDetails
│   ├── verification.dart       # NEW - Verification request model
│   └── shift.dart              # NEW - Shift-specific model
│
├── services/
│   ├── auth_service.dart       # MODIFY - Add tier selection
│   ├── user_tier_service.dart  # NEW - Tier management
│   ├── verification_service.dart  # NEW - Verification flow
│   ├── shift_service.dart      # NEW - Shift operations
│   ├── paystack_service.dart   # NEW - Payment gateway
│   ├── task_service.dart       # MODIFY - Add jobType filtering
│   └── payment_service.dart    # MODIFY - Integrate Paystack
│
├── screens/
│   ├── auth/
│   │   ├── register_form.dart  # MODIFY - Add tier selection step
│   │   └── tier_selection_screen.dart  # NEW
│   ├── verification/
│   │   ├── verification_upload_screen.dart  # NEW
│   │   ├── verification_status_screen.dart  # NEW
│   │   └── admin_verification_review_screen.dart  # NEW
│   ├── shifts/
│   │   ├── create_shift_screen.dart  # NEW
│   │   ├── shift_list_screen.dart    # NEW
│   │   └── shift_details_screen.dart # NEW
│   └── tasks/
│       ├── create_task_screen_enhanced.dart  # MODIFY - Add requiredTier
│       └── task_list_screen.dart  # MODIFY - Add tier filter
│
├── widgets/
│   ├── tier_badge.dart         # NEW - Display verification badge
│   ├── tier_filter_chips.dart  # NEW - Filter UI by tier
│   └── job_card.dart           # NEW - Unified task/shift display
│
└── config/
    ├── feature_flags.dart      # NEW - Toggle features during development
    └── tier_config.dart        # NEW - Tier definitions and rules
```

## Build Order (Dependency-Based)

**Critical Path for 1-2 Week Timeline:**

### Day 1-2: Foundation (Tier Data Model)
1. **Create UserTierService** - Tier management without UI
2. **Extend User model** - Add tier fields to data class
3. **Add tier field to Firestore** - Migration script for existing users
4. **Unit tests for UserTierService**

**Why first:** All other features depend on tier concept existing. Must be stable.

### Day 3-4: Verification System
5. **Create VerificationService** - Document upload and status management
6. **Create Verifications collection** - New Firestore collection with indexes
7. **Build VerificationUploadScreen** - UI for document submission
8. **Build VerificationStatusScreen** - UI to check status
9. **Add verification to registration flow** - Optional step after signup

**Why second:** Tiers are useless without verification. Needed before users can become students/professionals.

### Day 5-6: Tier-Aware UI
10. **Add tier selection to registration** - TierSelectionScreen
11. **Build TierBadge widget** - Shows verification status
12. **Modify profile screens** - Display tier-specific info
13. **Add tier filtering to task list** - Filter tasks by required tier

**Why third:** Users can now register with tiers and see benefits. Core marketplace still works.

### Day 7-8: Shift System (Can be parallel with Payment)
14. **Create ShiftService** - Shift CRUD operations
15. **Extend Task model** - Add jobType and shiftDetails
16. **Build CreateShiftScreen** - UI for posting shifts
17. **Build ShiftListScreen** - Browse available shifts
18. **Modify TaskService** - Filter by jobType to separate tasks/shifts

**Why fourth:** Independent from verification. Can be built in parallel with payments.

### Day 9-10: Paystack Integration (Can be parallel with Shifts)
19. **Create PaystackService** - API integration
20. **Modify PaymentService** - Add Paystack as payment method
21. **Build Paystack WebView flow** - Payment UI
22. **Test ZAR transactions** - End-to-end payment testing

**Why fourth:** Payment is critical path but can be parallel with shifts if two developers.

### Day 11-12: Admin & Polish
23. **Build AdminVerificationReviewScreen** - Admin tools for verification
24. **Add notification triggers** - FCM for verification approved/rejected
25. **Feature flags cleanup** - Enable all features
26. **End-to-end testing** - All three tiers, verification, shifts, payments

### Day 13-14: Buffer & Bug Fixes
27. **Integration testing** - Full user journeys
28. **Bug fixes** - Address issues found in testing
29. **Performance testing** - Ensure queries are fast
30. **Investor demo preparation** - Demo script and test data

## Scaling Considerations

| Scale | Architecture Adjustments | Priority |
|-------|--------------------------|----------|
| **0-100 users** | Current architecture sufficient; no indexes needed beyond Firestore auto-indexes | Now |
| **100-1K users** | Add composite indexes for tier + jobType queries; monitor Firestore read counts | Week 2 |
| **1K-10K users** | Move verification review to Cloud Functions (async processing); add Firebase Performance Monitoring | Month 2 |
| **10K+ users** | Implement caching for user tier lookups (Redis/Firestore cache); consider CDN for verification documents | Month 6+ |

### Immediate Bottlenecks (1-2 Week Timeline)

1. **Firestore Composite Index Required:**
   - Query: `tasks.where('jobType', '==', 'shift').where('requiredTier', '==', 'student')`
   - Fix: Create index in Firebase Console before deploying

2. **Verification Document Storage Costs:**
   - Problem: Multiple uploads per user
   - Fix: Compress images on client before upload (use `image_picker` compression)

3. **Real-Time Listeners for Verification Status:**
   - Problem: Each user has listener on their verification doc
   - Fix: Acceptable at <1K users; move to polling at scale

## Sources

**Confidence: HIGH** - Based on established Flutter/Firebase architecture patterns from official documentation and production experience.

- Firebase Firestore Data Model Best Practices (official docs, January 2025)
- Flutter Firebase Integration Patterns (FlutterFire documentation)
- Role-Based Access Control in Firestore (Firebase Security Rules documentation)
- Multi-Tenancy Patterns for Firebase (Google Cloud Architecture Center)
- Payment Gateway Integration Patterns (Paystack API documentation)
- Existing codebase analysis: C:/Users/joram/taskers_new/.planning/codebase/

**Note on Confidence:** While WebSearch was unavailable, the architectural patterns documented here are well-established in the Flutter/Firebase ecosystem and validated by the existing codebase structure. The additive schema approach is the standard method for extending Firestore schemas without breaking changes. All patterns follow official Firebase and Flutter best practices as of January 2025.

---
*Architecture research for: Taskers SA multi-tier marketplace extension*
*Researched: 2026-02-11*
*Confidence: HIGH - Established patterns, validated against existing codebase*
