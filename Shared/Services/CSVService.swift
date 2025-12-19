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

/// Represents a parsed team member entry from CSV
struct TeamMemberEntry {
    let teamName: String
    let member: TeamMember
    let managerEmail: String?
}

// MARK: - CSV Parsing Protocol

/// Protocol for CSV parsing and serialization operations
protocol CSVParsing {
    func parseActivities(csvString: String, teamMembers: [TeamMember]) -> [Activity]
    func serializeActivities(_ activities: [Activity]) -> String
    func parseTeams(csvString: String) -> [TeamMemberEntry]
}

// MARK: - CSV Service

class CSVService: CSVParsing {
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

            // Schema: id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt,manager

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
            let managerEmail = columns.count > 11 ? columns[11].trimmingCharacters(in: .whitespacesAndNewlines) : nil
            let finalManagerEmail = (managerEmail?.isEmpty ?? true) ? nil : managerEmail

            // Find assigned member
            guard let member = teamMembers.findMember(byName: memberName) else {
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
                completedAt: completedAt,
                managerEmail: finalManagerEmail
            )

            activities.append(activity)
        }

        return activities
    }

    func serializeActivities(_ activities: [Activity]) -> String {
        var csv = "id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt,manager\n"

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
                activity.completedAt.map { dateFormatter.string(from: $0) } ?? "",
                activity.managerEmail ?? ""
            ]

            csv += row.joined(separator: ",") + "\n"
        }

        return csv
    }

    // MARK: - Teams

    func parseTeams(csvString: String) -> [TeamMemberEntry] {
        var members: [TeamMemberEntry] = []
        let lines = csvString.components(separatedBy: .newlines)

        // Skip header row
        guard lines.count > 1 else { return [] }

        for (index, line) in lines.enumerated() {
            if index == 0 { continue }
            let columns = parseCSVLine(line)
            if columns.count < 3 { continue }

            // Schema: name, team, email OR id, name, team, email OR name, team, email, manager
            let hasId = columns.count >= 4 && UUID(uuidString: columns[0]) != nil
            let id: UUID
            let name: String
            let teamName: String
            let email: String
            let managerEmail: String?

            if hasId {
                // New format with ID
                id = UUID(uuidString: columns[0])!
                name = columns[1]
                teamName = columns[2]
                email = columns[3]
                managerEmail = columns.count > 4 ? columns[4].trimmingCharacters(in: .whitespacesAndNewlines) : nil
            } else {
                // Legacy format without ID - generate deterministic UUID from name+email
                name = columns[0]
                teamName = columns[1]
                email = columns[2]
                managerEmail = columns.count > 3 ? columns[3].trimmingCharacters(in: .whitespacesAndNewlines) : nil
                // Use hash of name+email for deterministic UUID
                let seed = "\(name)|\(email)".lowercased()
                id = UUID(uuidString: deterministicUUID(from: seed)) ?? UUID()
            }

            let finalManagerEmail = (managerEmail?.isEmpty ?? true) ? nil : managerEmail
            let member = TeamMember(id: id, name: name, email: email)
            members.append(TeamMemberEntry(teamName: teamName, member: member, managerEmail: finalManagerEmail))
        }

        return members
    }

    /// Generates a deterministic UUID from a string seed
    private func deterministicUUID(from seed: String) -> String {
        let hash = seed.utf8.reduce(0) { ($0 &+ UInt64($1)) &* 16777619 }
        let part1 = String(format: "%08X", (hash >> 32) & 0xFFFFFFFF)
        let part2 = String(format: "%04X", (hash >> 16) & 0xFFFF)
        let part3 = String(format: "%04X", hash & 0xFFFF)
        let part4 = String(format: "%04X", (~hash >> 32) & 0xFFFF)
        let part5 = String(format: "%012X", hash & 0xFFFFFFFFFFFF)
        return "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
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
