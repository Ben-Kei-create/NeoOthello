import Foundation

struct Hand {
    var discs: [Disc] = []
    var capacity: Int = 3 // 初期上限は3枚

    // 補充が必要か？
    var needsRefill: Bool {
        return discs.count < capacity
    }

    // デッキから満タンになるまで補充
    mutating func refill(from deck: inout Deck, owner: DiscColor) {
        while discs.count < capacity {
            if let newDisc = deck.draw(for: owner) {
                discs.append(newDisc)
            } else {
                break // デッキ切れ
            }
        }
    }

    // 石を使う（選択したインデックスの石を消費して返す）
    mutating func useDisc(at index: Int) -> Disc? {
        guard index >= 0 && index < discs.count else { return nil }
        return discs.remove(at: index)
    }

    // 限界突破（6枚返しなどで枠が増える機能用）
    mutating func limitBreak() {
        if capacity < 5 { // 最大5枚まで
            capacity += 1
        }
    }
}
