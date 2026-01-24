# Changelog

## [2026-01-24]

### v1.0(8)

### Features & Enhancements

#### Timeline (Migration & UI/UX)
- **Migrated Timeline**: Moved the `TimelineTab` from the Manager app to the Member app to allow team members better visibility into team activity.
- **Improved Alignment**: The timeline view is now horizontally centered when data is sparse, providing a more balanced layout on large screens.
- **Dynamic Sizing**: Removed fixed-height constraints on activity sections; they now expand to utilize all available vertical space.
- **Outcome Visualization**: Added color-coded dots in activity popovers (Green for Ahead, Blue for Just-In-Time, Red for Overrun) for immediate performance feedback.

#### Analytics & Projections
- **Monthly Analytics**: Updated analytics graphs to automatically switch to a monthly view when logs span multiple months, improving long-term trend visibility.
- **Outcome Projections**: Introduced a new "Projections" tab in the Manager app, powered by a dedicated `OutcomeProjectionService` to forecast activity finishing states.

#### Data & Infrastructure
- **Unified Filtering System**: Implemented a reusable `ActivityFilterState` and `SharedFilterBar` to provide consistent filtering (Status, Priority, Outcome, Search) across both the Log and Timeline tabs.
- **Enhanced Data Management**: Improved `CSVService` and `ActivityService` for more robust handling of activity data and outcomes.
- **Navigation Updates**: Integrated the new Timeline and Projections features into the respective app's `MainTabView` and `AppState`.

### Technical Details
- Added `ActivityFilterState` and `SharedFilterBar` reusable components.
- Added `OutcomeProjectionService.swift`.
- Added `ProjectionsTab.swift` to Manager app.
- Moved and refactored `TimelineTab.swift` to Member app.
- Updated `TeamMemberAppState` and `ManagerAppState` to support new tabs and data services.
- Updated `LogTab.swift` to utilize the new shared filtering system.
