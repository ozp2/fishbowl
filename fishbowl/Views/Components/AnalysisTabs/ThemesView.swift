import SwiftUI

struct ThemesView: View {
    @ObservedObject var thoughtAnalyzer: ThoughtAnalyzer
    @State private var showAllThemes = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let themes = thoughtAnalyzer.activeThemes
            
            if !themes.isEmpty {
                ForEach(themes.prefix(showAllThemes ? themes.count : 4)) { theme in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .center, spacing: 2) {
                                Text(theme.name)
                                    .font(.custom("NunitoSans-Bold", size: 12))
                                    .foregroundColor(Color.mainText)
                                
                                Spacer()
                                
                                Text("\(theme.frequency)×")
                                    .font(.custom("NunitoSans-Bold", size: 10))
                                    .foregroundColor(Color.accent)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 0.5)
                                    .background(Color.accent.opacity(0.1))
                                    .cornerRadius(3)
                            }
                            
                            Text(theme.summary)
                                .font(.custom("NunitoSans-Regular", size: 11))
                                .foregroundColor(Color.mainText.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if themes.count > 4 {
                    Button(action: { showAllThemes.toggle() }) {
                        Text(showAllThemes ? "Show Less" : "Show All")
                            .font(.custom("NunitoSans-Regular", size: 11))
                            .foregroundColor(Color.accent)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 4)
                }
            } else {
                Text("No active themes found")
                    .font(.custom("NunitoSans-Regular", size: 11))
                    .foregroundColor(Color.mainText.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
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