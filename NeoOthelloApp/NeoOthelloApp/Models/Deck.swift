import Foundation

struct Deck {
    private var drawPile: [DiscType] = []

    // 初期化：デッキレシピでシャッフル
    init() {
        reset()
    }

    mutating func reset() {
        drawPile = []

        // --- デッキレシピ ---
        // 通常石: 20枚
        for _ in 0..<20 { drawPile.append(.normal) }
        // ボム: 5枚
        for _ in 0..<5 { drawPile.append(.bomb) }
        // ハッキング: 5枚
        for _ in 0..<5 { drawPile.append(.hacked) }

        drawPile.shuffle()
    }

    // ドロー機能
    // 引く人の色(owner)を指定することで、その石が「誰のものか」確定する
    mutating func draw(for owner: DiscColor) -> Disc? {
        guard !drawPile.isEmpty else { return nil } // 山札切れ

        let type = drawPile.removeFirst()
        // ここで「無色」だった石に「色」がつきます！
        return Disc(color: owner, type: type)
    }

    // 残り枚数（UI表示用）
    var count: Int {
        return drawPile.count
    }
}
