//
//  SharedFilterMenus.swift
//  Shared
//
//  reusable filter menu components used in both Manager and Member apps.
//  Encapsulates the Menu, Picker/Button logic, and consistent visual styling.
//
//  Created by vlad on 2025-12-06.
//

import SwiftUI

// MARK: - Status Filter Menu

struct StatusFilterMenu: View {
    @Binding var selection: ActivityStatus?
    
    var body: some View {
        Menu {
            Button("All Statuses") {
                selection = nil
            }
            
            Divider()
            
            ForEach(ActivityStatus.allCases, id: \.self) { status in
                Button(action: {
                    selection = status
                }) {
                    HStack {
                        Image(symbol: status.icon)
                        Text(status.rawValue)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(symbol: AppSymbols.filter)
                Text(selection?.rawValue ?? "Status")
                    .lineLimit(1)
                    .fixedSize()
                Image(symbol: AppSymbols.chevronDown)
                    .font(.caption2)
            }
        }
    }
}

// MARK: - Priority Filter Menu

struct PriorityFilterMenu: View {
    @Binding var selection: ActivityPriority?
    
    var body: some View {
        Menu {
            Button("All Priorities") {
                selection = nil
            }

            Divider()
            
            ForEach(ActivityPriority.allCases, id: \.self) { priority in
                Button(action: { selection = priority }) {
                    HStack {
                        Image(symbol: priority.icon)
                        Text(priority.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(symbol: AppSymbols.flagBadge)
                Text(selection?.shortName ?? "Priority")
                Image(symbol: AppSymbols.chevronDown)
                    .font(.caption2)
            }
        }
    }
}

// MARK: - Outcome Filter Menu

struct OutcomeFilterMenu: View {
    @Binding var selection: ActivityOutcome?
    
    var body: some View {
        Menu {
            Button("All Outcomes") {
                selection = nil
            }

            Divider()
            
            ForEach(ActivityOutcome.allCases, id: \.self) { outcome in
                Button(action: { selection = outcome }) {
                    HStack {
                        Image(symbol: outcome.icon)
                            .foregroundColor(outcome.color)
                        Text(outcome.rawValue)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(symbol: AppSymbols.outcome)
                Text(selection?.rawValue ?? "Outcome")
                Image(symbol: AppSymbols.chevronDown)
                    .font(.caption2)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HStack {
        StatusFilterMenu(selection: .constant(nil))
        PriorityFilterMenu(selection: .constant(nil))
        OutcomeFilterMenu(selection: .constant(nil))
    }
    .padding()
}
