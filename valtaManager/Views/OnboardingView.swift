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
    @Environment(AppState.self) private var appState
    @EnvironmentObject private var dataManager: DataManager
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
                    Image(systemName: "exclamationmark.triangle.fill")
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
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 20)], spacing: 20) {
                            ForEach(dataManager.teams) { team in
                                TeamSelectionCard(
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
                    Button(action: finishOnboarding) {
                        HStack(spacing: 8) {
                            Text("Start Managing")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Image(symbol: AppSymbols.arrowRight)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [
                                    AppColors.Manager.primary,
                                    AppColors.Manager.secondary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: AppColors.Manager.secondary.opacity(0.4), radius: 15, y: 5)
                    }
                    .buttonStyle(.plain)
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

struct TeamSelectionCard: View {
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
                                colors: [AppColors.Manager.teamNameStart, AppColors.Manager.teamNameEnd],
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
                        isSelected ? AppColors.Manager.primary : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
        .environmentObject(DataManager.shared)
}
