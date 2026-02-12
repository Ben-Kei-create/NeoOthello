import Foundation

/// Shared deck (山札). All discs start neutral; colored on draw.
struct Deck {
    private(set) var cards: [DiscData] = []

    var remainingCount: Int { cards.count }
    var isEmpty: Bool { cards.isEmpty }

    /// Build deck with given composition. All discs are neutral.
    mutating func build(normalCount: Int = 40,
                        hackedCount: Int = 8,
                        bombCount: Int = 6) {
        cards.removeAll()
        cards += (0..<normalCount).map { _ in DiscData(type: .normal) }
        cards += (0..<hackedCount).map { _ in DiscData(type: .hacked) }
        cards += (0..<bombCount).map { _ in DiscData(type: .bomb) }
        shuffle()
    }

    mutating func shuffle() {
        cards.shuffle()
    }

    /// Draw the top card and dye it to the player's color.
    mutating func draw(for playerColor: DiscColor) -> DiscData? {
        guard !cards.isEmpty else { return nil }
        var disc = cards.removeFirst()
        disc.color = playerColor
        return disc
    }

    func peek() -> DiscData? {
        cards.first
    }
}
