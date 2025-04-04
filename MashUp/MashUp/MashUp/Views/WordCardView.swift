import SwiftUI
import UniformTypeIdentifiers

struct WordCardView: View {
    let word: Word
    @State private var isDragging = false
    @State private var offset: CGSize = .zero
    @Environment(\.colorScheme) private var colorScheme
    
    // Match slot dimensions
    private let cardWidth: CGFloat = 80
    private let cardHeight: CGFloat = 40
    
    var body: some View {
        Text(word.text.uppercased())
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(ColorTheme.secondary(for: colorScheme))
            .frame(width: cardWidth - 8, height: cardHeight - 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(ColorTheme.primary(for: colorScheme))
                    .shadow(color: .black.opacity(isDragging ? 0.3 : 0.15), 
                            radius: isDragging ? 8 : 4, 
                            x: 0, 
                            y: isDragging ? 4 : 2)
            )
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .offset(offset)
            .animation(.spring(response: 0.4), value: isDragging)
            .animation(.spring(response: 0.4), value: offset)
            .draggable(word.text) {
                Text(word.text.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ColorTheme.secondary(for: colorScheme))
                    .frame(width: cardWidth - 8, height: cardHeight - 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(ColorTheme.primary(for: colorScheme))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                    .onAppear {
                        isDragging = true
                    }
                    .onDisappear {
                        isDragging = false
                    }
            }
    }
}
