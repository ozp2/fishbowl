import SwiftUI

struct DailyAnalysisView: View {
    @ObservedObject var thoughtAnalyzer: ThoughtAnalyzer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let analysis = thoughtAnalyzer.dailyAnalysis {
                // Overarching Areas
                if !analysis.overarchingAreas.isEmpty {
                    VStack(alignment: .leading, spacing: 8 ) {
                        Text("Life Areas")
                            .font(.custom("NunitoSans-Bold", size: 13))
                            .foregroundColor(Color.mainText)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(analysis.overarchingAreas, id: \.self) { area in
                                Text(area)
                                    .font(.custom("NunitoSans-Regular", size: 11))
                                    .foregroundColor(Color.mainText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accent.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // Today's Themes
                if !analysis.themesToday.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's Focus")
                            .font(.custom("NunitoSans-Bold", size: 13))
                            .foregroundColor(Color.mainText)
                        
                        ForEach(analysis.themesToday, id: \.self) { theme in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 4))
                                    .foregroundColor(Color.accent)
                                    .padding(.top, 6)
                                Text(theme.replacingOccurrences(of: "_", with: " "))
                                    .font(.custom("NunitoSans-Regular", size: 11))
                                    .foregroundColor(Color.mainText)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // Key Insights
                if !analysis.keyInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Insights")
                            .font(.custom("NunitoSans-Bold", size: 13))
                            .foregroundColor(Color.mainText)
                        
                        ForEach(analysis.keyInsights, id: \.self) { insight in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.accent)
                                    .padding(.top, 3)
                                Text(insight)
                                    .font(.custom("NunitoSans-Regular", size: 11))
                                    .foregroundColor(Color.mainText.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // Areas Needing Attention
                if !analysis.focusAreas.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Areas for Attention")
                            .font(.custom("NunitoSans-Bold", size: 13))
                            .foregroundColor(Color.mainText)
                        
                        ForEach(analysis.focusAreas, id: \.self) { area in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "burst.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.accent)
                                    .padding(.top, 3)
                                Text(area)
                                    .font(.custom("NunitoSans-Regular", size: 11))
                                    .foregroundColor(Color.mainText.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color.accent)
                    Text("Analyzing your thoughts...")
                        .font(.custom("NunitoSans-Regular", size: 11))
                        .foregroundColor(Color.mainText.opacity(0.6))
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding(.horizontal, 12)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accent.opacity(0.2), lineWidth: 1)
        )
    }
} 
