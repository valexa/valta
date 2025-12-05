//
//  RefreshTimer.swift
//  Shared
//
//  Shared timer service that triggers UI refresh every minute.
//  Used to keep time-based displays (progress bars, time remaining) current.
//
//  Created by vlad on 2025-12-04.
//

import Foundation
import Combine

// MARK: - Refresh Timer

/// Observable timer that triggers refresh every minute for time-sensitive UI updates
@Observable
final class RefreshTimer {
    
    /// Increments every minute to trigger UI refresh
    private(set) var tick: UInt64 = 0
    
    /// The current time, updated every minute
    private(set) var currentTime: Date = Date()
    
    /// Timer subscription
    private var timerCancellable: AnyCancellable?
    
    /// Refresh interval in seconds (default: 60 seconds)
    let interval: TimeInterval
    
    // MARK: - Initialization
    
    init(interval: TimeInterval = 60) {
        self.interval = interval
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Timer Control
    
    /// Starts the refresh timer
    func start() {
        guard timerCancellable == nil else { return }
        
        timerCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.refresh(at: date)
            }
    }
    
    /// Stops the refresh timer
    func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    /// Manually trigger a refresh
    func refresh(at date: Date = Date()) {
        tick &+= 1  // Overflow-safe increment
        currentTime = date
    }
}

// MARK: - Shared Instance

extension RefreshTimer {
    /// Shared timer instance for the app
    static let shared = RefreshTimer()
}

