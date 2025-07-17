import SwiftUI

struct TabButton: View {
    let tab: AnalysisTab
    @Binding var selectedTab: AnalysisTab
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {
            selectedTab = tab
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .frame(width: 16, height: 12)
                Text(title)
                    .font(.custom("NunitoSans-Bold", size: 10))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(selectedTab == tab ? Color.accent : Color.mainText.opacity(0.6))
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 