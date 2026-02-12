import Foundation

/// Pure 8x8 Othello board logic. No UI dependencies.
struct Board {
    static let size = 8

    private static let directions: [(dr: Int, dc: Int)] = [
        (-1, -1), (-1, 0), (-1, 1),
        ( 0, -1),          ( 0, 1),
        ( 1, -1), ( 1, 0), ( 1, 1)
    ]

    private(set) var cells: [[BoardCell]]

    init() {
        cells = (0..<Board.size).map { r in
            (0..<Board.size).map { c in BoardCell(row: r, col: c) }
        }
    }

    // MARK: - Setup

    mutating func initStandardBoard() {
        clearBoard()
        cells[3][3].place(color: .white)
        cells[3][4].place(color: .black)
        cells[4][3].place(color: .black)
        cells[4][4].place(color: .white)
    }

    mutating func clearBoard() {
        for r in 0..<Board.size {
            for c in 0..<Board.size {
                cells[r][c].clear()
            }
        }
    }

    // MARK: - Queries

    func inBounds(_ row: Int, _ col: Int) -> Bool {
        row >= 0 && row < Board.size && col >= 0 && col < Board.size
    }

    func cell(at row: Int, _ col: Int) -> BoardCell? {
        guard inBounds(row, col) else { return nil }
        return cells[row][col]
    }

    /// Returns positions that would be flipped if `color` places at (row, col).
    func flippableCells(row: Int, col: Int, color: DiscColor) -> [(Int, Int)] {
        guard inBounds(row, col), cells[row][col].isEmpty else { return [] }

        let opponent = color.opponent
        var result: [(Int, Int)] = []

        for dir in Board.directions {
            var line: [(Int, Int)] = []
            var r = row + dir.dr
            var c = col + dir.dc

            while inBounds(r, c) && cells[r][c].color == opponent {
                line.append((r, c))
                r += dir.dr
                c += dir.dc
            }

            if !line.isEmpty && inBounds(r, c) && cells[r][c].color == color {
                result.append(contentsOf: line)
            }
        }

        return result
    }

    func isValidMove(row: Int, col: Int, color: DiscColor) -> Bool {
        !flippableCells(row: row, col: col, color: color).isEmpty
    }

    func validMoves(for color: DiscColor) -> [(row: Int, col: Int)] {
        var moves: [(Int, Int)] = []
        for r in 0..<Board.size {
            for c in 0..<Board.size {
                if isValidMove(row: r, col: c, color: color) {
                    moves.append((r, c))
                }
            }
        }
        return moves
    }

    var isGameOver: Bool {
        validMoves(for: .black).isEmpty && validMoves(for: .white).isEmpty
    }

    func countDiscs() -> (black: Int, white: Int) {
        var b = 0, w = 0
        for r in 0..<Board.size {
            for c in 0..<Board.size {
                switch cells[r][c].color {
                case .black: b += 1
                case .white: w += 1
                case .none: break
                }
            }
        }
        return (b, w)
    }

    func adjacentCells(row: Int, col: Int) -> [(Int, Int)] {
        Board.directions.compactMap { dir in
            let r = row + dir.dr, c = col + dir.dc
            return inBounds(r, c) ? (r, c) : nil
        }
    }

    // MARK: - Mutations

    /// Place a disc and flip captured pieces. Returns flipped count.
    @discardableResult
    mutating func placeDisc(row: Int, col: Int, color: DiscColor,
                            type: DiscType = .normal) -> Int {
        let flippable = flippableCells(row: row, col: col, color: color)
        guard !flippable.isEmpty else { return 0 }

        cells[row][col].place(color: color, type: type)

        for (r, c) in flippable {
            cells[r][c].flip()
        }

        return flippable.count
    }

    mutating func destroyCell(row: Int, col: Int) {
        guard inBounds(row, col) else { return }
        cells[row][col].clear()
    }
}
