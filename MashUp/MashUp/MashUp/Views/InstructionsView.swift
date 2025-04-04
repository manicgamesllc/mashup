import SwiftUI

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("How to Play")
                        .font(.title.bold())
                    
                    // Instructions section
                    VStack(alignment: .leading, spacing: 16) {
                        instructionRow(number: "1", text: "Drag and drop words to form pairs")
                        instructionRow(number: "2", text: "Words must be placed in the correct order")
                        instructionRow(number: "3", text: "You have 3 attempts to find all pairs")
                        instructionRow(number: "4", text: "Correct pairs will stay locked")
                        instructionRow(number: "5", text: "New puzzle every day at midnight")
                    }
                    .padding(.vertical)
                    
                    // Example section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Example")
                            .font(.title3.bold())
                        
                        // Example card
                        VStack(spacing: 20) {
                            // Example word pair
                            HStack(spacing: 12) {
                                exampleWordCard(text: "COLD")
                                Image(systemName: "plus")
                                    .foregroundColor(.gray)
                                exampleWordCard(text: "FEET")
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.gray)
                                exampleCompoundWord(text: "Cold Feet")
                            }
                            
                            // Explanation text
                            Text("Combine 'COLD' + 'FEET' to make 'COLD FEET'")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips")
                            .font(.title3.bold())
                            .padding(.top)
                        
                        tipRow(icon: "arrow.2.squarepath", text: "Tap a word to return it to the word bank")
                        tipRow(icon: "checkmark.circle", text: "Correctly matched pairs will lock in place")
                        tipRow(icon: "clock", text: "Take your time - there's no time limit!")
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number)
                .font(.headline)
                .foregroundColor(ColorTheme.primary(for: colorScheme))
                .frame(width: 25, height: 25)
                .background(Circle().stroke(ColorTheme.primary(for: colorScheme), lineWidth: 2))
            
            Text(text)
                .font(.body)
                .foregroundColor(ColorTheme.primary(for: colorScheme))
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ColorTheme.primary(for: colorScheme))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(ColorTheme.primary(for: colorScheme))
        }
    }
    
    private func exampleWordCard(text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(ColorTheme.secondary(for: colorScheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(ColorTheme.primary(for: colorScheme))
            )
    }
    
    private func exampleCompoundWord(text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(ColorTheme.primary(for: colorScheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .stroke(ColorTheme.primary(for: colorScheme), lineWidth: 2)
            )
    }
}
