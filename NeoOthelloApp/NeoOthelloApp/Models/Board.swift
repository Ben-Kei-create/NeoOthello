import Foundation

struct Board {
    // 8x8の盤面データ（nilなら空き、入っていれば石）
    var grid: [[Disc?]]

    init() {
        // 8x8を空で初期化
        grid = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        setupInitialState()
    }

    // 初期配置（オセロの公式ルール）
    private mutating func setupInitialState() {
        grid[3][3] = Disc(color: .white)
        grid[4][4] = Disc(color: .white)
        grid[3][4] = Disc(color: .black)
        grid[4][3] = Disc(color: .black)
    }

    // 石を置く（成功したらひっくり返した座標リストを返す、失敗ならnil）
    mutating func place(_ color: DiscColor, at x: Int, _ y: Int) -> [(Int, Int)]? {
        // 既に石がある、または範囲外ならNG
        guard isValidCoordinate(x, y), grid[x][y] == nil else { return nil }

        let flipped = getFlippableDiscs(color, at: x, y)

        // 1枚もひっくり返せなければ置けない（オセロのルール）
        if flipped.isEmpty { return nil }

        // 石を置く
        grid[x][y] = Disc(color: color)

        // ひっくり返す処理
        for (fx, fy) in flipped {
            grid[fx][fy]?.color = color
        }

        return flipped
    }

    // 置ける場所かどうかチェック（ハイライト用）
    func canPlace(_ color: DiscColor, at x: Int, _ y: Int) -> Bool {
        guard isValidCoordinate(x, y), grid[x][y] == nil else { return false }
        return !getFlippableDiscs(color, at: x, y).isEmpty
    }

    // ひっくり返せる石の座標リストを取得
    private func getFlippableDiscs(_ color: DiscColor, at x: Int, _ y: Int) -> [(Int, Int)] {
        var flippable: [(Int, Int)] = []
        let directions = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),           (0, 1),
            (1, -1),  (1, 0),  (1, 1)
        ]

        for (dx, dy) in directions {
            var tempFlippable: [(Int, Int)] = []
            var cx = x + dx
            var cy = y + dy

            // その方向をスキャン
            while isValidCoordinate(cx, cy) {
                guard let disc = grid[cx][cy] else { break } // 空きマスなら終了

                if disc.color == color.opponent {
                    // 相手の石なら候補に追加して次へ
                    tempFlippable.append((cx, cy))
                } else if disc.color == color {
                    // 自分の石で挟めたら、候補を確定リストに追加
                    flippable.append(contentsOf: tempFlippable)
                    break
                }

                cx += dx
                cy += dy
            }
        }
        return flippable
    }

    private func isValidCoordinate(_ x: Int, _ y: Int) -> Bool {
        return x >= 0 && x < 8 && y >= 0 && y < 8
    }
}
