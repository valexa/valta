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

enum ViewState: Equatable {
    case loading
    case failed(String)
    case loaded
}

struct TeamMemberOnboardingView: View {
    @Environment(TeamMemberAppState.self) private var appState
    @Environment(DataManager.self) private var dataManager
    @State private var selectedTeam: Team?
    @State private var selectedMember: TeamMember?
    @State private var currentStep: OnboardingStep = .selectTeam
    @State private var loggedInEmails: Set<String> = []
    @State private var state: ViewState

    private let disableAutoState: Bool

    init(initialState: ViewState = .loading, disableAutoState: Bool = false) {
        _state = State(initialValue: initialState)
        self.disableAutoState = disableAutoState
    }

    enum OnboardingStep {
        case selectTeam
        case selectMember
    }

    var body: some View {
        ZStack {

            // Background gradient - teal/cyan theme for team member app
            AppGradients.teamMemberBackground
                .ignoresSafeArea()

            background

            switch state {
            case .loading:
                loadingState
            case .failed(let error):
                errorState(error: error)
            case .loaded:
                loadedState
            }
        }
        .frame(minWidth: 700, minHeight: 550)
        .task {
            // Always try to reload data first (shows spinner), regardless of cache
            await dataManager.loadData()
            // Fetch members that are already logged in elsewhere
            loggedInEmails = await NotificationService.shared.getLoggedInMemberEmails()
        }
        .onChange(of: dataManager.isLoading) { _, isLoading in
            guard !disableAutoState else { return }
            if isLoading {
                state = .loading
            } else if let error = dataManager.errorMessage {
                state = .failed(error)
            } else {
                state = .loaded
            }
        }
        .onAppear {
            guard !disableAutoState else { return }
            // Always start with loading state to show spinner while data refreshes
            state = .loading
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
                withAnimation(AppAnimations.springSlow) {
                    appState.selectMember(member)
                }
            }
        }
    }
}

// MARK: - View States

extension TeamMemberOnboardingView {

    @ViewBuilder
    var loadedState: some View {
        VStack(spacing: AppSpacing.huge) {

            VStack(spacing: AppSpacing.base) {
                Text(currentStep == .selectTeam ? "Select Your Team" : "Select Your Name")
                    .font(AppFont.headerXL)
                    .foregroundColor(.white)
            }

            // Content based on step
            if currentStep == .selectTeam {
                TeamSelectionView(selectedTeam: $selectedTeam)
            } else {
                MemberSelectionView(team: selectedTeam!, selectedMember: $selectedMember, loggedInEmails: loggedInEmails)
            }

            // Navigation buttons
            HStack(spacing: AppSpacing.xl) {
                if currentStep == .selectMember {
                    Button(action: {
                        withAnimation {
                            currentStep = .selectTeam
                            selectedMember = nil
                        }
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(symbol: AppSymbols.arrowLeft)
                                .font(AppFont.bodyPrimary)
                            Text("Back")
                                .font(AppFont.buttonLarge)
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .onboardingButton()
                }

                Button(action: handleContinue) {
                    HStack(spacing: AppSpacing.sm) {
                        Text("Continue")
                            .font(AppFont.buttonLarge)

                        Image(symbol: AppSymbols.arrowRight)
                            .font(AppFont.bodyPrimary)
                    }
                    .foregroundColor(.white)
                }
                .onboardingButton()
                .tint(.primary)
                .disabled(!canContinue)
            }
        }
        .padding(AppSpacing.huge)
    }

    @ViewBuilder
    func errorState(error: String) -> some View {
        ErrorView(title: "Error loading teams", message: error) {
            Task { await dataManager.loadData() }
        }
    }

    @ViewBuilder
    var loadingState: some View {
        LoadingView(message: "Loading Teams...")
    }

    var background: some View {
        // Animated background elements
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<5) { _ in
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
    }
}

// MARK: - Member Selection View

struct MemberSelectionView: View {
    let team: Team
    @Binding var selectedMember: TeamMember?
    var loggedInEmails: Set<String> = []

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Text("Team: \(team.name)")
                .font(AppFont.bodyPrimaryMedium)
                .foregroundColor(.white.opacity(0.6))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                ForEach(team.members) { member in
                    let isLoggedIn = loggedInEmails.contains(member.email)
                    MemberSelectionCard(
                        member: member,
                        isSelected: selectedMember?.id == member.id,
                        isDisabled: isLoggedIn
                    ) { selectedMember = member }
                }
            }
            .frame(maxWidth: 600)
        }
    }
}

// MARK: - Preview

#Preview("Loaded") {
    TeamMemberOnboardingView(initialState: .loaded, disableAutoState: true)
        .environment(TeamMemberAppState())
        .environment(DataManager.shared)
}

#Preview("Loading") {
    TeamMemberOnboardingView(initialState: .loading, disableAutoState: true)
        .environment(TeamMemberAppState())
        .environment(DataManager.shared)
}

#Preview("Error") {
    TeamMemberOnboardingView(initialState: .failed("Failed to connect to server."), disableAutoState: true)
        .environment(TeamMemberAppState())
        .environment(DataManager.shared)
}
