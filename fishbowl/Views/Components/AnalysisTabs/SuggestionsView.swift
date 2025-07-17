import SwiftUI

struct SuggestionsView: View {
    @ObservedObject var thoughtAnalyzer: ThoughtAnalyzer
    @State private var showAllSuggestions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let suggestions = thoughtAnalyzer.getAllSuggestions()
            
            if !suggestions.isEmpty {
                ForEach(suggestions.prefix(showAllSuggestions ? suggestions.count : 3), id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.accent)
                            .padding(.top, 4)
                        Text(suggestion)
                            .font(.custom("NunitoSans-Regular", size: 11))
                            .foregroundColor(Color.mainText.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if suggestions.count > 3 {
                    Button(action: {
                        withAnimation {
                            showAllSuggestions.toggle()
                        }
                    }) {
                        Text(showAllSuggestions ? "Show less" : "+ \(suggestions.count - 3) more suggestions")
                            .font(.custom("NunitoSans-Regular", size: 10))
                            .foregroundColor(Color.accent)
                    }
                }
            } else {
                Text("No suggestions yet - analyze your thoughts first")
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