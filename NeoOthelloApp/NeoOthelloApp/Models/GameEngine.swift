import Foundation

/// Core game engine: AI evaluation, turn progression, effect resolution.
struct GameEngine {

    // MARK: - AI Positional Weights

    private static let positionWeights: [[Int]] = [
        [ 100, -20,  10,   5,   5,  10, -20, 100],
        [ -20, -50,  -2,  -2,  -2,  -2, -50, -20],
        [  10,  -2,   1,   1,   1,   1,  -2,  10],
        [   5,  -2,   1,   0,   0,   1,  -2,   5],
        [   5,  -2,   1,   0,   0,   1,  -2,   5],
        [  10,  -2,   1,   1,   1,   1,  -2,  10],
        [ -20, -50,  -2,  -2,  -2,  -2, -50, -20],
        [ 100, -20,  10,   5,   5,  10, -20, 100]
    ]

    // MARK: - AI Move Selection

    /// Choose the best move for AI (positional weight + flip count).
    static func chooseBestMove(board: Board, color: DiscColor) -> (row: Int, col: Int)? {
        let moves = board.validMoves(for: color)
        guard !moves.isEmpty else { return nil }

        var bestMove = moves[0]
        var bestScore = Int.min

        for move in moves {
            let score = evaluateMove(board: board, row: move.row, col: move.col, color: color)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }

        return bestMove
    }

    /// For Hacked disc: choose the worst move for the victim.
    static func chooseWorstMoveFor(board: Board, victimColor: DiscColor) -> (row: Int, col: Int)? {
        let moves = board.validMoves(for: victimColor)
        guard !moves.isEmpty else { return nil }

        var worstMove = moves[0]
        var worstScore = Int.max

        for move in moves {
            let score = evaluateMove(board: board, row: move.row, col: move.col, color: victimColor)
            if score < worstScore {
                worstScore = score
                worstMove = move
            }
        }

        return worstMove
    }

    /// Random move (used when AI is victim of Hacked).
    static func chooseRandomMove(board: Board, color: DiscColor) -> (row: Int, col: Int)? {
        let moves = board.validMoves(for: color)
        return moves.isEmpty ? nil : moves.randomElement()
    }

    /// AI hand disc selection: prefer Normal > Bomb > Hacked.
    static func chooseHandDisc(hand: Hand) -> Int {
        var bestIdx = 0
        var bestPriority = -1

        for i in 0..<hand.count {
            guard let disc = hand.disc(at: i) else { continue }
            let priority: Int
            switch disc.type {
            case .normal: priority = 10
            case .bomb:   priority = 5
            case .hacked: priority = 1
            }
            if priority > bestPriority {
                bestPriority = priority
                bestIdx = i
            }
        }

        return bestIdx
    }

    private static func evaluateMove(board: Board, row: Int, col: Int, color: DiscColor) -> Int {
        let flipCount = board.flippableCells(row: row, col: col, color: color).count
        let posValue = positionWeights[row][col]
        return posValue * 2 + flipCount
    }

    // MARK: - Effect Resolution

    /// Resolve Bomb effect: destroy adjacent enemy discs. Returns affected positions.
    static func resolveBomb(board: inout Board, row: Int, col: Int,
                            placerColor: DiscColor) -> [(Int, Int)] {
        let enemy = placerColor.opponent
        let adjacent = board.adjacentCells(row: row, col: col)
        var affected: [(Int, Int)] = []

        for (r, c) in adjacent {
            if board.cells[r][c].color == enemy {
                affected.append((r, c))
                board.destroyCell(row: r, col: c)
            }
        }

        return affected
    }
}
