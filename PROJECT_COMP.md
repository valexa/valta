# Live Team Activities - Implementation Summary

> [!NOTE]
> **Data Persistence Strategy:**
> *   **Data (Teams/Activities)**: CSV Files + Firebase Storage
> *   **Tokens (FCM)**: Firestore
>
> This split is intentional and must be maintained.

## Project Structure


(See Xcode project for file structure)


---

## Architecture

### Observation Framework Pattern

Both apps use Swift's Observation framework for reactive state management:

```swift
// State class with @Observable macro
@Observable
final class ManagerAppState {
    var team: Team = ...
    var selectedTab: AppTab = .teams
}

// Root view owns state with @State
struct ContentView: View {
    @State private var appState = ManagerAppState()
    
    var body: some View {
        MainView()
            .environment(appState)  // Pass via environment
    }
}

// Child views access via @Environment
struct ChildView: View {
    @Environment(ManagerAppState.self) private var appState
    
    var body: some View {
        @Bindable var state = appState  // For two-way bindings
        TextField("Name", text: $state.teamName)
    }
}
```

**Key Patterns:**
- `@Observable` on state classes (automatically tracks property access)
- `@State` in root view to own the observable
- `.environment(appState)` to pass down the view hierarchy
- `@Environment(Type.self)` to receive in child views
- `@Bindable` for two-way bindings to `@Observable` properties

---

## Shared Components (`Shared/`)

### Models.swift
- **`ActivityStatus`** enum: running, completed, canceled, managerPending, teamMemberPending
- **`ActivityPriority`** enum: P0 (Critical), P1 (High), P2 (Medium), P3 (Low)
- **`ActivityOutcome`** enum: ahead (green), jit (yellow), overrun (red)
- **`TeamMember`** struct with id, name, email
- **`Activity`** struct with full activity details including:
  - `timeProgress` - elapsed time as percentage (0.0 to 1.0)
  - `timeRemainingProgress` - remaining time as percentage
- **`Team`** struct containing members and activities
- **`CompletionRequest`** struct for approval workflow
- **`ActivityLogEntry`** struct for activity history
- **Mock data** for 6 team members, 11 activities (Sarah Chen has all status types), completion requests, and log entries

### StyleGuideColors.swift
**ONLY** colors and gradients used across both apps. No fonts or other style definitions.

**`AppColors`** - Color definitions:
- **Priority colors**: P0 (red), P1-P3 (grayscale dark to light)
- **Status colors**: running (blue), completed (green), manager pending (red), team member pending (purple), canceled (gray)
- **Outcome colors**: ahead (green), jit (yellow), overrun (red)
- **Action colors**: `success` (green), `destructive` (red), `warning` (orange)
- **Stats colors**: total (light gray)
- **Avatar**: Neutral gray for all team members
- **UI colors**: `shadow` (black)
- **Manager theme**: Purple/blue tones (`AppColors.Manager.*`)
- **Team Member theme**: Teal/cyan tones (`AppColors.TeamMember.*`)

**`AppGradients`** - Pre-built gradients:
- `managerPrimary` / `managerBackground` / `managerIcon`
- `teamMemberPrimary` / `teamMemberBackground` / `teamMemberSelection`
- `success` (green) / `avatar`

> **Note:** All UI colors are centralized here - no hardcoded colors in view files.

### Theme.swift
Theme protocol and dependency injection for colors following SOLID principles.

**`AppTheme`** - Protocol defining color accessors:
- `color(for priority:)` - Get color for ActivityPriority
- `color(for status:)` - Get color for ActivityStatus
- `color(for outcome:)` - Get color for ActivityOutcome
- Action colors: `destructive`, `success`, `warning`
- UI colors: `avatar`, `shadow`, `statTotal`
- Gradients: `avatarGradient`, `successGradient`

**`DefaultTheme`** - Concrete implementation using AppColors

**Environment Integration:**
- `@Environment(\.theme)` - Access theme in views
- `.theme(_:)` - View modifier to inject custom theme
- `appTheme` - Global shared instance for convenience

**Model Extensions:**
- `ActivityPriority.color(using:)` - Theme-aware color
- `ActivityStatus.color(using:)` - Theme-aware color
- `ActivityOutcome.color(using:)` - Theme-aware color
- `Activity.displayColor(using:)` - Theme-aware display color with business rules

> **Note:** Theme injection enables testability, future theming, and follows Dependency Inversion Principle.

### ActivityTimeCalculator.swift
Extracted time calculation logic following Single Responsibility Principle.

**Properties:**
- `createdAt`, `deadline`, `startedAt`, `completedAt`, `status` - Activity time data
- `now: () -> Date` - Testable date provider (defaults to `Date()`)

**Time Remaining:**
- `timeRemaining: String` - Human-readable remaining time (e.g., "2h left", "Overdue by 30m")
- `timeRemainingInterval: TimeInterval` - Raw interval (negative if overdue)
- `isOverdue: Bool` - Whether past deadline and not completed

**Progress:**
- `timeProgress: Double` - Elapsed time as percentage (0.0 to 1.0)
- `timeRemainingProgress: Double` - Remaining time as percentage (1.0 to 0.0)

**Completion:**
- `completionDelta: TimeInterval?` - Time difference (positive = ahead, negative = late)
- `completionDeltaFormatted: String?` - Formatted delta (e.g., "-2d 3h 15m")

**Duration:**
- `totalDuration: TimeInterval` - Creation to deadline
- `activeDuration: TimeInterval?` - Start to completion

**Activity Extension:**
- `Activity.timeCalculator` - Convenience accessor

> **Note:** Testable via injectable `now` closure. Activity delegates to calculator for all time properties.

### StyleGuideFonts.swift
**ONLY** font sizes and pre-configured font styles. No colors.

**`AppFontSize`** - Size constants organized by category:
- **Icon sizes**: `iconXL` (48), `iconLarge` (44), `iconMedium` (40), `iconStandard` (28), `iconAction` (20), `iconInline` (18), `iconSmall` (14), `iconInfo` (11), `iconBadge` (10)
- **Header sizes**: `headerXL` (32), `headerLarge` (28), `headerPage` (24), `headerSection` (22)
- **Body sizes**: `subtitle` (17), `bodyLarge` (16), `bodyPrimary` (15), `bodySecondary` (14), `bodyStandard` (13)
- **Caption sizes**: `caption` (12), `captionSmall` (11), `captionTiny` (10)

**`AppFont`** - Pre-configured Font instances:
- **Headers**: `headerXL`, `headerLarge`, `headerPage`, `headerSection` (all bold, rounded)
- **Body**: `bodyLarge`, `bodyPrimary`, `bodyStandard` with weight variants (medium, semibold)
- **Captions**: `caption`, `captionSmall`, `captionTiny` with weight variants
- **Badges**: `badge`, `badgeCompact`, `priorityBadge`, `priorityBadgeCompact`
- **Buttons**: `buttonLarge`, `buttonStandard`, `buttonSmall`
- **Stats**: `statLarge`, `statMedium`

> **Note:** All font definitions are centralized here for consistent typography.

### AppSymbols.swift
Centralized SF Symbol names used throughout both apps.

**Categories:**
- Status icons: `running`, `completed`, `canceled`, `managerPending`, `teamMemberPending`
- Outcome icons: `outcomeAhead`, `outcomeJIT`, `outcomeOverrun`
- Action icons: `play`, `checkmark`, `xmark`, `plus`, etc.
- Navigation: `arrowRight`, `arrowLeft`, `chevronDown`
- Time/Calendar: `clock`, `calendar`, `hourglass`
- People/Team: `person3Sequence`, `personBadgePlus`
- UI: `magnifyingGlass`, `filter`, `flag`, `tray`

**Usage:** `Image(symbol: AppSymbols.checkmark)` instead of `Image(systemName: "checkmark")`

> **Note:** All SF Symbols are centralized - no hardcoded symbol strings in view files.

### Services/

#### ActivityFilter.swift
Provides filtering and querying for activity collections.

**Status Filters:**
- `running`, `completed`, `canceled`, `managerPending`, `teamMemberPending`
- `allPending` - Both manager and team member pending
- `active` - Running or any pending status

**Outcome Filters:**
- `completedAhead`, `completedJIT`, `completedOverrun`

**Other Filters:**
- `byPriority(_:)`, `byStatus(_:)`, `byOutcome(_:)`
- `assignedTo(_:)` - Returns new filter scoped to member
- `overdue`, `dueBefore(_:)`, `dueAfter(_:)`
- `search(_:)` - Text search across name, description, member

**Sorting:**
- `sortedByDeadline()`, `sortedByPriority()`, `sortedByCreatedAt()`

**Extensions:**
- `Team.activityFilter` - Create filter from team
- `[Activity].filter` - Create filter from array

#### ActivityStats.swift
Calculates statistics for activity collections.

**Count Stats:**
- `total`, `running`, `completed`, `canceled`, `allPending`, `active`, `overdue`
- `completedAhead`, `completedJIT`, `completedOverrun`
- `p0Count`, `p1Count`, `p2Count`, `p3Count`

**Percentage Stats:**
- `completionRate`, `overdueRate`, `aheadRate`, `onTimeRate`, `overrunRate`

**Extensions:**
- `Team.activityStats` - Create stats from team
- `[Activity].stats` - Create stats from array

#### ActivityService.swift
Handles activity mutations following Command pattern.

**ActivityService:**
- `startActivity(id:in:)` - Changes teamMemberPending → running
- `completeActivity(id:outcome:in:)` - Direct completion (manager)
- `cancelActivity(id:in:)` - Cancels activity
- `requestCompletion(id:outcome:in:)` - Changes running → managerPending
- `approveCompletion(id:in:)` - Approves request
- `rejectCompletion(id:in:)` - Rejects request

**TeamService:**
- `addMember(_:to:)`, `removeMember(id:from:)`
- `addActivity(_:to:)`, `removeActivity(id:from:)`

**CompletionRequestService:**
- `approve(_:activities:requests:)` - Approves and removes request
- `reject(_:activities:requests:)` - Rejects and removes request

> **Note:** Services are injectable and testable via `now` closure. ManagerAppState delegates to services.

### SharedComponents.swift
Reusable UI components used throughout both apps:

| Component | Description |
|-----------|-------------|
| `MemberAvatar` | Unified avatar with neutral color (supports member or custom initials) |
| `PriorityBadge` | Priority indicator (P0 red, P1-P3 grayscale) |
| `StatusBadge` | Activity status with icon and color |
| `OutcomeBadge` | Outcome indicator with icon |
| `TimeRemainingLabel` | Deadline countdown with optional progress bar |
| `TimeProgressBar` | Visual progress bar showing time remaining (color-coded: green → red) |
| `ActivityRow` | **Unified activity row component** used across all tabs in both apps |
| `ActivityInfoRow` | Icon + text info row |
| `EmptyStateView` | Empty state placeholder |
| `SectionHeader` | Section title with optional count |

**ActivityRow Features:**
- PriorityBadge + Activity name + StatusBadge
- TimeRemainingLabel with integrated progress bar
- Optional assignee display
- Overdue warning indicator
- Hover-activated action buttons (Start/Complete)
- Highlighted state for current user's activities

---

## Manager App (`valtaManager/`)

### Features
- **Two tabs**: Teams and Requests (per app header comment)
- **Onboarding flow**: Multi-step setup for new managers
- **Team management**: Add/remove members, view stats
- **Activity dashboard**: Create, view, filter, complete activities
- **Completion requests**: Approve/reject team member requests

### Views

#### OnboardingView.swift
- Welcome step with manager name input
- Team name creation step
- Member selection grid with animated cards
- Completion summary with animated checkmark
- Uses `AppGradients.managerBackground` and `AppColors.Manager.*`

#### TeamsTab.swift
- Left sidebar: team info, interactive stats grid, member list
- **Stats Grid**: Clickable stat cards that filter the activity list
  - Running (blue), Pending (purple), Completed (green), Total (light gray)
  - Click to filter, click again to clear, visual selection state
- **Member Filters**: Click team members to filter activities by assignee
  - Shows selection state with checkmark and accent color
  - Displays running count and total activities per member
  - Clear button in header, also clearable via dropdown
  - List with `.swipeActions` for native swipe-to-delete (full swipe supported)
- Activity dashboard with search and filters (status/priority/member)
- Uses `MemberAvatar` component for all avatars

#### ActivityCard.swift
- Priority badges with color coding
- Status badges with icons
- Assignee avatars using `MemberAvatar` component
- Time remaining/overdue indicators
- Expandable descriptions
- Complete/cancel actions on hover

#### RequestsTab.swift
- Request cards with requester `MemberAvatar`
- Activity details and requested outcome
- Approve/reject buttons with visual feedback
- "Approve All" bulk action
- Empty state when caught up

#### NewActivitySheet.swift
- Name, description, assignee picker with `MemberAvatar`
- Priority selection with visual cards
- Deadline picker with quick-set buttons (1h, 4h, 1d, 3d, 1w)
- Notification preview

---

## Team Member App (`valta/`)

### Features
- **Three tabs**: My Activities, Team, and Log (per app header comment)
- **Onboarding**: Select identity from team member list
- **Activity management**: Start activities, request completion
- **Team visibility**: View all team activities
- **Activity log**: History of all activity events

### Views

#### TeamMemberOnboardingView.swift
- Member selection grid with `MemberAvatar` component
- Uses `AppGradients.teamMemberBackground` and `AppColors.TeamMember.*`
- Animated selection cards
- Identity confirmation

#### ActivitiesTab.swift
- Header with user `MemberAvatar` and quick stats
- Sections: Needs Attention, In Progress, Awaiting Approval, Completed
- Compact activity rows with `TimeProgressBar` showing time remaining visually
- Hover actions for Start/Complete
- Request completion sheet with outcome selection

#### TeamTab.swift
- Team overview with member count and active activity count
- Grouped by team member with `MemberAvatar` and expandable sections
- Search and filter by completed activities
- Visual indicator for current user's activities

#### LogTab.swift
- Timeline view of activity events
- Grouped by date with `MemberAvatar` for assignees
- **Comprehensive filtering:**
  - Status filter: All statuses (Running, Completed, Canceled, Manager Pending, Team Member Pending)
  - Priority filter: P0-P3
  - Outcome filter: Ahead, Just In Time, Overrun
  - "My Activities" toggle
- Search functionality
- Action icons: created, started, completion requested, completed, canceled

---

## Design System

### App Themes

| App | Primary Colors | Background |
|-----|----------------|------------|
| Manager | Purple/Blue | Dark purple gradient |
| Team Member | Teal/Cyan | Dark teal gradient |

### Color Palette (via `AppColors`)

#### Priority Colors
| Priority | Color | Usage |
|----------|-------|-------|
| P0 Critical | `AppColors.priorityP0` | Red |
| P1 High | `AppColors.priorityP1` | Dark Gray (0.35) |
| P2 Medium | `AppColors.priorityP2` | Medium Gray (0.55) |
| P3 Low | `AppColors.priorityP3` | Light Gray (0.72) |

#### Outcome Colors
| Outcome | Color | Usage |
|---------|-------|-------|
| Ahead | `AppColors.outcomeAhead` | Green |
| Just In Time | `AppColors.outcomeJIT` | Yellow |
| Overrun | `AppColors.outcomeOverrun` | Red |

#### Avatar
- **All members**: `AppColors.avatar` (neutral gray)
- **Usage**: `MemberAvatar(member:)` or `MemberAvatar(initials:)`

### Typography
- Headers: `.system(size: 22-28, weight: .bold, design: .rounded)`
- Body: `.system(size: 13-15)`
- Captions: `.system(size: 11-12)`

### Special Rules
- **P0 Exception**: P0 activities with JIT outcome display red (not yellow)

---

## Specification Compliance

### Activity Status (from spec)
✅ running
✅ completed
✅ canceled
✅ manager pending
✅ team member pending

### Activity Priority (from spec)
✅ P0 - Critical
✅ P1 - High
✅ P2 - Medium
✅ P3 - Low

### Activity Outcomes (from spec)
✅ ahead - green
✅ jit - yellow
✅ overrun - red

### Manager App Features (from spec & header)
✅ Two tabs: Teams and Requests
✅ Team creation and member management
✅ Activity dashboard with all ongoing activities, statuses, and deadlines
✅ Activity creation with name, description, assigned member, deadline, and priority
✅ Completion request approval/rejection workflow
✅ Notification preview showing spec-compliant message format

### Team Member App Features (from spec & header)
✅ Three tabs: Activities, Team, and Log
✅ Select identity from predefined team member list
✅ View assigned activities and their status
✅ Start activities (changes status from pending to running)
✅ Request completion with outcome selection
✅ View all team activities
✅ Activity log with history

---

## Architecture Highlights

### Unified Design System
- All colors defined in `StyleGuide.swift` via `AppColors` and `AppGradients`
- Single `MemberAvatar` component used everywhere (no duplicate avatar code)
- Consistent theming: Manager (purple/blue) vs Team Member (teal/cyan)

### Shared Code
- Models and mock data shared between both apps
- UI components in `SharedComponents.swift` reduce duplication
- Both apps use same data structures for seamless future integration

### State Management
- `@Observable` pattern with `ManagerAppState` / `TeamMemberAppState`
- Centralized state for each app with computed properties
- Actions for modifying activities, approvals, etc.
