import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var showingInstructions = false
    @State private var showConfetti = false
    @State private var showingStatistics = false
    @State private var showingSettings = false  // New state for settings sheet
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Use ColorTheme with the colorScheme parameter
            ColorTheme.background(for: colorScheme).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    // Header with buttons
                    HStack {
                        // Left side buttons
                        VStack(spacing: 8) {  // Increased spacing from 8 to 16
                            Button {
                                showingStatistics = true
                            } label: {
                                Image(systemName: "chart.bar")
                                    .font(.title2)
                                    .foregroundColor(ColorTheme.primary(for: colorScheme))
                            }
                            
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.title2)
                                    .foregroundColor(ColorTheme.primary(for: colorScheme))
                            }
                        }
                        .padding(.leading)
                        .padding(.top, 25)  // Added top padding to move icons down
                        
                        Spacer()
                        
                        // Title
                        Text("MashUp")
                            .font(.system(size: 38, weight: .heavy))
                            .foregroundColor(ColorTheme.primary(for: colorScheme))
                        
                        Spacer()
                        
                        // Info button
                        Button {
                            showingInstructions = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(ColorTheme.primary(for: colorScheme))
                        }
                        .padding(.trailing)
                    }
                    .padding(.top, 20)
                    
                    // Handle completed game state
                    if gameViewModel.isPuzzleCompletedToday {
                        CompletedGameView(gameViewModel: gameViewModel)
                    } else {
                        // Regular game content
                        activeGameContent
                    }
                }
                .padding(.bottom, 20)
            }
            .environmentObject(gameViewModel)
            .sheet(isPresented: $showingInstructions) {
                InstructionsView()
            }
            .sheet(isPresented: $showingStatistics) {
                StatisticsView(viewModel: gameViewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            
            // Add confetti overlay
            ConfettiView(isShowing: $showConfetti)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
        .onChange(of: gameViewModel.gameCompleted) { oldValue, newValue in
            if newValue && gameViewModel.correctPairIndices.count == 5 {
                showConfetti = true
                // Automatically hide confetti after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showConfetti = false
                    }
                }
            }
        }
    }
    
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
    
    // Active game content (when today's puzzle hasn't been completed)
    private var activeGameContent: some View {
        VStack(spacing: 12) {
            // Subheader
            Text("Pair words in the correct order")
                .font(.subheadline)
                .foregroundColor(ColorTheme.primary(for: colorScheme).opacity(0.7))
                .padding(.top, -5)
                .padding(.bottom, 5)
            
            // Tries indicator
            if !gameViewModel.gameCompleted {
                HStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index < gameViewModel.triesRemaining ? ColorTheme.primary(for: colorScheme) : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.bottom, 5)
            }
            
            // Middle section - Active dragging area
            DraggableArea(gameViewModel: gameViewModel)
                .padding(.top, 5)
            
            // Submit or Reset button
            if gameViewModel.gameCompleted {
                VStack(spacing: 12) {
                    // Results message
                    Text(gameViewModel.resultsMessage)
                        .font(.headline)
                        .foregroundColor(ColorTheme.primary(for: colorScheme))
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                    
                    // Share button
                    Button(action: {
                        gameViewModel.shareResults()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Results")
                        }
                        .font(.headline)
                        .foregroundColor(ColorTheme.secondary(for: colorScheme)) // Use dynamic secondary color instead of white
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
                }
                .padding(.vertical, 10)
                .transition(.opacity)
            } else if gameViewModel.hasSubmitted {
                // Feedback during check
                Text(gameViewModel.resultsMessage)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primary(for: colorScheme))
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 10)
                    .transition(.opacity)
            } else if gameViewModel.allWordsPlaced {
                // Submit button - appears when all words are placed
                Button(action: {
                    withAnimation {
                        gameViewModel.checkPairs()
                    }
                }) {
                    Text("Check Pairs")
                        .font(.headline)
                        .foregroundColor(ColorTheme.secondary(for: colorScheme)) // Use dynamic secondary color
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(ColorTheme.primary(for: colorScheme))
                                .shadow(color: ColorTheme.primary(for: colorScheme).opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                }
                .padding(.vertical, 10)
                .transition(.opacity)
            }
            
            // After the game completed section, add the correct answers reveal
            if gameViewModel.showingCorrectAnswers {
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
            
            Spacer()
            
            // Available words
            let availableWords = gameViewModel.words.filter { !$0.isPaired }
            if !availableWords.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Words")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        ForEach(availableWords) { word in
                            WordCardView(word: word)
                                .border(Color.clear)
                                .contentShape(Rectangle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
                .opacity(gameViewModel.gameCompleted ? 0.6 : 1) // Dim when game is over
            }
        }
    }
}

// Add FlowLayout to handle wrapped content
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            spacing: spacing,
            subviews: subviews
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            spacing: spacing,
            subviews: subviews
        )
        for row in result.rows {
            for item in row {
                item.view.place(
                    at: CGPoint(x: item.x + bounds.minX, y: item.y + bounds.minY),
                    proposal: .unspecified
                )
            }
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var rows: [[Item]] = []
        
        struct Item {
            var view: LayoutSubview
            var size: CGSize
            var x: CGFloat
            var y: CGFloat
        }
        
        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: LayoutSubviews) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var currentRow: [Item] = []
            var maxHeight: CGFloat = 0
            
            for view in subviews {
                let viewSize = view.sizeThatFits(.unspecified)
                if currentX + viewSize.width > maxWidth, !currentRow.isEmpty {
                    // Move to next row
                    currentX = 0
                    currentY += maxHeight + spacing
                    rows.append(currentRow)
                    currentRow = []
                    maxHeight = 0
                }
                
                currentRow.append(Item(view: view, size: viewSize, x: currentX, y: currentY))
                currentX += viewSize.width + spacing
                maxHeight = max(maxHeight, viewSize.height)
            }
            
            if !currentRow.isEmpty {
                rows.append(currentRow)
                currentY += maxHeight
            }
            
            size = CGSize(width: maxWidth, height: currentY)
        }
    }
}

#Preview {
    ContentView()
}
