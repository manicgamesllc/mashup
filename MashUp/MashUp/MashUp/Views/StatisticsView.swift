import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Statistics Grid
                StatisticsGridView(statistics: viewModel.statistics)
                
                // Perfect Games
                PerfectGamesView(statistics: viewModel.statistics)
                
                // Chart Section
                AttemptsChartView(statistics: viewModel.statistics)
                
                Spacer()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Separated Grid View Component
struct StatisticsGridView: View {
    let statistics: GameStatistics
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            StatBox(title: "Played", value: "\(statistics.gamesPlayed)")
            StatBox(title: "Win %", value: String(format: "%.0f", statistics.winPercentage))
            StatBox(title: "Streak", value: "\(statistics.currentStreak)")
            StatBox(title: "Max", value: "\(statistics.maxStreak)")
        }
        .padding()
    }
}

// Perfect Games View
struct PerfectGamesView: View {
    let statistics: GameStatistics
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Perfect Games")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primary(for: colorScheme))
            }
            
            Spacer()
            
            Text("\(statistics.mistakeDistribution[0] ?? 0)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(ColorTheme.primary(for: colorScheme))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorTheme.cardBackground(for: colorScheme))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// Separated Chart View Component
struct AttemptsChartView: View {
    let statistics: GameStatistics
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Mistake Distribution")
                .font(.headline)
                .padding(.leading)
            
            if statistics.gamesPlayed == 0 {
                Text("Play your first game to see statistics!")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(height: 200)
            } else {
                attemptsChart
            }
        }
    }
    
    private var attemptsChart: some View {
        Chart {
            ForEach([0, 1, 2, 3], id: \.self) { mistakeCount in
                let count = statistics.mistakeDistribution[mistakeCount] ?? 0
                
                BarMark(
                    x: .value("Mistakes", "\(mistakeCount)"),
                    y: .value("Games", count)
                )
                .cornerRadius(6)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [ColorTheme.primary(for: colorScheme), ColorTheme.primary(for: colorScheme).opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(radius: 2, y: 1)
                .annotation(position: .top, alignment: .center, spacing: 6) {
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ColorTheme.primary(for: colorScheme))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks {
                // Hide Y axis
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(Color.gray)
                    .font(.footnote)
            }
        }
        .frame(height: 200)
        .padding()
    }
}

struct StatBox: View {
    let title: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ColorTheme.primary(for: colorScheme))
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}
