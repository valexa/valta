//
//  BaseAppState.swift
//  Shared
//
//  Base class for observable state management.
//  Provides common functionality for data synchronization and lifecycle.
//
//  Created by Vlad on 2025-12-09.
//

import SwiftUI
import Observation

@Observable
class BaseAppState {
    // Reference to DataManager for live data
    let dataManager = DataManager.shared
    
    // Services
    let activityService = ActivityService()
    
    // Shared state
    var hasCompletedOnboarding: Bool = false
    var dataVersion: Int = 0
    
    init() {
        // Observe DataManager team changes
        NotificationCenter.default.addObserver(forName: DataManager.dataChangedNotification, object: nil, queue: .main) { [weak self] _ in
            self?.onTeamsChanged()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Open for override
    func onTeamsChanged() {
        dataVersion &+= 1
    }
}
