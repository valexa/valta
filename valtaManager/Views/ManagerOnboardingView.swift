//
//  ManagerOnboardingView.swift
//  valtaManager
//
//  Onboarding flow for manager setup.
//  Allows user to select an existing team from the database.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

enum ViewState: Equatable {
    case loading
    case failed(String)
    case loaded
}

struct ManagerOnboardingView: View {
    @Environment(ManagerAppState.self) private var appState
    @Environment(DataManager.self) private var dataManager
    @State private var selectedTeam: Team?
    @State private var state: ViewState

    private let disableAutoState: Bool

    init(initialState: ViewState = .loading, disableAutoState: Bool = false) {
        _state = State(initialValue: initialState)
        self.disableAutoState = disableAutoState
    }

    var body: some View {
        ZStack {
            // Background gradient
            AppGradients.managerBackground
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

    private func finishOnboarding() {
        guard selectedTeam != nil else { return }
        appState.hasCompletedOnboarding = true
    }
}

// MARK: - View States

extension ManagerOnboardingView {

    @ViewBuilder
    var loadedState: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 12) {
                Image(symbol: AppSymbols.person3Sequence)
                    .font(AppFont.iconXL)
                    .foregroundColor(.white)

                Text("Select Your Team")
                    .font(AppFont.headerXL)
                    .foregroundColor(.white)

                Text("Choose a team to manage from the list below")
                    .font(AppFont.bodyLarge)
                    .foregroundColor(.white.opacity(0.7))
            }

            // Team List
            TeamSelectionView(selectedTeam: $selectedTeam)

            // Continue Button
            Button("Start Managing", systemImage: AppSymbols.arrowRight, action: finishOnboarding)
                .onboardingButton()
                .disabled(selectedTeam == nil)
                .opacity(selectedTeam == nil ? 0.5 : 1.0)
        }
        .padding(40)
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
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.Manager.glowPrimary.opacity(0.15),
                                    AppColors.Manager.glowSecondary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: CGFloat.random(in: 100...300))
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

#Preview("Loaded") {
    ManagerOnboardingView(initialState: .loaded, disableAutoState: true)
        .environment(ManagerAppState())
        .environment(DataManager.shared)
}

#Preview("Loading") {
    ManagerOnboardingView(initialState: .loading, disableAutoState: true)
        .environment(ManagerAppState())
        .environment(DataManager.shared)
}

#Preview("Error") {
    ManagerOnboardingView(initialState: .failed("Failed to connect to server."), disableAutoState: true)
        .environment(ManagerAppState())
        .environment(DataManager.shared)
}
