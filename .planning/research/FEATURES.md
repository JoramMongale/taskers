# Feature Research: Multi-Tier Task Marketplace

**Domain:** Multi-tier task marketplace (student staffing + professional services)
**Researched:** 2026-02-11
**Confidence:** MEDIUM (based on established marketplace patterns, no real-time verification available)

**Context:** Adding tier system to existing marketplace with task posting, browsing, accepting, completion flow, ratings, and messaging. Target: SA market, investor demo in 1-2 weeks.

## Feature Landscape

### Table Stakes: Student Staffing Tier (Must-Have)

Features employers expect when hiring students for shift work. Missing these = employers won't post shifts.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Shift scheduling with time slots** | Core need - employers post specific shifts (e.g., "Fri 6pm-2am") | MEDIUM | Modify existing task posting to include time ranges, recurring shifts |
| **Hourly rate specification** | Students paid by hour, not per-task | LOW | Add hourly_rate field, calculate total from hours worked |
| **Student verification (university)** | Employers want confirmed students for student tier | MEDIUM | Email verification (@university.ac.za domain) or student ID upload |
| **Availability calendar** | Students show when they can work; employers filter | MEDIUM | Calendar UI for students, filter for employers searching |
| **Multiple worker booking** | Events need 5 bartenders, 10 waiters - book multiple at once | MEDIUM | Extend accept flow to support multiple workers per shift |
| **Shift confirmation/check-in** | Proof worker showed up (employers fear no-shows) | MEDIUM | GPS check-in or employer confirmation at shift start |
| **Uniform/requirements specification** | "Black shirt, black pants" common requirement | LOW | Text field in shift posting |
| **Bulk shift posting** | Post same shift for multiple dates (every Friday) | MEDIUM | Recurring shift template, generate multiple instances |

### Table Stakes: Professional Services Tier (Must-Have)

Features clients expect when hiring licensed professionals. Missing these = professionals or clients won't trust platform.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Credential verification** | Electricians/plumbers need licenses, insurance | HIGH | Document upload + manual review (investor demo: upload only, review later) |
| **License number display** | Clients verify professional registration | LOW | Display verified license number on profile |
| **Insurance certificate storage** | Liability protection, clients often require proof | MEDIUM | Document storage, expiry tracking |
| **Quote system** | Pros assess job before committing to price | MEDIUM | Multi-step: view task → request site visit OR submit quote → client accepts |
| **Job photos/documentation** | "Show me the problem" before quoting | LOW | Photo upload in task posting (extend existing) |
| **Specialization tags** | "Residential electrician" vs "Industrial electrician" | LOW | Category refinement with specialization badges |
| **Portfolio/past work showcase** | Clients want to see quality of work | MEDIUM | Photo gallery in profile with descriptions |
| **Emergency/urgent job indicator** | Burst pipe = premium rate, fast response | LOW | Priority flag on task with visual indicator |

### Table Stakes: Both Tiers (Cross-Cutting)

Features both tiers need, not in existing marketplace.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Tier identification badges** | Users instantly see "Student Worker" vs "Verified Professional" | LOW | Badge component on profiles, search results |
| **Tier-specific search filters** | Employers want to filter by tier when browsing | LOW | Add tier filter to existing search |
| **Different rating criteria** | Students rated on punctuality, attitude; pros on quality, compliance | MEDIUM | Tier-specific rating forms (extend existing ratings) |
| **Earnings dashboard** | Workers track income, tax purposes | MEDIUM | Analytics page summing completed task payments |
| **Cancellation policies per tier** | Students: 24hr notice; Pros: different for quotes vs booked jobs | MEDIUM | Tier-specific cancellation rules with penalties |
| **Background checks (optional)** | Trust signal, especially for students entering homes | HIGH | Third-party integration OR manual document review (defer to post-demo) |

### Existing Features to MODIFY

Features already built that need adaptation for tiers.

| Existing Feature | Required Modification | Complexity | Notes |
|------------------|----------------------|------------|-------|
| **Task posting** | Add tier selector, shift times (students), quote request (pros) | MEDIUM | Extend form with conditional fields based on selected tier |
| **Browse/search** | Filter by tier, show hourly rate vs fixed price | LOW | Add tier filter, display rate format based on tier |
| **Accept flow** | Students: instant booking; Pros: quote-then-book flow | MEDIUM | Branch logic based on tier |
| **Ratings** | Tier-specific rating criteria | MEDIUM | Dynamic rating form based on tier |
| **Profile** | Show verification badges, credentials, availability calendar | MEDIUM | Conditional profile sections by tier |
| **Messaging** | Add quote discussion thread for pros | LOW | Extend existing chat with quote context |

### Existing Features to KEEP Unchanged

These work fine across both tiers.

- Task browsing core UI
- Basic messaging
- Payment escrow (if implemented)
- User registration
- Push notifications
- Reviews/testimonials

## Differentiators (Competitive Advantage)

Features that set product apart from competitors. Not required for MVP, but valuable for growth.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Smart shift matching** | AI suggests students based on past shifts, location, availability | HIGH | Algorithm matching student profiles to shift requirements |
| **Reputation score combining both tiers** | Worker's student history boosts professional tier credibility | MEDIUM | Cross-tier reputation calculation, shows work ethic continuity |
| **Shift reliability predictor** | Warn employers if student has high cancellation rate for similar shifts | MEDIUM | Analytics on student acceptance/completion patterns |
| **Instant payment for students** | Pay within hours, not days (cash flow critical for students) | HIGH | Payment provider integration with instant disbursement |
| **Professional progression path** | Guide students toward apprenticeships/licensing | LOW | UI showing "Path to Pro" with requirements |
| **Group bookings with team leaders** | Book 10 waiters, 1 experienced team leader | MEDIUM | Hierarchical booking with role designation |
| **Venue-specific requirements** | Venue pre-approves students; future shifts auto-match | MEDIUM | Venue whitelist feature for recurring employers |
| **Shift swap marketplace** | Student can't make shift; offers to peers | MEDIUM | Secondary marketplace for accepted shifts |

## Anti-Features (Commonly Requested, Often Problematic)

Features to explicitly NOT build.

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| **Automated credential verification** | "Why manual review?" | SA licensing bodies lack APIs; high false positive risk | Manual review with 24hr SLA, outsource verification post-demo |
| **Real-time GPS tracking during shifts** | "Make sure they're working" | Privacy concerns, battery drain, trust issues | Check-in at start/end, employer can message anytime |
| **Bidding wars (lowest price wins)** | "Get best price" | Race to bottom, professionals avoid platform | Fixed rates by employer OR professional quotes (not auction) |
| **Complex scheduling algorithms** | "Optimize everything" | Over-engineering for MVP, employers want control | Manual selection with filters/suggestions, not auto-assignment |
| **Student academic verification via university APIs** | "Fully automated" | SA universities lack standardized APIs | Email domain verification + student ID upload |
| **In-app payment splitting** | "Split bill between multiple clients" | Edge case, adds payment complexity | Single payer, they handle their own splitting |
| **Professional liability insurance through platform** | "One-stop shop" | Regulatory complexity, high cost | Require proof of insurance, don't provide it |
| **Shift marketplace for pros** | "Pros need scheduling too" | Pros typically quote custom jobs, not hourly shifts | Keep pros on quote/job basis, students on shifts |

## Feature Dependencies

```
STUDENT TIER:
University Email Verification
    └──enables──> Student Tier Access
                      └──requires──> Availability Calendar
                                         └──enables──> Shift Matching

Shift Posting
    └──requires──> Time Slot Selection
    └──requires──> Hourly Rate
    └──optional──> Bulk/Recurring Shifts

Multiple Worker Booking
    └──requires──> Shift Posting
    └──enhances──> Bulk Shift Posting

Shift Check-In
    └──requires──> Accepted Shift
    └──enables──> Payment Release

PROFESSIONAL TIER:
License Upload
    └──enables──> Professional Tier Access
                      └──enables──> Quote Submission
                                       └──requires──> Job Photos (optional)

Credential Verification
    └──requires──> License Upload
    └──enables──> Verified Badge Display

Quote System
    └──requires──> Professional Tier Profile
    └──requires──> Task with Photos
    └──enables──> Quote Discussion (messaging)
    └──enables──> Quote Acceptance Flow

CROSS-TIER:
Tier System (core)
    └──affects──> All search/browse
    └──affects──> Task posting
    └──affects──> Profile display
    └──affects──> Accept flow
    └──affects──> Rating system
```

### Dependency Notes

- **Tier system must come first:** Everything else branches from tier identification
- **Verification blocks tier access:** Can't post as student/pro until verified
- **Quote system independent from shift system:** Don't couple them; different workflows
- **Ratings depend on completion:** Keep existing rating trigger, just modify form

## MVP Definition (For Investor Demo in 1-2 Weeks)

### Launch With (v1 - Demo)

Minimum to demonstrate multi-tier concept and tier-specific workflows.

#### Core Tier System (PRIORITY 1)
- [ ] Tier selection during signup (student vs professional vs client)
- [ ] Tier badges on profiles and search results
- [ ] Tier-specific search filters

#### Student Tier Essentials (PRIORITY 1)
- [ ] Shift posting with date/time range and hourly rate
- [ ] Availability calendar (simplified: select available days/times)
- [ ] University email verification (@university.ac.za domain check)
- [ ] Multiple worker booking (simple: "Need X workers" counter)
- [ ] Shift-specific accept flow (instant booking if available)

#### Professional Tier Essentials (PRIORITY 1)
- [ ] License/credential upload form (no verification yet - just upload)
- [ ] Quote request flow (pro views task → submits quote → client accepts)
- [ ] Specialization tags (electrician, plumber, carpenter subcategories)
- [ ] Job photo upload in task posting

#### Modified Existing Features (PRIORITY 2)
- [ ] Task posting form with tier selector and conditional fields
- [ ] Browse/search with tier filter
- [ ] Profile display with tier-specific sections
- [ ] Tier-specific rating criteria

### Add After Demo (v1.x)

Features to validate tier system before full launch.

- [ ] Manual credential verification workflow (for professional tier)
- [ ] Shift check-in/confirmation (GPS or employer confirmation)
- [ ] Bulk/recurring shift posting
- [ ] Earnings dashboard
- [ ] Insurance certificate storage
- [ ] Portfolio/past work showcase
- [ ] Cancellation policies per tier
- [ ] Uniform/requirements field for student shifts

### Future Consideration (v2+)

Features to defer until product-market fit established.

- [ ] Smart shift matching algorithm
- [ ] Cross-tier reputation scoring
- [ ] Shift reliability predictor
- [ ] Instant payment for students
- [ ] Professional progression path UI
- [ ] Group bookings with team leaders
- [ ] Venue-specific whitelists
- [ ] Shift swap marketplace
- [ ] Background checks integration
- [ ] Emergency job indicators with premium pricing

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Phase |
|---------|------------|---------------------|----------|-------|
| Tier system core | HIGH | MEDIUM | P1 | Demo |
| Shift posting with time slots | HIGH | MEDIUM | P1 | Demo |
| Hourly rate handling | HIGH | LOW | P1 | Demo |
| University email verification | HIGH | LOW | P1 | Demo |
| Quote system basics | HIGH | MEDIUM | P1 | Demo |
| License upload form | HIGH | LOW | P1 | Demo |
| Multiple worker booking | HIGH | MEDIUM | P1 | Demo |
| Tier-specific search filters | HIGH | LOW | P1 | Demo |
| Job photo upload | MEDIUM | LOW | P1 | Demo |
| Availability calendar | HIGH | MEDIUM | P1 | Demo (simplified) |
| Modified task posting | HIGH | MEDIUM | P2 | Demo |
| Modified profiles | HIGH | MEDIUM | P2 | Demo |
| Tier-specific ratings | MEDIUM | MEDIUM | P2 | Demo |
| Manual credential verification | HIGH | MEDIUM | P2 | Post-demo |
| Shift check-in | HIGH | MEDIUM | P2 | Post-demo |
| Bulk shift posting | MEDIUM | MEDIUM | P2 | Post-demo |
| Portfolio showcase | MEDIUM | MEDIUM | P2 | Post-demo |
| Earnings dashboard | MEDIUM | MEDIUM | P2 | Post-demo |
| Cancellation policies | MEDIUM | MEDIUM | P2 | Post-demo |
| Smart matching | HIGH | HIGH | P3 | v2+ |
| Instant payment | HIGH | HIGH | P3 | v2+ |
| Shift swap | MEDIUM | MEDIUM | P3 | v2+ |

**Priority key:**
- P1: Must have for demo (core tier differentiation)
- P2: Should have for launch (trust and usability)
- P3: Nice to have (competitive advantage)

## Competitor Feature Analysis

| Feature | Wonolo (Student Staffing) | Upwork (Professional Services) | Our Approach |
|---------|---------------------------|--------------------------------|--------------|
| Verification | Background checks, fast onboarding | Skill tests, portfolio reviews | Email (students), license upload (pros) - fast MVP |
| Booking | Instant shift booking | Proposal/interview process | Instant (students), quote system (pros) |
| Scheduling | Shift calendar, recurring shifts | Project milestones | Shift calendar (students), quote-then-schedule (pros) |
| Payments | Hourly, direct deposit | Escrow, milestone-based | Hourly (students), quote-based (pros) - use existing escrow |
| Search | Location, skills, availability | Skills, rate, reviews | Tier filter + existing filters |
| Ratings | Shift-specific ratings | Overall + per-project | Tier-specific criteria (punctuality vs quality) |
| Mobile | Mobile-first for workers | Desktop for pros, mobile for browsing | Mobile-first for students, responsive for pros |

**Key Insight:** Don't try to be both platforms - use tier system to maintain separate workflows within one app.

## Implementation Notes for Existing Marketplace

### Database Changes Required
- Add `tier` field to users table: `student | professional | client`
- Add `verification_status` to users: `pending | verified | rejected`
- Add `hourly_rate` to tasks (students) vs existing `fixed_price` (pros)
- Add `shift_start_time`, `shift_end_time` to tasks
- Add `worker_count` to tasks (for multiple bookings)
- Add `quote_amount`, `quote_status` to task applications
- Add `availability` JSON field to user profiles
- Add `credentials` table: user_id, document_url, verified_at, expiry_date

### UI Components to Build
- Tier selector (signup and task posting)
- Time range picker (shift scheduling)
- Availability calendar (drag to select available times)
- Quote submission form
- Document upload widget
- Tier badge component
- Multi-worker counter/selector

### Logic Changes
- Task accept flow: branch by tier (instant vs quote)
- Search/browse: filter by tier
- Profile: conditional sections by tier
- Ratings: dynamic form by tier
- Notifications: tier-specific templates

## South African Market Considerations

**Student Tier:**
- University email domains: @uct.ac.za, @wits.ac.za, @sun.ac.za, @ru.ac.za, @up.ac.za, @ukzn.ac.za, etc.
- Popular student jobs: Event staffing (bartenders, waiters), retail promotions, tutoring
- Payment: EFT dominant, PayFast for card payments

**Professional Tier:**
- Licensing bodies: ECSA (engineers), PIRB (plumbers), SAIEE (electricians), SACAP (architects)
- Verification challenge: No centralized API, manual lookup required
- Insurance: COIDA, public liability standard requirements
- Categories: Electricians, plumbers, builders, carpenters, HVAC, painters, tilers

**Platform-Wide:**
- Load shedding considerations: Offline-first for students (shift data cached)
- Data costs: Image compression, progressive loading
- Languages: English primary, Afrikaans/Zulu nice-to-have (defer)

## Sources

**Confidence Note:** Research based on established marketplace patterns from Wonolo, Instawork (student staffing), Upwork, Thumbtack (professional services). WebSearch unavailable; findings derived from training data (pre-2025) on marketplace design patterns. **MEDIUM confidence** - patterns are well-established but not verified against 2026 current state.

**Referenced Patterns From:**
- Wonolo - Student/gig worker shift scheduling model
- Instawork - Hospitality staffing marketplace
- Upwork - Professional services quote/proposal system
- Thumbtack - Professional verification and quote flow
- TaskRabbit - Task marketplace with tiered pricing

**SA-Specific Context:**
- University email domain patterns (known SA universities)
- Professional licensing body structure (ECSA, PIRB, etc.)
- Payment preferences (EFT/PayFast dominance)

---
*Feature research for: Multi-tier task marketplace expansion*
*Researched: 2026-02-11*
*Next step: Use this to define requirements and phase structure in roadmap*
