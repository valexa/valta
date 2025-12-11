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
    @State private var loggedInEmails: Set<String> = []
    
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
                    
                    VStack(spacing: 12) {
                        Text(currentStep == .selectTeam ? "Select Your Team" : "Select Your Name")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    // Content based on step
                    if currentStep == .selectTeam {
                        TeamSelectionView(selectedTeam: $selectedTeam)
                    } else {
                        MemberSelectionView(team: selectedTeam!, selectedMember: $selectedMember, loggedInEmails: loggedInEmails)
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
            // Fetch members that are already logged in elsewhere
            loggedInEmails = await NotificationService.shared.getLoggedInMemberEmails()
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
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 20)], spacing: 20) {
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
    var loggedInEmails: Set<String> = []
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Team: \(team.name)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                ForEach(team.members) { member in
                    let isLoggedIn = loggedInEmails.contains(member.email)
                    MemberSelectionCard(
                        member: member,
                        isSelected: selectedMember?.id == member.id,
                        isDisabled: isLoggedIn,
                        action: { selectedMember = member }
                    )
                }
            }
            .frame(maxWidth: 600)
        }
    }
}



// MARK: - Preview

#Preview {
    TeamMemberOnboardingView()
        .environment(TeamMemberAppState())
        .environment(DataManager.shared)
}
