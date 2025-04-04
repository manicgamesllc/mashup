import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct Word: Identifiable, Hashable, Codable, Transferable {
    var id: UUID
    var text: String
    var isPaired: Bool
    
    init(id: UUID = UUID(), text: String, isPaired: Bool = false) {
        self.id = id
        self.text = text
        self.isPaired = isPaired
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: Word.self, contentType: .data)
    }
}

struct WordPair: Identifiable {
    var id = UUID()
    var word1: Word
    var word2: Word
    
    var combinedText: String {
        return word1.text + word2.text
    }
}