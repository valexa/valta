# Live Team Activities - Implementation Plan

> [!WARNING]
> **PERSISTENCE STRATEGY:**
> Use **CSV/Firebase Storage** for Teams and Activities.
> Use **Firestore** ONLY for FCM Tokens (Notifications).
> Do not mix these strategies.

## Overview

Live Team Activities is a macOS application suite consisting of two apps:
- **valtaManager** - For team leaders to manage teams and activities
- **valta** - For team members to view and interact with their activities

## Architectural Decisions (Updated)
- Observation over Combine
  - We standardized on the Observation framework (`@Observable`) for state management.
  - We removed `ObservableObject`, `@Published`, and Combine subscriptions from the shared data layer.
  - Views use `@Environment(Type.self)` and `.environment(instance)` for dependency injection instead of `@EnvironmentObject`.

- Nested mutation handling
  - Observation does not notify on nested mutations by default.
  - `DataManager` exposes `notifyTeamsChanged()` which performs a top-level write (`teams = teams`) and triggers a callback.
  - `DataManager` provides `onTeamsChanged: (() -> Void)?` to notify state containers.

- State container invalidation
  - `ManagerAppState` and `TeamMemberAppState` each expose `dataVersion: Int`.
  - Derived/computed properties depend on `dataVersion` to re-evaluate when changes occur.

- UI animation strategy
  - Mutating actions are wrapped in `withAnimation(.spring(...))` at call sites.
  - Lists use `.animation(..., value: items.map(\.id))` to animate insertions/removals/reorders.

- Simplified UI components
  - `CompletionButton` simplified to a minimal wrapper around `Button` to remove progress state and complexity.

---

## Phase 1: UI Foundation ✅ COMPLETED

### 1.1 Shared Infrastructure ✅
- [x] Create `Shared/` folder structure
- [x] Implement data models (`Models.swift`)
  - [x] `ActivityStatus` enum (running, completed, canceled, managerPending, teamMemberPending)
  - [x] `ActivityPriority` enum (P0-P3 with color coding)
  - [x] `ActivityOutcome` enum (ahead, jit, overrun with colors)
  - [x] `TeamMember` struct with avatar support
  - [x] `Activity` struct with all required fields
  - [x] `Team` struct
  - [x] `ActivityLogEntry` struct for history
- [x] Create mock data for development
- [x] Implement shared UI components (`SharedComponents.swift`)
  - [x] `PriorityBadge`
  - [x] `StatusBadge`
  - [x] `MemberAvatar`
  - [x] `OutcomeBadge`
  - [x] `TimeRemainingLabel`
  - [x] `EmptyStateView`
  - [x] `SectionHeader`
- [x] Style guide files
  - [x] `StyleGuideColors.swift` - **ONLY** colors and gradients (`AppColors`, `AppGradients`)
  - [x] `StyleGuideFonts.swift` - **ONLY** font sizes and styles (`AppFontSize`, `AppFont`)
  - [x] `AppSymbols.swift` - Centralized SF Symbols

### 1.2 Manager App UI ✅
- [x] App entry point and state management (`ManagerAppState.swift`)
- [x] Main tab structure (Teams, Requests)
- [x] Onboarding flow
  - [x] Welcome step with manager name
  - [x] Team name creation
  - [x] Member selection
  - [x] Completion summary
- [x] Teams Tab
  - [x] Team sidebar with stats
  - [x] Member list with management
  - [x] Activity dashboard with filtering
  - [x] Activity cards with actions
- [x] Requests Tab
  - [x] Completion request cards
  - [x] Approve/reject functionality
  - [x] Bulk approve action
- [x] New Activity Sheet
  - [x] Form fields (name, description, assignee, priority, deadline)
  - [x] Quick deadline buttons
  - [x] Notification preview
- [x] Complete Activity Sheet with outcome selection

### 1.3 Team Member App UI ✅
- [x] App entry point and state management (`TeamMemberAppState.swift`)
- [x] Main tab structure (Activities, Team, Log)
- [x] Onboarding flow
  - [x] Member selection from predefined list
- [x] Activities Tab (My Activities)
  - [x] User header with quick stats
  - [x] Pending activities section
  - [x] Running activities section
  - [x] Awaiting approval section
  - [x] Completed activities section
  - [x] Start activity action
  - [x] Request completion sheet
- [x] Team Tab
  - [x] Team overview stats
  - [x] Activities grouped by member
  - [x] Search and filter
  - [x] Current user highlighting
- [x] Log Tab
  - [x] Timeline view
  - [x] Date grouping
  - [x] Action type filtering
  - [x] Search functionality

---

## Phase 2: Data Persistence (Firebase Storage + CSV) ✅ COMPLETED

### 2.1 Firebase Setup
- [x] Add `FirebaseStorage` and `FirebaseAuth` SDK via SPM
- [x] Enable **Storage** in Firebase Console
- [x] Configure Storage Rules (authenticated access)
- [x] Enable Anonymous Authentication

### 2.2 CSV Handling
- [x] Create `CSVService` for serialization/deserialization
- [x] Implement custom CSV parsing for:
  - `Activity`
  - `TeamMember`
  - `Team`
- [x] Create `StorageService` to handle Upload/Download
  - `upload(data: Data, path: String)`
  - `download(path: String)`
- [x] Create `AuthService` for anonymous authentication
- [x] Create `DataManager` to coordinate services

### 2.3 Data Sync Strategy
- [x] **Manager App**:
  - On change: Generate CSV -> Upload to Storage
- [x] **Team App**:
  - On launch: Download CSV -> Parse -> Update Local State
- [x] **Conflict Resolution**: Last write wins (Simple file replacement)



---

## Phase 3: Business Logic ✅ COMPLETED

### 3.1 Activity Lifecycle
- [x] Implement activity state machine
  - [x] teamMemberPending → running (on start)
  - [x] running → managerPending (on completion request)
  - [x] managerPending → completed (on approval)
  - [x] managerPending → running (on rejection)
  - [x] Any → canceled
- [x] Implement deadline monitoring (every minute)
- [x] Auto-transition overdue activities to completed/overrun
- [x] Handle pending completion events at deadline

### 3.2 Outcome Calculation
- [x] Implement outcome thresholds
  - [x] Ahead: ≥30 min before deadline
  - [x] JIT: within ±5 min of deadline
  - [x] Overrun: after deadline
- [x] P0 exception: JIT outcome shows red color

### 3.3 Manager Actions
- [x] Create activity with notification generation
- [x] Approve completion request
- [x] Reject completion request
- [x] Cancel activity
- [x] Direct completion by manager

### 3.4 Team Member Actions
- [x] Start activity
- [x] Submit completion 
- [x] View activity details

---

## Phase 4: Notifications (FCM) ✅ COMPLETED

### 4.1 Configuration
- [x] Configure APNs keys in Firebase Console
- [x] Add Push Notification capability in Xcode
- [x] Implement `AppDelegate` for notification handling (SwiftUI adapter)

### 4.2 Implementation
- [x] Request notification permissions
- [x] Handle FCM token registration
- [x] Implement local notification triggers for immediate feedback
- [x] Test remote notifications via Firebase Console


---

## Phase 5: Firestore Integration ✅ COMPLETED

### 5.1 Setup
- [x] Enable Firestore in Firebase Console
- [x] Add `FirebaseFirestore` SDK via SPM
- [x] Configure Firestore Security Rules

### 5.2 FCM Token Storage
- [x] Create `FirestoreService.swift`
  - Singleton `shared` instance
  - Methods to save/delete FCM tokens
- [x] Migrate `NotificationService` to store tokens in Firestore

### 5.3 Cleanup
- [x] Ensure `CSVService` and `StorageService` remain active for data sync
- [x] Remove unused Firestore method stubs (if any)



---

## Phase 6: Polish and Testing 🔄 90% COMPLETE

### 6.1 UI Polish ✅
- [x] Activity detail context menu (right-click)
- [x] Hover tooltips for activity descriptions
- [x] TipKit integration for user guidance
- [x] Outcome projection in context menu
- [x] Animations and transitions

### 6.2 Unit Testing ✅
- [x] Unit tests for ActivityFilter
- [x] Unit tests for ActivityStats
- [x] Unit tests for ActivityTimeCalculator
- [x] Unit tests for ActivityService

### 6.3 Integration Testing 🔄
- [ ] End-to-end data sync testing
- [x] Cross-app notification testing

---

## Phase 7: ML Projections ✅ PHASE A / 🔮 PHASE B PLANNED

### 7.1 Statistical Outcome Projection ✅ COMPLETED

Implemented statistical projection for activity outcomes based on historical member performance.

- [x] Create `OutcomeProjectionService.swift`
  - Analyzes completed activities per member and priority
  - Calculates outcome probability distributions (ahead/jit/overrun)
  - Performance scoring: Ahead=100pts, JIT=70pts, Overrun=30pts
  - Confidence ratings based on sample size
- [x] Create `ProjectionsTab.swift` in manager app
  - Member performance cards ranked by score
  - Swift Charts bar charts for outcome distribution
  - Priority projection grid (P0-P3)
  - Data warning banner when <10 completed activities
- [x] Add `tabProjections` symbol (`robotic.vacuum`) to `AppSymbols.swift`
- [x] Integrate tab into manager `ContentView.swift`

**Why Statistical (not Core ML):**
- App started December 2025 — insufficient training data for ML models
- Statistical approach automatically adapts as data grows
- No model training/bundling required
- Equivalent accuracy for probability distributions at this scale

### 7.2 Core ML Upgrade 🔮 PLANNED (June 2026)

After 6 months of data accumulation (~500+ completed activities):

- [ ] Create `MLDataExporter.swift` — Export activities to training format
- [ ] Train `OutcomePredictor.mlmodel` using `MLBoostedTreeClassifier`
- [ ] Bundle model in app
- [ ] Implement `CoreMLOutcomeProjectionService.swift`
- [ ] Add `MLUpdateTask` for on-device incremental learning

**Data Thresholds for Core ML Transition:**

| Metric | Current | Target |
|--------|---------|--------|
| Days of history | ~15 days | 180+ days |
| Completed activities | ~20 | 500+ |
| Activities per member | ~3-5 | 50+ |

---

## Technical Reference

### Data Model Enums

```swift
// Activity Status
case running           // Activity is in progress
case completed         // Activity is finished
case canceled          // Activity was canceled
case managerPending    // Awaiting manager approval
case teamMemberPending // Awaiting team member to start

// Activity Priority
case p0 = 0  // Critical (red)
case p1 = 1  // High (orange)
case p2 = 2  // Medium (yellow)
case p3 = 3  // Low (blue)

// Activity Outcome
case ahead   // Completed ≥30 min early (green)
case jit     // Completed within ±5 min (yellow, red for P0)
case overrun // Completed after deadline (red)
```

### Special Rules

1. **P0 JIT Exception**: For P0 activities, if outcome is JIT (on-time), display color is RED instead of yellow.

2. **Deadline Auto-Transition**: Activities past deadline without completion are auto-transitioned to:
   - Status: `completed`
   - Outcome: `overrun`
   - Exception: If pending completion request exists, status becomes `managerPending`

---

## File Structure

```
valta/
├── Shared/                          # ✅ Shared code (both targets)
│   ├── Models.swift                 # ✅ Data models
│   ├── MockData.swift               # ✅ Mock data for development
│   ├── Theme.swift                  # ✅ Theme protocol & DI
│   ├── ActivityTimeCalculator.swift # ✅ Extracted time logic
│   ├── Tips.swift                   # ✅ TipKit tips
│   ├── StyleGuideColors.swift       # ✅ Colors & gradients ONLY
│   ├── StyleGuideFonts.swift        # ✅ Font sizes & styles ONLY
│   ├── AppSymbols.swift             # ✅ SF Symbols enum
│   ├── Services/
│   │   ├── ActivityFilter.swift     # ✅ Filtering/querying
│   │   ├── ActivityStats.swift      # ✅ Statistics
│   │   ├── ActivityService.swift    # ✅ Business logic
│   │   └── OutcomeProjectionService.swift # ✅ ML projection engine
│   └── Components/
│       ├── SharedComponents.swift   # ✅ Reusable UI components
│       ├── ActivityRow.swift        # ✅ Unified activity row
│       ├── ActivityDetailPopover.swift # ✅ Context menu content
│       └── StatButton.swift         # ✅ Filterable stat button
├── valta/                           # ✅ Team Member App
│   ├── valtaApp.swift
│   ├── ContentView.swift
│   ├── TeamMemberAppState.swift
│   └── Views/
│       ├── TeamMemberOnboardingView.swift
│       ├── ActivitiesTab.swift
│       ├── TeamTab.swift
│       └── LogTab.swift
├── valtaManager/                    # ✅ Manager App
│   ├── valtaManagerApp.swift
│   ├── ContentView.swift
│   ├── ManagerAppState.swift
│   └── Views/
│       ├── OnboardingView.swift
│       ├── ActivitiesTab.swift
│       ├── ManagerActivityRow.swift
│       ├── RequestsTab.swift
│       ├── NewActivitySheet.swift
│       ├── AnalyticsTab.swift       # ✅ Swift Charts analytics
│       └── ProjectionsTab.swift     # ✅ ML outcome projections
├── FULL_SPECIFICATION.md
├── IMPLEMENTATION_PLAN.md           # This file
└── PROJECT_COMP.md                  # Implementation summary
```

---

## Current Status

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 1: UI Foundation | ✅ Complete | 100% |
| Phase 2: Data Persistence | ✅ Complete | 100% |
| Phase 3: Business Logic | ✅ Complete | 100% |
| Phase 4: Notifications | ✅ Complete | 100% |
| Phase 5: Firestore Integration | ✅ Complete | 100% |
| Phase 6: Polish & Testing | 🔄 In Progress | 90% |
| Phase 7: ML Projections | ✅/🔮 Partial | 50% |

**Overall Progress: ~93%** (6.4 of 7 phases complete)

---

## Next Steps

1. **Immediate**: Integration testing - end-to-end data sync and cross-app notifications
2. **Final**: Release preparation

