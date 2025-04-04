import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var words: [Word]
    @Published var activeWords: [Word?] = Array(repeating: nil, count: 10) // Fixed size array of optionals
    @Published var resultsMessage = ""
    @Published var pairResults: [Bool] = [] // Store which pairs are correct
    @Published var hasSubmitted = false // Track if results have been submitted
    @Published var triesRemaining = 3 // Track number of tries
    @Published var gameCompleted = false // Track if game is completed
    @Published var correctPairIndices: Set<Int> = [] // Track indices of correct pairs
    @Published private(set) var statistics: GameStatistics = .empty
    @Published var showingCorrectAnswers = false
    @Published var isPuzzleCompletedToday = false
    @Published var savedGameState: SavedGameState?
    private let statisticsKey = "gameStatistics"
    private let gameStateKey = "savedGameState"
    private let lastCompletedDateKey = "lastCompletedDate"
    
    // Dictionary of correct pairings - Order matters (first word -> second word)
    private let correctPairs: [(first: String, second: String)] = [
        ("Second", "Hand"),
        ("Rock", "Star"),
        ("Cold", "Feet"),
        ("Broken", "Heart"),
        ("Silver", "Lining")
    ]
    
    private var lastPlayedDate: Date? {
        get { UserDefaults.standard.object(forKey: "lastPlayedDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastPlayedDate") }
    }
    
    private var lastCompletedDate: Date? {
        get { UserDefaults.standard.object(forKey: lastCompletedDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastCompletedDateKey) }
    }
    
    var canPlayToday: Bool {
        guard let lastPlayed = lastPlayedDate else { return true }
        return !Calendar.current.isDate(lastPlayed, inSameDayAs: Date())
    }
    
    var puzzleCompletedToday: Bool {
        guard let lastCompleted = lastCompletedDate else { return false }
        return Calendar.current.isDate(lastCompleted, inSameDayAs: Date())
    }
    
    var allWordsPlaced: Bool {
        activeWords.compactMap { $0 }.count == 10 // Count non-nil slots
    }
    
    var correctAnswersForDisplay: [(first: String, second: String)] {
        correctPairs
    }
    
    init() {
        // Initialize words with empty array first
        self.words = []
        // Then setup the game
        loadStatistics()
        checkCompletionStatus()
        setupGame()
    }
    
    private func checkCompletionStatus() {
        // Check if today's puzzle was already completed
        if puzzleCompletedToday, let savedState = loadGameState() {
            // Restore saved game state
            isPuzzleCompletedToday = true
            savedGameState = savedState
            resultsMessage = savedState.resultsMessage
            correctPairIndices = savedState.correctPairIndices
            triesRemaining = savedState.triesRemaining
            gameCompleted = true
            
            // If player didn't get all pairs, show the correct answers
            if correctPairIndices.count < 5 {
                showingCorrectAnswers = true
            }
        } else {
            isPuzzleCompletedToday = false
            savedGameState = nil
        }
    }
    
    private func setupGame() {
        if isPuzzleCompletedToday {
            // Load the saved state words
            words = savedGameState?.words ?? []
            activeWords = savedGameState?.activeWords ?? Array(repeating: nil, count: 10)
        } else if (!canPlayToday) {
            // Load saved game state if exists
            words = [
                "Second", "Hand", "Rock", "Star", "Cold",
                "Feet", "Broken", "Heart", "Silver", "Lining"
            ].map { Word(text: $0) }
        } else {
            // Initialize with today's puzzle
            words = [
                "Second", "Hand", "Rock", "Star", "Cold",
                "Feet", "Broken", "Heart", "Silver", "Lining"
            ].map { Word(text: $0) }.shuffled()
            lastPlayedDate = Date()
        }
    }
    
    private func loadStatistics() {
        if let data = UserDefaults.standard.data(forKey: statisticsKey),
           let stats = try? JSONDecoder().decode(GameStatistics.self, from: data) {
            statistics = stats
        }
    }
    
    private func saveStatistics() {
        if let data = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(data, forKey: statisticsKey)
        }
    }
    
    private func updateStatistics() {
        statistics.gamesPlayed += 1
        
        // Calculate mistakes correctly - we need to consider attempts used instead
        // A perfect game means solving in 1 attempt (3-1=2 remaining tries)
        let attemptsUsed = 3 - triesRemaining
        let mistakes = attemptsUsed - 1 // First attempt doesn't count as a mistake
        
        // Update histogram data with correct mistake count
        statistics.mistakeDistribution[mistakes, default: 0] += 1
        
        if correctPairIndices.count == 5 {
            statistics.gamesWon += 1
            statistics.currentStreak += 1
            statistics.maxStreak = max(statistics.currentStreak, statistics.maxStreak)
        } else {
            statistics.currentStreak = 0
        }
        
        saveStatistics()
    }
    
    private func saveCompletedGameState() {
        // Save the current game state when completed
        let state = SavedGameState(
            words: words,
            activeWords: activeWords,
            resultsMessage: resultsMessage,
            correctPairIndices: correctPairIndices,
            triesRemaining: triesRemaining,
            completionDate: Date()
        )
        
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: gameStateKey)
        }
        
        // Mark as completed today
        lastCompletedDate = Date()
        isPuzzleCompletedToday = true
        savedGameState = state
    }
    
    private func loadGameState() -> SavedGameState? {
        guard let data = UserDefaults.standard.data(forKey: gameStateKey),
              let state = try? JSONDecoder().decode(SavedGameState.self, from: data) else {
            return nil
        }
        return state
    }
    
    func addWordToSpecificSlot(_ word: Word, at position: Int) {
        guard position >= 0 && position < 10 else { return }
        
        // If there's already a word in this slot, return it to available words
        if let existingWord = activeWords[position] {
            // Find the word in the original list and mark it as not paired
            if let index = words.firstIndex(where: { $0.id == existingWord.id }) {
                withAnimation {
                    words[index].isPaired = false
                }
            }
        }
        
        // Ensure the word isn't already in active words
        if !activeWords.compactMap({ $0 }).contains(where: { $0.id == word.id }) {
            // Mark the new word as paired in the original list
            if let index = words.firstIndex(where: { $0.id == word.id }) {
                withAnimation {
                    words[index].isPaired = true
                }
            }
            
            // Set the word at the desired position
            withAnimation {
                activeWords[position] = word
            }
        }
    }
    
    func findNextAvailableSlot() -> Int {
        // Find first nil slot
        return activeWords.firstIndex(where: { $0 == nil }) ?? -1
    }
    
    func removeWord(at index: Int) {
        guard index >= 0 && index < 10 else { return }
        
        // Can't remove words that are part of a correct pair
        let pairIndex = index / 2
        if correctPairIndices.contains(pairIndex) {
            return // Don't allow removing words from correct pairs
        }
        
        // Get the word to remove
        guard let wordToRemove = activeWords[index] else { return }
        
        // Mark the word as not paired in the original list
        if let originalIndex = words.firstIndex(where: { $0.id == wordToRemove.id }) {
            words[originalIndex].isPaired = false
        }
        
        // Simply set the slot to nil
        withAnimation {
            activeWords[index] = nil
        }
        
        // Reset submission state if needed
        if hasSubmitted {
            withAnimation {
                hasSubmitted = false
                pairResults.removeAll()
            }
        }
    }
    
    func checkPairs() {
        pairResults.removeAll()
        var newCorrectPairs = Set<Int>()
        
        // Check each pair - fixed stride syntax
        for i in stride(from: 0, through: 8, by: 2) {
            guard let word1 = activeWords[i],
                  let word2 = activeWords[i + 1] else { continue }
            
            let pairIndex = i / 2
            
            // If this pair was already marked correct in a previous attempt, keep it correct
            if correctPairIndices.contains(pairIndex) {
                pairResults.append(true)
                newCorrectPairs.insert(pairIndex)
                continue
            }
            
            // Check if pair is correct
            let isPairCorrect = correctPairs.contains { pair in
                pair.first == word1.text && pair.second == word2.text
            }
            
            pairResults.append(isPairCorrect)
            
            // If correct, add to correctPairIndices
            if isPairCorrect {
                newCorrectPairs.insert(pairIndex)
            }
        }
        
        // Update the correct pair indices
        correctPairIndices = newCorrectPairs
        
        // Mark as submitted
        hasSubmitted = true
        
        // Decrement tries
        triesRemaining -= 1
        
        // Update results message
        let correctCount = correctPairIndices.count
        if triesRemaining > 0 && correctCount < 5 {
            resultsMessage = "You found \(correctCount) correct pairs!\nTries remaining: \(triesRemaining)"
        } else if correctCount == 5 {
            resultsMessage = "Congratulations! You found all pairs!"
            gameCompleted = true
        } else if triesRemaining == 0 {
            resultsMessage = "Game over! You found \(correctCount) out of 5 pairs."
            gameCompleted = true
        }
        
        checkGameCompletion()
        
        if gameCompleted {
            updateStatistics()
        }
    }
    
    private func checkGameCompletion() {
        // Game is complete if all pairs are matched or no tries remaining
        if correctPairIndices.count == 5 || triesRemaining == 0 {
            gameCompleted = true
            
            // Save the completed game state
            saveCompletedGameState()
            
            // If game is lost, show correct answers after a delay
            if triesRemaining == 0 && correctPairIndices.count < 5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        self.showingCorrectAnswers = true
                    }
                }
            }
        } else {
            // Reset submission state after a delay to continue game
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    self.hasSubmitted = false
                    self.pairResults.removeAll()
                }
            }
        }
    }
    
    func generateShareText() -> String {
        let emoji = triesRemaining > 0 ? "🎉" : "😔"
        let score = "\(correctPairIndices.count)/5"
        let attemptsUsed = 3 - triesRemaining
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())
        
        return """
        MashUp \(dateStr) \(emoji)
        Score: \(score)
        Attempts: \(attemptsUsed)/3
        """
    }
    
    func shareResults() {
        let shareText = generateShareText()
        let av = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Find the top-most view controller to present from
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Find the presented view controller (if any)
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            
            // On iPad, we need to set the popover presentation
            if let popover = av.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            topVC.present(av, animated: true)
        }
    }
    
    // Returns if a specific pair is correct (for coloring)
    func isPairCorrect(pairIndex: Int) -> Bool? {
        if correctPairIndices.contains(pairIndex) {
            return true
        }
        guard hasSubmitted, pairIndex < pairResults.count else { return nil }
        return pairResults[pairIndex]
    }
    
    // Check if a word at a specific index is part of a correct pair
    func isWordInCorrectPair(at index: Int) -> Bool {
        let pairIndex = index / 2
        return correctPairIndices.contains(pairIndex)
    }
    
    func swapWords(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0, sourceIndex < 10,
              destinationIndex >= 0, destinationIndex < 10,
              !isWordInCorrectPair(at: sourceIndex),
              !isWordInCorrectPair(at: destinationIndex) else {
            return
        }
        
        withAnimation {
            let temp = activeWords[sourceIndex]
            activeWords[sourceIndex] = activeWords[destinationIndex]
            activeWords[destinationIndex] = temp
        }
        
        // Reset submission state if needed
        if hasSubmitted {
            withAnimation {
                hasSubmitted = false
                pairResults.removeAll()
            }
        }
    }
}

// Model to represent a matched pair
struct MatchedPair: Identifiable {
    let id = UUID()
    let firstWord: Word
    let secondWord: Word
}

// Add a model to store game state
struct SavedGameState: Codable {
    let words: [Word]
    let activeWords: [Word?]
    let resultsMessage: String
    let correctPairIndices: Set<Int>
    let triesRemaining: Int
    let completionDate: Date
    
    enum CodingKeys: String, CodingKey {
        case words, resultsMessage, triesRemaining, completionDate
        case correctPairIndices, activeWords
    }
    
    init(words: [Word], activeWords: [Word?], resultsMessage: String, 
         correctPairIndices: Set<Int>, triesRemaining: Int, completionDate: Date) {
        self.words = words
        self.activeWords = activeWords
        self.resultsMessage = resultsMessage
        self.correctPairIndices = correctPairIndices
        self.triesRemaining = triesRemaining
        self.completionDate = completionDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        words = try container.decode([Word].self, forKey: .words)
        resultsMessage = try container.decode(String.self, forKey: .resultsMessage)
        triesRemaining = try container.decode(Int.self, forKey: .triesRemaining)
        completionDate = try container.decode(Date.self, forKey: .completionDate)
        
        // Decode optional arrays and sets
        let indicesArray = try container.decode([Int].self, forKey: .correctPairIndices)
        correctPairIndices = Set(indicesArray)
        
        // Decode array of optional words
        let activeWordsData = try container.decode([Data?].self, forKey: .activeWords)
        activeWords = activeWordsData.map { data -> Word? in
            guard let data = data,
                  let word = try? JSONDecoder().decode(Word.self, from: data) else {
                return nil
            }
            return word
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(words, forKey: .words)
        try container.encode(resultsMessage, forKey: .resultsMessage)
        try container.encode(triesRemaining, forKey: .triesRemaining)
        try container.encode(completionDate, forKey: .completionDate)
        
        // Encode arrays and sets
        try container.encode(Array(correctPairIndices), forKey: .correctPairIndices)
        
        // Encode array of optional words
        let activeWordsData = activeWords.map { word -> Data? in
            guard let word = word,
                  let data = try? JSONEncoder().encode(word) else {
                return nil
            }
            return data
        }
        try container.encode(activeWordsData, forKey: .activeWords)
    }
}
