//
//  OnboardingView.swift
//  valtaManager
//
//  Onboarding flow for manager setup.
//  Allows user to select an existing team from the database.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(ManagerAppState.self) private var appState
    @Environment(DataManager.self) private var dataManager
    @State private var selectedTeam: Team?
    
    var body: some View {
        ZStack {
            // Background gradient
            AppGradients.managerBackground
                .ignoresSafeArea()
            
            // Animated background elements
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<3) { i in
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
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(symbol: AppSymbols.person3Sequence)
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                        
                        Text("Select Your Team")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Choose a team to manage from the list below")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 60)
                    
                    // Team List
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
                        .padding(.bottom, 20)
                    }
                    
                    // Continue Button
                    Button("Start Managing", systemImage: AppSymbols.arrowRight, action: finishOnboarding)
                        .onboardingButton()
                    .disabled(selectedTeam == nil)
                    .opacity(selectedTeam == nil ? 0.5 : 1.0)
                    .padding(.bottom, 40)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 550)
        .task {
            if dataManager.teams.isEmpty {
                await dataManager.loadData()
            }
        }
    }
    
    private func finishOnboarding() {
        guard selectedTeam != nil else { return }
        // Team is already set in DataManager by the user selecting it
        // AppState now reads from DataManager.teams
        appState.hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
        .environment(ManagerAppState())
        .environment(DataManager.shared)
}
