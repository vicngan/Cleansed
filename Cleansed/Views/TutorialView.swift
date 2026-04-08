//
//  TutorialView.swift
//  Cleansed
//
//  Created by Gemini CLI on 3/20/26.
//

import SwiftUI

enum TutorialPageType {
    case standard
    case widgetTutorial
}

struct TutorialPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let type: TutorialPageType
    var steps: [TutorialStep] = []

    static let all: [TutorialPage] = [
        TutorialPage(
            title: "welcome to clero",
            description: "a minimalist approach to managing your productivity and digital focus.",
            icon: "leaf.fill",
            type: .standard
        ),
        TutorialPage(
            title: "focus & screen time",
            description: "set focus schedules to block distracting apps and regain your time. simply select apps and set your timer.",
            icon: "hourglass",
            type: .standard
        ),
        TutorialPage(
            title: "habits & todos",
            description: "track your daily routines and complete tasks with ease. stay on top of your day with a clean, focused list.",
            icon: "checkmark.circle.fill",
            type: .standard
        ),
        TutorialPage(
            title: "adding widgets",
            description: "bring your focus to your home screen. follow these simple steps to add clero widgets.",
            icon: "square.dashed.inset.filled",
            type: .widgetTutorial,
            steps: [
                TutorialStep(text: "long press on your home screen", icon: "hand.tap.fill"),
                TutorialStep(text: "tap 'edit' in the top left corner", icon: "pencil.line"),
                TutorialStep(text: "select 'add widget' from the menu", icon: "plus"),
                TutorialStep(text: "search for 'clero' and add it", icon: "magnifyingglass")
            ]
        ),
        TutorialPage(
            title: "customize your style",
            description: "long press a widget and select 'edit widget' to choose a specific habit or todo list.",
            icon: "paintpalette.fill",
            type: .standard
        )
    ]
}

struct TutorialStep: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
}

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<TutorialPage.all.count, id: \.self) { index in
                        TutorialPageView(page: TutorialPage.all[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Spacer()
                
                // Bottom Navigation
                HStack {
                    if currentPage > 0 {
                        Button {
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            Text("back")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 30)
                        .padding(.bottom, 30)
                    }
                    
                    Spacer()
                    
                    Button {
                        if currentPage < TutorialPage.all.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: currentPage < TutorialPage.all.count - 1 ? "arrow.right" : "checkmark")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(.systemBackground))
                        }
                        .shadow(color: Color.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

struct TutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        VStack(spacing: 30) {
            if page.type == .standard {
                StandardPageView(page: page)
            } else {
                WidgetTutorialPageView(page: page)
            }
        }
        .padding()
    }
}

struct StandardPageView: View {
    @Environment(\.colorScheme) var colorScheme
    let page: TutorialPage
    
    var body: some View {
        VStack(spacing: 40) {
            if page.title == "welcome to clero" {
                Image(colorScheme == .dark ? "logo-dark" : "logo-light")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .padding(20)
            } else {
                Image(systemName: page.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundStyle(Color.primary)
                    .padding(30)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                    )
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .textCase(.lowercase)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
                    .textCase(.lowercase)
            }
        }
    }
}

struct WidgetTutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .textCase(.lowercase)
                
                Text(page.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .textCase(.lowercase)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                ForEach(page.steps) { step in
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: step.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(.systemBackground))
                        }
                        
                        Text(step.text)
                            .font(.body)
                            .foregroundStyle(Color.primary)
                            .textCase(.lowercase)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal)
        }
    }
}

#Preview {
    TutorialView()
}
