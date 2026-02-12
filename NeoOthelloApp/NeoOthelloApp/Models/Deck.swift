import Foundation

/// Shared deck (山札). All discs start neutral; colored on draw.
/// Used in Rogue mode only.
struct Deck {
    private(set) var cards: [Disc] = []

    var remainingCount: Int { cards.count }
    var isEmpty: Bool { cards.isEmpty }

    /// Build deck with given composition. All discs are neutral.
    mutating func build(normalCount: Int = 40,
                        hackedCount: Int = 8,
                        bombCount: Int = 6) {
        cards.removeAll()
        cards += (0..<normalCount).map { _ in Disc(color: .none, type: .normal) }
        cards += (0..<hackedCount).map { _ in Disc(color: .none, type: .hacked) }
        cards += (0..<bombCount).map { _ in Disc(color: .none, type: .bomb) }
        shuffle()
    }

    mutating func shuffle() {
        cards.shuffle()
    }

    /// Draw the top card and dye it to the player's color.
    mutating func draw(for playerColor: DiscColor) -> Disc? {
        guard !cards.isEmpty else { return nil }
        var disc = cards.removeFirst()
        disc.color = playerColor
        return disc
    }

    func peek() -> Disc? {
        cards.first
    }
}
