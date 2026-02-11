# Requirements: Taskers SA

**Defined:** 2026-02-11
**Core Value:** Employers can quickly find and hire verified workers across different skill levels - from students needing part-time shifts to certified electricians for professional jobs.

## v1 Requirements

Requirements for investor demo (1-2 weeks). Each maps to roadmap phases.

### Tier System (Foundation)

- [ ] **TIER-01**: User can select tier during registration (regular, student, professional)
- [ ] **TIER-02**: Tier badge displays on user profile
- [ ] **TIER-03**: User tier stored in both Firebase Auth custom claims and Firestore
- [ ] **TIER-04**: Existing users migrated to "regular" tier automatically
- [ ] **TIER-05**: Task poster can specify required tier for job posting
- [ ] **TIER-06**: Task browser can filter by required tier
- [ ] **TIER-07**: Tier-specific profile sections display based on user tier

### Student Tier Verification

- [ ] **STU-01**: Student can verify account using university email domain
- [ ] **STU-02**: System validates email against approved SA university domains (@uct.ac.za, @wits.ac.za, etc.)
- [ ] **STU-03**: Student receives verification badge after email confirmation
- [ ] **STU-04**: Student profile displays verification status (pending, verified)
- [ ] **STU-05**: Student can upload additional documents (student card, proof of enrollment)

### Student Shifts

- [ ] **SHIFT-01**: Employer can post shift-based job with time range and hourly rate
- [ ] **SHIFT-02**: Shift posting specifies number of workers needed (e.g., "5 bartenders")
- [ ] **SHIFT-03**: Student can browse shift postings with time/date filters
- [ ] **SHIFT-04**: Student can accept available shift slot
- [ ] **SHIFT-05**: System prevents overbooking (max workers per shift enforced)
- [ ] **SHIFT-06**: Student profile shows shift availability calendar

### Professional Tier Verification

- [ ] **PRO-01**: Professional can upload credential documents (license, certificate, insurance)
- [ ] **PRO-02**: Documents stored securely in Firebase Storage with access rules
- [ ] **PRO-03**: Professional submission creates verification request in Firestore
- [ ] **PRO-04**: Admin can review verification requests via admin dashboard
- [ ] **PRO-05**: Admin can approve or reject verification with notes
- [ ] **PRO-06**: Professional receives notification on verification status change
- [ ] **PRO-07**: Verified professional receives verification badge on profile
- [ ] **PRO-08**: Professional profile displays license number after verification

### Professional Services

- [ ] **SERV-01**: Professional can add specialization tags (e.g., "residential electrician")
- [ ] **SERV-02**: Employer can post job with photo uploads for professionals to assess
- [ ] **SERV-03**: Professional can submit quote for job with estimated cost and timeline
- [ ] **SERV-04**: Employer can accept professional's quote to proceed with job
- [ ] **SERV-05**: Professional profile shows portfolio of past work

### Payments

- [ ] **PAY-01**: System integrates with Paystack for ZAR payment processing
- [ ] **PAY-02**: Employer can pay for completed task/shift via Paystack
- [ ] **PAY-03**: Payment flow uses WebView for Paystack payment page
- [ ] **PAY-04**: Webhook handler verifies Paystack signature (HMAC-SHA512)
- [ ] **PAY-05**: Transaction records stored in Firestore with idempotency keys
- [ ] **PAY-06**: Worker receives payment confirmation notification

### Multi-Platform Builds

- [ ] **BUILD-01**: iOS build configured and testable via TestFlight
- [ ] **BUILD-02**: Android APK build generated and installable
- [ ] **BUILD-03**: Both platforms tested with Firebase configuration
- [ ] **BUILD-04**: Builds validated with actual payment flow (test mode)

### Demo Preparation

- [ ] **DEMO-01**: Demo accounts created for each tier (regular, pending student, verified professional)
- [ ] **DEMO-02**: Sample tasks and shifts pre-loaded for realistic demo
- [ ] **DEMO-03**: Verification workflow tested end-to-end
- [ ] **DEMO-04**: Payment flow tested in Paystack test mode
- [ ] **DEMO-05**: Demo script written with key user flows
- [ ] **DEMO-06**: Three dry run demos completed before investor presentation

## v2 Requirements

Deferred to future releases after investor demo validation.

### Advanced Student Features

- **STU-20**: AI profile builder to polish student CVs
- **STU-21**: Cross-tier reputation scoring (student work ethic carries over)
- **STU-22**: Earnings dashboard for tax purposes
- **STU-23**: Shift swap marketplace between students
- **STU-24**: Instant payment after shift completion
- **STU-25**: Shift confirmation/check-in system with GPS or employer QR code
- **STU-26**: Student availability recurrence settings (every Friday 6pm-2am)

### Advanced Professional Features

- **PRO-20**: Automated credential verification via ECSA/PIRB/SAIEE APIs
- **PRO-21**: Background check integration
- **PRO-22**: Insurance certificate validation
- **PRO-23**: Emergency/urgent job indicators with premium pricing
- **PRO-24**: Quote negotiation system (back-and-forth)
- **PRO-25**: Job completion photo documentation

### Monetization

- **MON-01**: R50 verification fee for student accounts (bypassed by college promo code)
- **MON-02**: Transaction fee percentage on completed jobs
- **MON-03**: Premium tier with featured listings
- **MON-04**: College partnership program with bulk verification

### Platform Enhancements

- **PLAT-01**: Smart shift matching algorithm based on location and history
- **PLAT-02**: Advanced search with multiple filters (tier, rating, distance, availability)
- **PLAT-03**: Analytics dashboard for employers (hiring patterns, cost tracking)
- **PLAT-04**: Multi-language support (English, Afrikaans, Zulu)
- **PLAT-05**: Web platform for employers (desktop experience)

## Out of Scope

Explicitly excluded features with reasoning to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Bidding/auction system for jobs | Creates race-to-bottom pricing, bad for worker earnings and quality |
| Real-time GPS tracking of workers | Privacy concerns, high battery drain, unnecessary for trust |
| Real-time chat messaging | Existing async messaging sufficient, adds complexity |
| Video calls for job consultation | Overkill for SA market, bandwidth concerns |
| Cryptocurrency payments | ZAR focus, Paystack sufficient, adds regulatory complexity |
| Social media features (feed, stories) | Not core to marketplace value, feature creep |
| Automated credential verification (v1) | SA licensing bodies lack public APIs, manual review required |
| Background checks (v1) | High cost, slow process, defer until proven market fit |
| Multi-currency support (v1) | South Africa market only, ZAR sufficient |
| Advanced shift scheduling (recurring shifts, templates) | Nice-to-have, defer to v2 for demo timeline |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TIER-01 | Phase 1 | Pending |
| TIER-02 | Phase 1 | Pending |
| TIER-03 | Phase 1 | Pending |
| TIER-04 | Phase 1 | Pending |
| TIER-05 | Phase 1 | Pending |
| TIER-06 | Phase 1 | Pending |
| TIER-07 | Phase 1 | Pending |
| STU-01 | Phase 2 | Pending |
| STU-02 | Phase 2 | Pending |
| STU-03 | Phase 2 | Pending |
| STU-04 | Phase 2 | Pending |
| STU-05 | Phase 2 | Pending |
| SHIFT-01 | Phase 3 | Pending |
| SHIFT-02 | Phase 3 | Pending |
| SHIFT-03 | Phase 3 | Pending |
| SHIFT-04 | Phase 3 | Pending |
| SHIFT-05 | Phase 3 | Pending |
| SHIFT-06 | Phase 3 | Pending |
| PRO-01 | Phase 2 | Pending |
| PRO-02 | Phase 2 | Pending |
| PRO-03 | Phase 2 | Pending |
| PRO-04 | Phase 2 | Pending |
| PRO-05 | Phase 2 | Pending |
| PRO-06 | Phase 2 | Pending |
| PRO-07 | Phase 2 | Pending |
| PRO-08 | Phase 2 | Pending |
| SERV-01 | Phase 4 | Pending |
| SERV-02 | Phase 4 | Pending |
| SERV-03 | Phase 4 | Pending |
| SERV-04 | Phase 4 | Pending |
| SERV-05 | Phase 4 | Pending |
| PAY-01 | Phase 4 | Pending |
| PAY-02 | Phase 4 | Pending |
| PAY-03 | Phase 4 | Pending |
| PAY-04 | Phase 4 | Pending |
| PAY-05 | Phase 4 | Pending |
| PAY-06 | Phase 4 | Pending |
| BUILD-01 | Phase 5 | Pending |
| BUILD-02 | Phase 5 | Pending |
| BUILD-03 | Phase 5 | Pending |
| BUILD-04 | Phase 5 | Pending |
| DEMO-01 | Phase 5 | Pending |
| DEMO-02 | Phase 5 | Pending |
| DEMO-03 | Phase 5 | Pending |
| DEMO-04 | Phase 5 | Pending |
| DEMO-05 | Phase 5 | Pending |
| DEMO-06 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 51 total
- Mapped to phases: 51
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-11*
*Last updated: 2026-02-11 after initial definition*
