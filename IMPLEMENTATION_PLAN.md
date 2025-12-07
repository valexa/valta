# Live Team Activities - Implementation Plan

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
  - `AppState` and `TeamMemberAppState` each expose `dataVersion: Int`.
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
- [x] App entry point and state management (`AppState.swift`)
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

## Phase 4: Notifications (FCM) 🔄 IN PROGRESS

### 4.1 Configuration
- [ ] Configure APNs keys in Firebase Console
- [ ] Add Push Notification capability in Xcode
- [ ] Implement `AppDelegate` for notification handling (SwiftUI adapter)

### 4.2 Implementation
- [ ] Request notification permissions
- [ ] Handle FCM token registration
- [ ] Implement local notification triggers for immediate feedback
- [ ] Test remote notifications via Firebase Console


---

## Phase 5: Firestore Integration (Replacing CSV) 🔲 TODO

### 5.1 Setup
- [ ] Enable Firestore in Firebase Console
- [ ] Add `FirebaseFirestore` SDK via SPM
- [ ] Configure Firestore Security Rules

### 5.2 Persistence Layer Migration
- [ ] Create `FirestoreService`
- [ ] Implement `Activity` document mapping
- [ ] Implement `Team` and `TeamMember` document mapping
- [ ] Implement real-time listeners for data sync
- [ ] Migrate FCM token storage to Firestore

### 5.3 Cleanup
- [ ] Remove `CSVService`
- [ ] Remove `FirebaseStorage` dependency (if unused)
- [ ] Deprecate file-based sync logic



---

## Phase 6: Unit Testing, Polish, and Integration Testing 🔲 TODO

### 6.1 UI Polish
- [ ] Add loading states
- [ ] Implement error handling UI
- [ ] Add animations and transitions
- [ ] Accessibility support
- [ ] Dark mode verification

### 6.2 Testing
- [ ] Unit tests for business logic
- [ ] UI tests for critical flows
- [ ] Integration tests for data sync

### 6.3 Performance
- [ ] Profile memory usage
- [ ] Optimize list rendering
- [ ] Test with large datasets

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
│   ├── StyleGuideColors.swift       # ✅ Colors & gradients ONLY
│   ├── StyleGuideFonts.swift        # ✅ Font sizes & styles ONLY
│   ├── AppSymbols.swift             # ✅ SF Symbols enum
│   ├── Services/
│   │   ├── ActivityFilter.swift     # ✅ Filtering/querying
│   │   ├── ActivityStats.swift      # ✅ Statistics
│   │   └── ActivityService.swift    # ✅ Business logic
│   └── Components/
│       ├── SharedComponents.swift   # ✅ Reusable UI components
│       ├── ActivityRow.swift        # ✅ Unified activity row
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
│   ├── AppState.swift
│   └── Views/
│       ├── OnboardingView.swift
│       ├── TeamsTab.swift
│       ├── ActivityCard.swift
│       ├── RequestsTab.swift
│       └── NewActivitySheet.swift
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
| Phase 4: Notifications | 🔄 In Progress | 10% |
| Phase 5: Firestore Integration | 🔲 Not Started | 0% |
| Phase 6: Testing & Polish | 🔲 Not Started | 0% |
**Overall Progress: ~52%** (3.1 of 6 phases complete)

---

## Next Steps

1. **Immediate**: Implement push notifications using Firebase Cloud Messaging
2. **Short-term**: Migrate data persistence to Firestore
3. **Medium-term**: Comprehensive Unit & Integration Testing
4. **Long-term**: Final UI Polish and Release
