# Taskers SA

## What This Is

A multi-tier task marketplace for South Africa that connects employers with three distinct worker types: general taskers for project-based work, students and service workers for shift-based gigs, and verified professional tradespeople for skilled services. The platform expands beyond traditional task marketplaces by offering specialized flows for seasonal student staffing and college-verified professional trades.

## Core Value

Employers can quickly find and hire verified workers across different skill levels - from students needing part-time shifts to certified electricians for professional jobs - all in one platform built for the South African market.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- ✓ User authentication (email/password, Firebase Auth) — existing
- ✓ Task posting and browsing — existing
- ✓ Task completion flow (accept, complete, rate) — existing
- ✓ User profiles and role management — existing
- ✓ Real-time messaging between posters and taskers — existing

### Active

<!-- Current scope. Building toward these. -->

- [ ] **Student Tier**: Shift-based job postings (hourly instead of project-based)
- [ ] **Student Tier**: Student-specific profile creation with student details
- [ ] **Student Tier**: Basic verification system (free for v1)
- [ ] **Student Tier**: Verification badge display on profiles
- [ ] **Professional Tier**: Professional profiles with credential fields
- [ ] **Professional Tier**: Certificate/credential upload system
- [ ] **Professional Tier**: College verification integration (TVET partnerships)
- [ ] **Professional Tier**: Verification badge for professionals
- [ ] **Payments**: Paystack integration for task/shift payments (ZAR)
- [ ] **Payments**: Transaction history and escrow system
- [ ] **Multi-Tier UI**: Unified interface showing all three worker tiers
- [ ] **Multi-Tier UI**: Tier-specific job browsing and filtering
- [ ] **Mobile Builds**: iOS build ready for App Store / TestFlight
- [ ] **Mobile Builds**: Android APK build for distribution
- [ ] **Investor Demo**: All three tiers functional and demonstrable

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- R50 verification fee — Defer to v2, start with free verification to build user base
- AI profile builder — Complex feature, defer until core marketplace proven
- Paid professional tier full features — Basic verification sufficient for v1 demo
- Advanced analytics dashboard — Not needed for investor demo
- Multi-currency support — SA market only for v1 (ZAR)

## Context

**Existing Codebase:**
- Flutter mobile app (Android and iOS) with Firebase backend
- Firebase Auth, Firestore, Firebase Storage already integrated
- Core task marketplace functional (posting, browsing, accepting, completing tasks)
- Real-time messaging system working
- Payment integration needed (Paystack documented but not implemented)

**Market Context:**
- Targeting South African market (university students, service workers, tradespeople)
- Competitive with TaskRabbit but specialized for SA student/seasonal staffing
- Partnership opportunity with TVET colleges for verified professional credentials

**Technical Debt from Codebase Audit:**
- Paystack API keys currently hardcoded (need environment variables)
- No external error tracking service (Firebase Crashlytics not configured)
- Test coverage minimal (test/ directory exists but needs implementation)

## Constraints

- **Timeline**: 1-2 weeks until investor presentation — aggressive schedule requires focus on demo-critical features
- **Tech Stack**: Flutter (mobile), Firebase (Auth, Firestore, Storage), Paystack (payments) — existing architecture must be preserved
- **Geography**: South Africa market, ZAR currency only for v1
- **Quality**: Fully functional for investor demo — not prototype, needs to work end-to-end
- **Platforms**: iOS and Android builds both required for demo
- **Budget**: Firebase free tier, Paystack transaction fees only

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Three-tier marketplace (Regular, Student, Professional) | Differentiate from generic TaskRabbit, target SA student market specifically | — Pending |
| Student tier prioritized over professional tier | Higher volume potential, easier validation, builds momentum faster | — Pending |
| Free verification for v1 | Reduce friction, monetize later once user base established | — Pending |
| Defer AI profile builder | Timeline too tight, focus on core marketplace functionality | — Pending |
| Keep existing Flutter app structure | Working codebase, investor demo timeline too tight for rewrite | — Pending |

---
*Last updated: 2026-02-11 after initialization*
