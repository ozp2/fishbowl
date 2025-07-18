//
//  ContentView.swift
//  fishbowl
//
//  Created by Olivia on 7/11/25.
//

import SwiftUI

struct ContentView: View {
    @State private var journalText: String = ""
    @State private var saveMessage: String? = nil
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var errorMessage: String? = nil
    @State private var showAnalysis: Bool = false
    @State private var analysisTab: AnalysisTab = .daily
    
    @StateObject private var scheduler = SchedulerService()
    @StateObject private var thoughtAnalyzer = ThoughtAnalyzer()
    @StateObject private var notificationService = NotificationService()
    
    // Add timer to clear status messages
    private let statusMessageDuration: TimeInterval = 2.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with analysis toggle
            HStack (alignment: .center) {
                Text(showAnalysis ? "Thought analysis" : "What's on your mind?")
                    .font(.custom("NunitoSans-Bold", size: 16))
                    .frame(height: 20, alignment: .center)
                    .padding(.bottom, 12)
                    .padding(.top, 8)
                
                Spacer()
                
                Button(action: toggleAnalysis) {
                    Image(systemName: showAnalysis ? "xmark.circle.fill" : "sparkles")
                        .foregroundColor(Color.accent)
                        .font(.system(size: 16))
                        .padding(8)
                        .background(Color.surface)
                        .clipShape(Circle())
                        .frame(height: 20, alignment: .center)
                        .shadow(color: Color.black.opacity(0.1), radius: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .help(showAnalysis ? "Close analysis" : "Show analysis")
                .padding(.trailing, 4)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Analysis view
                if showAnalysis {
                    ScrollView(.vertical, showsIndicators: false) {
                        AnalysisView(
                            thoughtAnalyzer: thoughtAnalyzer,
                            scheduler: scheduler,
                            selectedTab: $analysisTab,
                            showAnalysis: $showAnalysis
                        )
                        .transition(AnyTransition.slide)
                        .animation(.easeInOut, value: showAnalysis)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // Text editor
                    ZStack(alignment: .topLeading) {
                        if journalText.isEmpty {
                            Text("Write your thoughts here...")
                                .foregroundColor(Color.mainText)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .font(.custom("NunitoSans-Regular", size: 14))
                                .kerning(0.2)
                        }
                        TextEditor(text: $journalText)
                            .font(.custom("NunitoSans-Regular", size: 14))
                            .kerning(0.2)
                            .padding(.leading, 8)
                            .padding(.trailing, 14)
                            .padding(.vertical, 12)
                            .scrollContentBackground(.hidden)
                            .scrollDisabled(true)
                            .lineSpacing(4)
                    }
                    .frame(minHeight: 290)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accent.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Save button and status
                    HStack {
                        if let message = saveMessage {
                            StatusMessage(message: message, type: .success)
                        } else if let error = errorMessage {
                            StatusMessage(message: error, type: .error)
                        } else {
                            Button(action: saveEntry) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                    Text("Save Thoughts")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.accent)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .font(.custom("NunitoSans-Bold", size: 14))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(journalText.isEmpty)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 10)
        }
        .padding()
        .frame(width: 360, height: 425)
        .background(Color.surfaceContainer)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            setupServices()
        }
        .onDisappear {
            scheduler.stopScheduler()
        }
    }
    
    private func setupServices() {
        scheduler.startScheduler()
        
        // Check for any pending analysis results
        Task {
            let status = scheduler.getAnalysisStatus()
            if status.daily || status.weekly || status.themes {
                showAnalysis = true
            }
        }
    }
    
    private func toggleAnalysis() {
        withAnimation {
            showAnalysis.toggle()
        }
    }
    
    private func saveEntry() {
        do {
            let fileService = FileService()
            try fileService.saveJournalEntry(journalText)
            
            showSaveMessage("Entry saved!")
            journalText = ""
            
            Task {
                if thoughtAnalyzer.shouldDiscoverThemes() {
                    logDebug("Starting theme discovery", category: "ContentView")
                    await thoughtAnalyzer.discoverThemes()
                } else {
                    logDebug("Skipping theme discovery - conditions not met", category: "ContentView")
                }
            }
        } catch {
            ErrorHandlingService.shared.handle(error, context: "Saving journal entry")
            showError("Failed to save entry: \(error.localizedDescription)")
        }
    }
    
    private func showSaveMessage(_ message: String) {
        saveMessage = message
        clearStatusMessageAfterDelay()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        clearStatusMessageAfterDelay()
    }
    
    private func clearStatusMessageAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + statusMessageDuration) {
            saveMessage = nil
            errorMessage = nil
        }
    }
}

// MARK: - Status Message View
struct StatusMessage: View {
    let message: String
    let type: StatusType
    
    enum StatusType {
        case success
        case error
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .success
            case .error: return .errorRed
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .success: return .successLight
            case .error: return .lightRed
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            Text(message)
                .font(.custom("NunitoSans-Bold", size: 14))
                .foregroundColor(type.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(type.backgroundColor)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

#Preview {
    ContentView()
}
