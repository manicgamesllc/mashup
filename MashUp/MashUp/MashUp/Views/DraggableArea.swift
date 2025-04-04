import SwiftUI
import UniformTypeIdentifiers

struct DraggableArea: View {
    @ObservedObject var gameViewModel: GameViewModel
    @State private var isTargeted = false
    
    let pairCount = 5
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                ForEach(0..<pairCount, id: \.self) { pairIndex in
                    PairSlotView(
                        pairIndex: pairIndex,
                        leftWord: gameViewModel.activeWords[pairIndex * 2],
                        rightWord: gameViewModel.activeWords[pairIndex * 2 + 1]
                    )
                }
            }
            .padding(.vertical, 20)
        }
        .padding(.horizontal)
        .frame(maxHeight: 400)
    }
}

private struct PairSlotView: View {
    let pairIndex: Int
    let leftWord: Word?
    let rightWord: Word?
    @EnvironmentObject private var gameViewModel: GameViewModel
    @State private var isSliding = false
    
    var pairResult: Bool? {
        gameViewModel.isPairCorrect(pairIndex: pairIndex)
    }
    
    var resultColor: Color {
        if let result = pairResult {
            return result ? Color.green : Color.red
        }
        return Color.clear // No result yet
    }
    
    var isCorrectPair: Bool {
        gameViewModel.correctPairIndices.contains(pairIndex)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            SlotView(
                word: leftWord,
                slotIndex: pairIndex * 2,
                resultColor: resultColor,
                offset: isCorrectPair && isSliding ? 45 : 0  // Increased slide distance
            )
            .frame(width: 130)
            .opacity(isCorrectPair && isSliding ? 1 : 1) // Keep words visible
            
            // Divider
            Rectangle()
                .fill(
                    isCorrectPair ? Color.green.opacity(0.5) :
                        gameViewModel.hasSubmitted ? resultColor.opacity(0.5) : 
                        ColorTheme.primary.opacity(0.3)
                )
                .frame(width: 2, height: 44)
                .opacity(isCorrectPair && isSliding ? 0 : 1)  // Fade out divider
            
            SlotView(
                word: rightWord,
                slotIndex: pairIndex * 2 + 1,
                resultColor: resultColor,
                offset: isCorrectPair && isSliding ? -45 : 0  // Increased slide distance
            )
            .frame(width: 130)
            .opacity(isCorrectPair && isSliding ? 1 : 1) // Keep words visible
        }
        .padding(.vertical, 4)
        .onChange(of: isCorrectPair) { oldValue, newValue in
            if newValue {
                // Trigger sliding animation when pair becomes correct
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isSliding = true
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isCorrectPair ? Color.green.opacity(0.1) :
                        resultColor.opacity(0.1)
                )
                .opacity(gameViewModel.hasSubmitted || isCorrectPair ? 1 : 0)
        )
    }
}

private struct SlotView: View {
    let word: Word?
    let slotIndex: Int
    let resultColor: Color
    let offset: CGFloat  // Add offset parameter for sliding animation
    
    @EnvironmentObject private var gameViewModel: GameViewModel
    @State private var isTargeted = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Constants for sizing
    private let slotWidth: CGFloat = 80
    private let slotHeight: CGFloat = 40
    
    var isInCorrectPair: Bool {
        gameViewModel.isWordInCorrectPair(at: slotIndex)
    }
    
    var body: some View {
        ZStack {
            // Dotted border container - update colors to work in dark mode
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4]))
                .fill(
                    isInCorrectPair ? Color.green.opacity(0.7) :
                        gameViewModel.hasSubmitted ? 
                            resultColor.opacity(0.7) :
                            ColorTheme.primary(for: colorScheme).opacity(isTargeted ? 0.4 : 0.2)
                )
                .frame(width: slotWidth, height: slotHeight)
                .background(isTargeted ? ColorTheme.primary(for: colorScheme).opacity(0.1) : Color.clear)
                .opacity(isInCorrectPair ? 0 : 1) // Hide dotted border when correct
                .animation(.easeInOut(duration: 0.2), value: isTargeted)
            
            // Word card that fills the container - update colors
            if let word = word {
                Text(word.text.uppercased()) // Convert to uppercase
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ColorTheme.secondary(for: colorScheme)) // Update text color for contrast
                    .frame(width: slotWidth - 8, height: slotHeight - 8) // Slightly smaller than container
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                isInCorrectPair ? Color.green :
                                    gameViewModel.hasSubmitted ? resultColor : 
                                    ColorTheme.primary(for: colorScheme)
                            )
                    )
                    .offset(x: offset)  // Apply the sliding offset
                    .transition(.scale.combined(with: .opacity))
                    .onTapGesture {
                        if !gameViewModel.hasSubmitted && !gameViewModel.gameCompleted && !isInCorrectPair {
                            gameViewModel.removeWord(at: slotIndex)
                        }
                    }
                    .draggable("\(slotIndex):\(word.text)") { // Include slot index in drag data
                        Text(word.text.uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: slotWidth - 8, height: slotHeight - 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(ColorTheme.primary)
                            )
                    }
            }
        }
        .frame(width: slotWidth, height: slotHeight)
        .contentShape(Rectangle())
        // Use drop modifier that works with String (word text)
        .dropDestination(for: String.self) { items, _ in
            // Don't allow drops if results are showing, game completed, or slot is in a correct pair
            guard !gameViewModel.hasSubmitted && !gameViewModel.gameCompleted && !isInCorrectPair else { return false }
            
            guard let droppedData = items.first else { return false }
            
            // Check if this is a word being swapped from another slot
            if droppedData.contains(":") {
                let components = droppedData.split(separator: ":")
                if components.count == 2,
                   let sourceIndex = Int(components[0]) {
                    // Swap words between slots
                    gameViewModel.swapWords(from: sourceIndex, to: slotIndex)
                    return true
                }
            } else {
                // Handle dropping new word from available words
                if let droppedWord = gameViewModel.words.first(where: { $0.text == droppedData && !$0.isPaired }) {
                    gameViewModel.addWordToSpecificSlot(droppedWord, at: slotIndex)
                    return true
                }
            }
            return false
        } isTargeted: {
            isTargeted = $0 && !gameViewModel.hasSubmitted && !gameViewModel.gameCompleted && !isInCorrectPair
        }
        // Add a custom overlay to hide the default plus indicator
        .overlay(
            isTargeted ? Color.clear : Color.clear
        )
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
