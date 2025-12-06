//
//  TeamMemberOnboardingView.swift
//  valta
//
//  Onboarding flow for team members to select their team and identity.
//  Two-step process: 1) Select team, 2) Select member name.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct TeamMemberOnboardingView: View {
    @Environment(TeamMemberAppState.self) private var appState
    @Environment(DataManager.self) private var dataManager
    @State private var selectedTeam: Team?
    @State private var selectedMember: TeamMember?
    @State private var currentStep: OnboardingStep = .selectTeam
    
    enum OnboardingStep {
        case selectTeam
        case selectMember
    }
    
    var body: some View {
        ZStack {
            // Background gradient - teal/cyan theme for team member app
            AppGradients.teamMemberBackground
                .ignoresSafeArea()
            
            // Animated background elements
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.TeamMember.glowPrimary.opacity(0.12),
                                        AppColors.TeamMember.glowSecondary.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: CGFloat.random(in: 100...250))
                            .offset(
                                x: CGFloat.random(in: -200...geometry.size.width),
                                y: CGFloat.random(in: -100...geometry.size.height)
                            )
                            .blur(radius: 50)
                    }
                }
            }
            
            if dataManager.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                    Text("Loading Teams...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
            } else if let error = dataManager.errorMessage {
                VStack(spacing: 16) {
                    Image(symbol: AppSymbols.exclamationTriangle)
                        .font(.system(size: 44))
                        .foregroundColor(AppColors.destructive)
                    Text("Error loading teams")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await dataManager.loadData() }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                }
                .padding()
            } else {
                VStack(spacing: 40) {
                    // Logo/Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.TeamMember.primary,
                                        AppColors.TeamMember.primaryEnd
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: AppColors.TeamMember.primary.opacity(0.5), radius: 25, y: 8)
                        
                        Image(symbol: AppSymbols.personCropCircleBadgeCheckmark)
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 12) {
                        Text(currentStep == .selectTeam ? "Select Your Team" : "Select Your Name")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(currentStep == .selectTeam ? "Choose which team you're part of" : "Who are you?")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Content based on step
                    if currentStep == .selectTeam {
                        TeamSelectionView(selectedTeam: $selectedTeam)
                    } else {
                        MemberSelectionView(team: selectedTeam!, selectedMember: $selectedMember)
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentStep == .selectMember {
                            Button(action: {
                                withAnimation {
                                    currentStep = .selectTeam
                                    selectedMember = nil
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(symbol: AppSymbols.arrowLeft)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white.opacity(0.7))
                            }
                            .onboardingButton()
                        }
                        
                        Button(action: handleContinue) {
                            HStack(spacing: 8) {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Image(symbol: AppSymbols.arrowRight)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                        }
                        .onboardingButton()
                        .tint(.primary)
                        .disabled(!canContinue)
                    }
                }
                .padding(40)
            }
        }
        .frame(minWidth: 700, minHeight: 550)
        .task {
            if dataManager.teams.isEmpty {
                await dataManager.loadData()
            }
        }
    }
    
    private var canContinue: Bool {
        switch currentStep {
        case .selectTeam:
            return selectedTeam != nil
        case .selectMember:
            return selectedMember != nil
        }
    }
    
    private func handleContinue() {
        switch currentStep {
        case .selectTeam:
            withAnimation {
                currentStep = .selectMember
            }
        case .selectMember:
            if let member = selectedMember {
                withAnimation(.spring(duration: 0.5)) {
                    appState.selectMember(member)
                }
            }
        }
    }
}

// MARK: - Team Selection View

struct TeamSelectionView: View {
    @Environment(DataManager.self) private var dataManager
    @Binding var selectedTeam: Team?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 20)], spacing: 20) {
                ForEach(dataManager.teams) { team in
                    TeamCard(
                        team: team,
                        isSelected: selectedTeam?.id == team.id,
                        action: {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedTeam = team
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: 800)
        }
    }
}

// MARK: - Member Selection View

struct MemberSelectionView: View {
    let team: Team
    @Binding var selectedMember: TeamMember?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Team: \(team.name)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 12) {
                ForEach(team.members) { member in
                    MemberSelectionCard(
                        member: member,
                        isSelected: selectedMember?.id == member.id,
                        avatarSize: 44,
                        style: .teamMemberOnboarding,
                        action: { selectedMember = member }
                    )
                }
            }
            .frame(maxWidth: 600)
        }
    }
}

// MARK: - Team Card

struct TeamCard: View {
    let team: Team
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(symbol: AppSymbols.rectangleGroup)
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.TeamMember.primary, AppColors.TeamMember.primaryEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Spacer()
                    
                    if isSelected {
                        Image(symbol: AppSymbols.checkmark)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(AppColors.success)
                            .clipShape(Circle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(team.members.count) members")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Member preview avatars
                HStack(spacing: -8) {
                    ForEach(Array(team.members.prefix(5))) { member in
                        MemberAvatar(member: member, size: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                    }
                    if team.members.count > 5 {
                        Text("+\(team.members.count - 5)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 12)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? AppColors.TeamMember.primary : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    TeamMemberOnboardingView()
        .environment(TeamMemberAppState())
        .environment(DataManager.shared)
}
