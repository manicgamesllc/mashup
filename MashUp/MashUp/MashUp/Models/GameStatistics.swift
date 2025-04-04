import Foundation

struct GameStatistics: Codable {
    var gamesPlayed: Int
    var gamesWon: Int
    var currentStreak: Int
    var maxStreak: Int
    var mistakeDistribution: [Int: Int]
    
    static var empty: GameStatistics {
        GameStatistics(
            gamesPlayed: 0,
            gamesWon: 0,
            currentStreak: 0,
            maxStreak: 0,
            mistakeDistribution: [0: 0, 1: 0, 2: 0, 3: 0]  // Initialize with all mistake counts (0-3)
        )
    }
    
    var winPercentage: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100
    }
}
