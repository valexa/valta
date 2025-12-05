//
//  CSVService.swift
//  Shared
//
//  Handles CSV parsing and serialization for Activities and Teams.
//
//  Created by vlad on 2025-12-04.
//

import Foundation
import SwiftUI

class CSVService {
    static let shared = CSVService()
    
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    // MARK: - Activities
    
    func parseActivities(csvString: String, teamMembers: [TeamMember]) -> [Activity] {
        var activities: [Activity] = []
        let lines = csvString.components(separatedBy: .newlines)
        
        // Skip header row
        guard lines.count > 1 else { return [] }
        
        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // Skip header
            let columns = parseCSVLine(line)
            if columns.count < 9 { continue } // Ensure minimum required columns
            
            // Schema: id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt
            
            let idString = columns[0]
            let name = columns[1]
            let description = columns[2]
            let memberName = columns[3]
            let priorityString = columns[4]
            let statusString = columns[5]
            let outcomeString = columns[6]
            let createdAtString = columns[7]
            let deadlineString = columns[8]
            let startedAtString = columns.count > 9 ? columns[9] : ""
            let completedAtString = columns.count > 10 ? columns[10] : ""
            
            // Find assigned member
            guard let member = teamMembers.first(where: { $0.name == memberName }) else {
                print("Warning: Member \(memberName) not found for activity \(name)")
                continue
            }
            
            // Parse Enums
            let priority = parsePriority(priorityString)
            let status = ActivityStatus(rawValue: statusString) ?? .teamMemberPending
            let outcome = ActivityOutcome(rawValue: outcomeString)
            
            // Parse Dates
            guard let createdAt = dateFormatter.date(from: createdAtString),
                  let deadline = dateFormatter.date(from: deadlineString) else {
                continue
            }
            
            let startedAt = dateFormatter.date(from: startedAtString)
            let completedAt = dateFormatter.date(from: completedAtString)
            
            let activity = Activity(
                id: UUID(uuidString: idString) ?? UUID(),
                name: name,
                description: description,
                assignedMember: member,
                priority: priority,
                status: status,
                outcome: outcome,
                createdAt: createdAt,
                deadline: deadline,
                startedAt: startedAt,
                completedAt: completedAt
            )
            
            activities.append(activity)
        }
        
        return activities
    }
    
    func serializeActivities(_ activities: [Activity]) -> String {
        var csv = "id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt\n"
        
        for activity in activities {
            let row = [
                activity.id.uuidString,
                escapeCSV(activity.name),
                escapeCSV(activity.description),
                escapeCSV(activity.assignedMember.name),
                activity.priority.shortName.lowercased(), // p0, p1 etc
                activity.status.rawValue,
                activity.outcome?.rawValue ?? "",
                dateFormatter.string(from: activity.createdAt),
                dateFormatter.string(from: activity.deadline),
                activity.startedAt.map { dateFormatter.string(from: $0) } ?? "",
                activity.completedAt.map { dateFormatter.string(from: $0) } ?? ""
            ]
            
            csv += row.joined(separator: ",") + "\n"
        }
        
        return csv
    }
    
    // MARK: - Teams
    
    func parseTeams(csvString: String) -> [(teamName: String, member: TeamMember)] {
        var members: [(String, TeamMember)] = []
        let lines = csvString.components(separatedBy: .newlines)
        
        // Skip header row
        guard lines.count > 1 else { return [] }
        
        for (index, line) in lines.enumerated() {
            if index == 0 { continue }
            let columns = parseCSVLine(line)
            if columns.count < 3 { continue }
            
            // Schema: name, team, email
            let name = columns[0]
            let teamName = columns[1]
            let email = columns[2]
            
            let member = TeamMember(name: name, email: email)
            members.append((teamName, member))
        }
        
        return members
    }
    
    // MARK: - Helpers
    
    private func parsePriority(_ string: String) -> ActivityPriority {
        switch string.lowercased() {
        case "p0": return .p0
        case "p1": return .p1
        case "p2": return .p2
        case "p3": return .p3
        default: return .p3
        }
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return string
    }
}
