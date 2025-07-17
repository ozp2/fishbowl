import SwiftUI

struct AnalysisView: View {
    @ObservedObject var thoughtAnalyzer: ThoughtAnalyzer
    @ObservedObject var scheduler: SchedulerService
    @Binding var selectedTab: AnalysisTab
    @Binding var showAnalysis: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with tab selection
            HStack {
                HStack(spacing: 4) {
                    TabButton(tab: .daily, selectedTab: $selectedTab, icon: "calendar", title: "Daily")
                    TabButton(tab: .themes, selectedTab: $selectedTab, icon: "eyeglasses", title: "Themes")
                    TabButton(tab: .suggestions, selectedTab: $selectedTab, icon: "lightbulb", title: "Ideas")
                    TabButton(tab: .patterns, selectedTab: $selectedTab, icon: "chart.line.uptrend.xyaxis", title: "Patterns")
                    
                    if thoughtAnalyzer.isAnalyzing {
                        VStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 16, height: 12)
                            Text("Analyzing")
                                .font(.custom("NunitoSans-Bold", size: 10))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color.mainText.opacity(0.6))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    } else {
                        Button(action: {
                            Task {
                                await thoughtAnalyzer.analyzeTodaysThoughts()
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 12))
                                    .frame(width: 16, height: 12)
                                Text("Refresh")
                                    .font(.custom("NunitoSans-Bold", size: 10))
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color.mainText.opacity(0.6))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Tab content
            VStack(alignment: .leading, spacing: 8) {
                switch selectedTab {
                case .daily:
                    DailyAnalysisView(thoughtAnalyzer: thoughtAnalyzer)
                case .themes:
                    ThemesView(thoughtAnalyzer: thoughtAnalyzer)
                case .suggestions:
                    SuggestionsView(thoughtAnalyzer: thoughtAnalyzer)
                case .patterns:
                    PatternsView(thoughtAnalyzer: thoughtAnalyzer)
                }
            }
        }
        .onAppear {
            Task {
                if thoughtAnalyzer.shouldDiscoverThemes() {
                    await thoughtAnalyzer.discoverThemes()
                }
            }
        }
    }
} 