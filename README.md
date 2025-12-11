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

## Architecture & State Management (Updated)

### Architecture

The architecture is based on MVVM with clearly separated views, view models, and model layers.

- **Models**: Define core business data structures including `Activity`, `TeamMember`, `CompletionRequest`.
- **ViewModels**: Handle state and business logic, exposing observable properties to views.
- **Views**: SwiftUI views composed with reusable components and bound to view models.
- **Services**: Networking, data persistence, and synchronization layers abstracted behind protocols.

### State Management

- **ObservableObject**: Used for view models to publish changes.
- **@Published**: Properties that need to update views.
- **EnvironmentObject**: For shared app state across views.
- **Combine**: Reactive framework for asynchronous events and binding.
- **State restoration**: Persistence of UI state for continuity.
- **Data flow**: Unidirectional where possible, with actions triggering view model updates, which update models, then views.

### Data Flow Example

- User taps "Start Activity" → View notifies ViewModel → ViewModel updates Activity status → Published changes reflect in UI → Persistence saves updated status.

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
3. Build and run (⌘R)

## Documentation

- `FULL_SPECIFICATION.md` - Complete product specification
- `IMPLEMENTATION_PLAN.md` - Development roadmap and progress
- `PUSH_NOTIFICATIONS_PLAN.md` - Push notification specific plan
- `NOTIFICATION_SETUP_GUIDE.md` - Push notification setup guide
- `PROJECT_COMP.md` - Detailed implementation summary
- `PROJECT_RULES.md` - Detailed AI rules

## License

See [LICENSE](LICENSE) file.
