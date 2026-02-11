# Roadmap: Taskers SA

## Overview

Transform the existing task marketplace into a three-tier platform distinguishing regular users, verified students (shift work), and verified professionals (licensed trades). The journey moves from foundational tier infrastructure through parallel verification systems, then implements tier-specific workflows (student shifts, professional quotes), integrates payments, and culminates in investor-ready demo with iOS/Android builds. Aggressive 1-2 week timeline requires ruthless focus on demo-critical features only.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Tier Foundation** - Multi-tier infrastructure with backward-compatible schema
- [ ] **Phase 2: Verification System** - Document upload and verification flows for students and professionals
- [ ] **Phase 3: Student Shifts** - Shift-based job postings with time slots and multi-worker booking
- [ ] **Phase 4: Professional Services & Payments** - Quote system, specializations, and Paystack integration
- [ ] **Phase 5: Launch Readiness** - iOS/Android builds and investor demo preparation

## Phase Details

### Phase 1: Tier Foundation
**Goal**: Users can select and display tier identity (regular, student, professional) throughout platform
**Depends on**: Nothing (first phase)
**Requirements**: TIER-01, TIER-02, TIER-03, TIER-04, TIER-05, TIER-06, TIER-07
**Success Criteria** (what must be TRUE):
  1. New user can select tier during registration (regular, student, professional)
  2. Existing users migrated to "regular" tier automatically without breaking app
  3. User profile displays tier badge (regular, student-pending, student-verified, professional-pending, professional-verified)
  4. Employer posting task can specify required tier for job (any, student, professional)
  5. Worker browsing tasks can filter by required tier matching their own
**Plans**: TBD

Plans:
- [ ] TBD during plan-phase

### Phase 2: Verification System
**Goal**: Students and professionals can verify credentials and receive verification badges
**Depends on**: Phase 1
**Requirements**: STU-01, STU-02, STU-03, STU-04, STU-05, PRO-01, PRO-02, PRO-03, PRO-04, PRO-05, PRO-06, PRO-07, PRO-08
**Success Criteria** (what must be TRUE):
  1. Student can verify account using university email domain (@uct.ac.za, @wits.ac.za, etc.)
  2. Student receives verification badge after email confirmation
  3. Student can upload additional documents (student card) for review
  4. Professional can upload credential documents (license, certificate, insurance)
  5. Admin can review verification requests and approve/reject with notes
  6. Professional receives verification badge and license number displays on profile
**Plans**: TBD

Plans:
- [ ] TBD during plan-phase

### Phase 3: Student Shifts
**Goal**: Employers can post shift-based jobs and students can accept shift slots
**Depends on**: Phase 2
**Requirements**: SHIFT-01, SHIFT-02, SHIFT-03, SHIFT-04, SHIFT-05, SHIFT-06
**Success Criteria** (what must be TRUE):
  1. Employer can post shift with time range, hourly rate, and number of workers needed
  2. Student can browse shifts filtered by date/time availability
  3. Student can accept available shift slot (instant booking)
  4. System prevents overbooking (enforces max workers per shift)
  5. Student profile shows shift availability calendar
**Plans**: TBD

Plans:
- [ ] TBD during plan-phase

### Phase 4: Professional Services & Payments
**Goal**: Professionals can quote on jobs with photos and employers can pay via Paystack
**Depends on**: Phase 3
**Requirements**: SERV-01, SERV-02, SERV-03, SERV-04, SERV-05, PAY-01, PAY-02, PAY-03, PAY-04, PAY-05, PAY-06
**Success Criteria** (what must be TRUE):
  1. Professional can add specialization tags (e.g., "residential electrician")
  2. Employer can post job with photo uploads for professionals to assess
  3. Professional can submit quote with estimated cost and timeline
  4. Employer can accept quote and pay via Paystack WebView (ZAR)
  5. Payment webhook verifies transaction and updates Firestore with idempotency
  6. Worker receives payment confirmation notification
**Plans**: TBD

Plans:
- [ ] TBD during plan-phase

### Phase 5: Launch Readiness
**Goal**: iOS and Android builds tested and demo accounts ready for investor presentation
**Depends on**: Phase 4
**Requirements**: BUILD-01, BUILD-02, BUILD-03, BUILD-04, DEMO-01, DEMO-02, DEMO-03, DEMO-04, DEMO-05, DEMO-06
**Success Criteria** (what must be TRUE):
  1. iOS build configured and testable via TestFlight
  2. Android APK generated and installable on devices
  3. Both platforms tested with Firebase configuration and payment flow (test mode)
  4. Demo accounts exist for each tier state (regular, pending student, verified professional)
  5. Sample tasks and shifts pre-loaded for realistic demo
  6. Three dry run demos completed before investor presentation
**Plans**: TBD

Plans:
- [ ] TBD during plan-phase

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Tier Foundation | 0/TBD | Not started | - |
| 2. Verification System | 0/TBD | Not started | - |
| 3. Student Shifts | 0/TBD | Not started | - |
| 4. Professional Services & Payments | 0/TBD | Not started | - |
| 5. Launch Readiness | 0/TBD | Not started | - |

---
*Roadmap created: 2026-02-11*
*Last updated: 2026-02-11*
