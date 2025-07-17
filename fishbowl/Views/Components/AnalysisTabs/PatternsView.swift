import SwiftUI

struct PatternsView: View {
    @ObservedObject var thoughtAnalyzer: ThoughtAnalyzer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let patterns = thoughtAnalyzer.getDiscoveredPatterns()
            let breakthroughs = thoughtAnalyzer.getBreakthroughs()
            
            if !patterns.isEmpty || !breakthroughs.isEmpty {
                if !patterns.isEmpty {
                    Text("Patterns:")
                        .font(.custom("NunitoSans-Bold", size: 11))
                        .foregroundColor(Color.mainText)
                    
                    ForEach(patterns, id: \.self) { pattern in
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11))
                                .foregroundColor(Color.accent)
                            Text(pattern)
                                .font(.custom("NunitoSans-Regular", size: 11))
                                .foregroundColor(Color.mainText.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                if !breakthroughs.isEmpty {
                    Text("Breakthroughs:")
                        .font(.custom("NunitoSans-Bold", size: 11))
                        .foregroundColor(Color.success)
                    
                    ForEach(breakthroughs, id: \.self) { breakthrough in
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "target")
                                .font(.system(size: 11))
                                .foregroundColor(Color.success)
                            Text(breakthrough)
                                .font(.custom("NunitoSans-Regular", size: 11))
                                .foregroundColor(Color.success.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } else {
                Text("Weekly patterns will appear here after more analysis")
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