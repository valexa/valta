# Live Team Activities

A macOS application suite for real-time team activity management, consisting of two companion apps for managers and team members.

## Overview

Live Team Activities provides a centralized platform for tracking tasks, deadlines, and progress visibility among team members. The system enables managers to assign activities with priorities and deadlines, while team members can start, track, and complete their assigned work.

## Apps

### valta (Team Member App)

The workspace for team members to manage their assigned activities.

**Features:**
- **My Activities** - View and manage personally assigned activities
- **Start Activities** - Acknowledge and begin assigned work
- **Request Completion** - Submit completion requests with automatic outcome assessment
- **Team Visibility** - See what everyone on the team is working on
- **Activity Log** - Browse history of all activity events
- **Dock Badge** - App icon shows count of pending activities awaiting start

**Tabs:**
| Tab | Description |
|-----|-------------|
| My Activities | Personal activity queue with pending, running, and completed sections |
| Team | All team activities grouped by member |
| Log | Timeline of activity events with status, priority, and outcome filters |


### valtaManager (Manager App)

The control center for team leaders to manage teams and activities.

**Features:**
- **Team Selection** - Choose team from Firebase Storage (CSV)
- **Activity Dashboard** - View all activities with search and filters
- **Activity Creation** - Assign activities with priority (P0-P3), deadlines, and descriptions
- **Approval Workflow** - Review and approve/reject completion requests from team members
- **Interactive Stats** - Click stat cards to filter the activity list by status
- **Dock Badge** - App icon shows count of pending completion requests

**Tabs:**
| Tab | Description |
|-----|-------------|
| Teams | Team sidebar with member list, stats grid, and activity dashboard |
| Requests | Pending completion requests from team members awaiting approval |


## Activity System

### Priorities
| Priority | Level | Color |
|----------|-------|-------|
| P0 | Critical | 🔴 Red |
| P1 | High | 🔲 Dark Gray |
| P2 | Medium | ▫️ Medium Gray |
| P3 | Low | ⬜ Light Gray |

### Statuses
| Status | Description | Color |
|--------|-------------|-------|
| Team Member Pending | Awaiting team member to start | Purple |
| Running | Activity in progress | Blue |
| Manager Pending | Completion request awaiting approval | Red |
| Completed | Activity finished | Green |
| Canceled | Activity was canceled | Gray |

### Outcomes
| Outcome | Meaning | Color |
|---------|---------|-------|
| Ahead | Completed ≥30 min before deadline | 🟢 Green |
| Just In Time | Completed within ±5 min of deadline (before or after) | 🟡 Yellow |
| Overrun | Completed >5 min after deadline | 🔴 Red |

> **Note:** P0 (Critical) activities with "Just In Time" outcome display red instead of yellow.

## Design System

Both apps share a unified design system with centralized colors and reusable components.

### App Themes
- **Manager App** - Purple/blue gradient theme with hidden title bar
- **Team Member App** - Teal/cyan gradient theme with hidden title bar
- **Window Style** - Both apps use `.hiddenTitleBar` with `.unified` toolbar style for modern macOS appearance

### Navigation
- **Native TabView** - Both apps use SwiftUI's native `TabView` with `Tab` views for seamless navigation
- **Dock Badges** - Automatic badge counts on app icons for pending activities

### Shared Components
- `MemberAvatar` - Unified avatar component with neutral gray color
- `PriorityBadge` - Priority indicator (P0 red, P1-P3 grayscale)
- `StatusBadge` - Activity status with icon and color-coded display
- `OutcomeBadge` - Outcome indicator with icon
- `TimeRemainingLabel` - Deadline countdown with optional progress bar
- `TimeProgressBar` - Visual progress bar (green → yellow → orange → red)
- `ActivityRow` - Unified activity row used across all tabs in both apps

## Project Structure


(See Xcode project for file structure)

## Architecture & State Management

### Architecture

The architecture is based on MVVM with clearly separated views, state classes, and model layers.

- **Models**: Define core business data structures including `Activity`, `Team`, `TeamMember`.
- **State Classes**: `@Observable` classes (`BaseAppState`, `TeamMemberAppState`, `ManagerAppState`) manage state and business logic with automatic UI updates.
- **Views**: SwiftUI views composed with reusable components and bound to state via `@Environment`.
- **Services**: Networking, data persistence, and synchronization layers abstracted behind protocols.

### State Management

- **@Observable**: Swift 5.9+ Observation framework for automatic UI updates (replaces legacy `ObservableObject`/`@Published`).
- **@Environment**: Injects shared app state into views.
- **NotificationCenter**: Data change propagation via `DataManager.dataChangedNotification`.
- **State restoration**: Persistence of UI state via `UserDefaults` for continuity.
- **Data flow**: Unidirectional—actions trigger state class updates, which update models, then views automatically re-render.

### Data Flow Example

User taps "Start Activity" → View calls state method → State updates Activity status → Observable properties update automatically → UI re-renders → Persistence saves updated status to Firebase Storage.

---

## Hybrid persistence strategy:
> This project uses a hybrid persistence strategy:
> *   **Activities & Teams Data**: Persisted via **CSV files** in **Firebase Storage**.
> *   **Notifications (FCM Tokens)**: Persisted via **Firestore**.
> 
> Firestore is strictly for token management. Do not use it for core data persistence.

## Requirements

- macOS 26.0+
- Xcode 26.1+
- Swift 5.0+

## Getting Started

1. Open `valta.xcodeproj` in Xcode
2. Select the scheme you want to run:
   - `valtaManager` - Manager app
   - `valta` - Team member app
3. **SwiftLint Setup** (optional but recommended):
   - Install SwiftLint: `brew install swiftlint`
   - **Important**: Set `ENABLE_USER_SCRIPT_SANDBOXING = NO` in Build Settings for each target, or the linter won't be able to read project files
   - Add a Run Script Build Phase with: `/opt/homebrew/bin/swiftlint`
4. Build and run (⌘R)

## Documentation

- `FULL_SPECIFICATION.md` - Complete product specification
- `IMPLEMENTATION_PLAN.md` - Development roadmap and progress
- `PUSH_NOTIFICATIONS_PLAN.md` - Push notification specific plan
- `NOTIFICATION_SETUP_GUIDE.md` - Push notification setup guide
- `PROJECT_COMP.md` - Detailed implementation summary
- `PROJECT_RULES.md` - Detailed AI rules

## License

See [LICENSE](LICENSE) file.
