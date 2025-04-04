import SwiftUI

struct CompletedGameView: View {
    @ObservedObject var gameViewModel: GameViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Subheader
            Text("Today's Completed Puzzle")
                .font(.subheadline)
                .foregroundColor(ColorTheme.primary(for: colorScheme).opacity(0.7))
                .padding(.top, -5)
                .padding(.bottom, 5)
            
            // Tries indicator (locked)
            HStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index < gameViewModel.triesRemaining ? ColorTheme.primary(for: colorScheme) : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.bottom, 5)
            
            // Show the completed game board with placed words
            CompletedDraggableArea(gameViewModel: gameViewModel)
                .padding(.top, 5)
                .disabled(true) // Disable any interactions
            
            // Results message
            Text(gameViewModel.resultsMessage)
                .font(.headline)
                .foregroundColor(ColorTheme.primary(for: colorScheme))
                .padding(.horizontal)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
            
            // Share button
            Button(action: {
                gameViewModel.shareResults()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Results")
                }
                .font(.headline)
                .foregroundColor(ColorTheme.secondary(for: colorScheme))
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(ColorTheme.primary(for: colorScheme))
                        .shadow(color: ColorTheme.primary(for: colorScheme).opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
            
            // Next puzzle countdown
            Text("Next puzzle in: \(timeUntilNextPuzzle)")
                .font(.footnote)
                .foregroundColor(.gray)
            
            // Show correct answers if needed
            if gameViewModel.showingCorrectAnswers {
                correctAnswersView
            }
            
            Spacer(minLength: 20)
        }
        .padding(.vertical, 10)
    }
    
    // Calculate time until next puzzle
    private var timeUntilNextPuzzle: String {
        let calendar = Calendar.current
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
            return ""
        }
        
        let midnight = calendar.startOfDay(for: tomorrow)
        // Fix the deprecated syntax with the correct method call
        let components = calendar.dateComponents([.hour, .minute], from: now, to: midnight)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
    
    // Extract correct answers into a separate view
    private var correctAnswersView: some View {
        VStack(spacing: 16) {
            Text("Correct Answers:")
                .font(.headline)
                .foregroundColor(ColorTheme.primary(for: colorScheme))
            
            ForEach(gameViewModel.correctAnswersForDisplay, id: \.first) { pair in
                HStack(spacing: 12) {
                    Text(pair.first.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                    
                    Image(systemName: "plus")
                        .foregroundColor(.gray)
                    
                    Text(pair.second.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
        .padding(.horizontal)
        .transition(.opacity)
    }
}

// Non-interactive draggable area for completed game view
struct CompletedDraggableArea: View {
    @ObservedObject var gameViewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { pairIndex in
                    CompletedPairSlotView(
                        pairIndex: pairIndex,
                        leftWord: gameViewModel.activeWords[pairIndex * 2],
                        rightWord: gameViewModel.activeWords[pairIndex * 2 + 1],
                        isCorrectPair: gameViewModel.correctPairIndices.contains(pairIndex)
                    )
                }
            }
            .padding(.vertical, 20)
        }
        .padding(.horizontal)
        .frame(maxHeight: 400)
    }
}

struct CompletedPairSlotView: View {
    let pairIndex: Int
    let leftWord: Word?
    let rightWord: Word?
    let isCorrectPair: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Left word
            CompletedSlotView(
                word: leftWord,
                isCorrect: isCorrectPair
            )
            .frame(width: 130)
            
            // Divider
            Rectangle()
                .fill(
                    isCorrectPair ? Color.green.opacity(0.5) : Color.red.opacity(0.5)
                )
                .frame(width: 2, height: 44)
            
            // Right word
            CompletedSlotView(
                word: rightWord,
                isCorrect: isCorrectPair
            )
            .frame(width: 130)
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isCorrectPair ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
                )
        )
    }
}

struct CompletedSlotView: View {
    let word: Word?
    let isCorrect: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private let slotWidth: CGFloat = 80
    private let slotHeight: CGFloat = 40
    
    var body: some View {
        ZStack {
            // Container
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4]))
                .fill(
                    isCorrect ? Color.green.opacity(0.7) : Color.red.opacity(0.7)
                )
                .frame(width: slotWidth, height: slotHeight)
                .opacity(word == nil ? 1 : 0) // Show only if no word
            
            // Word if present
            if let word = word {
                Text(word.text.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ColorTheme.secondary(for: colorScheme))
                    .frame(width: slotWidth - 8, height: slotHeight - 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                isCorrect ? Color.green : Color.red
                            )
                    )
            }
        }
        .frame(width: slotWidth, height: slotHeight)
    }
}
