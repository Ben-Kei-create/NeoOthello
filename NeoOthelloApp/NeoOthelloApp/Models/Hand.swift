import Foundation

/// Manages a player's hand with dynamic capacity (Limit Break).
struct Hand {
    static let initialCapacity = 3
    static let maxCapacity = 5
    static let limitBreakThreshold = 6

    private(set) var discs: [DiscData] = []
    private(set) var capacity: Int = Hand.initialCapacity
    let ownerColor: DiscColor

    init(ownerColor: DiscColor) {
        self.ownerColor = ownerColor
    }

    var count: Int { discs.count }
    var isFull: Bool { discs.count >= capacity }
    var slotsAvailable: Int { capacity - discs.count }

    mutating func add(_ disc: DiscData) {
        guard discs.count < capacity else { return }
        discs.append(disc)
    }

    @discardableResult
    mutating func remove(at index: Int) -> DiscData? {
        guard index >= 0 && index < discs.count else { return nil }
        return discs.remove(at: index)
    }

    func disc(at index: Int) -> DiscData? {
        guard index >= 0 && index < discs.count else { return nil }
        return discs[index]
    }

    /// Attempt to expand capacity. Returns true if expanded.
    @discardableResult
    mutating func tryExpandCapacity() -> Bool {
        guard capacity < Hand.maxCapacity else { return false }
        capacity += 1
        return true
    }

    func checkLimitBreak(flippedCount: Int) -> Bool {
        flippedCount >= Hand.limitBreakThreshold
    }

    mutating func clear() {
        discs.removeAll()
        capacity = Hand.initialCapacity
    }
}
