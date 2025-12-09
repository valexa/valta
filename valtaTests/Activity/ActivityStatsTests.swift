//
//  ActivityStatsTests.swift
//  valtaTests
//
//  Created by ANTIGRAVITY on 2025-12-08.
//

import Testing
import Foundation
@testable import valta

struct ActivityStatsTests {
    
    @Test func testStatsCalculation() {
        let activities =
            TestDataFactory.makeRunning(2) +
            TestDataFactory.makeCompleted(ahead: 2, jit: 1, overrun: 1) +
            TestDataFactory.makePending(teamMember: 1, manager: 1)
        
        let filter = ActivityFilter(activities: activities)
        let stats = ActivityStats(filter: filter)
        
        #expect(stats.total == 8)
        #expect(stats.running == 2)
        #expect(stats.completed == 4) // 2 ahead + 1 jit + 1 overrun
        #expect(stats.completedAhead == 2)
        #expect(stats.completedJIT == 1)
        #expect(stats.completedOverrun == 1)
        
        // pending = teamMemberPending + managerPending
        #expect(stats.allPending == 2)
        #expect(stats.active == 4) // running + pending
    }
    
    @Test func testEmptyStats() {
        let filter = ActivityFilter(activities: [])
        let stats = ActivityStats(filter: filter)
        
        #expect(stats.total == 0)
        #expect(stats.active == 0)
        #expect(stats.completed == 0)
    }
}
