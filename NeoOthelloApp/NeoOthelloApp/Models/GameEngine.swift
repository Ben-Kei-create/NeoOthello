import Foundation

/// Core game engine: AI evaluation and effect resolution.
/// Used for AI opponent and special disc effects.
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
    static func chooseBestMove(board: Board, color: DiscColor) -> (x: Int, y: Int)? {
        var bestMove: (Int, Int)? = nil
        var bestScore = Int.min

        for x in 0..<8 {
            for y in 0..<8 {
                if board.canPlace(color, at: x, y) {
                    let score = evaluateMove(board: board, x: x, y: y, color: color)
                    if score > bestScore {
                        bestScore = score
                        bestMove = (x, y)
                    }
                }
            }
        }

        return bestMove
    }

    /// For Hacked disc: choose the worst move for the victim.
    static func chooseWorstMoveFor(board: Board, victimColor: DiscColor) -> (x: Int, y: Int)? {
        var worstMove: (Int, Int)? = nil
        var worstScore = Int.max

        for x in 0..<8 {
            for y in 0..<8 {
                if board.canPlace(victimColor, at: x, y) {
                    let score = evaluateMove(board: board, x: x, y: y, color: victimColor)
                    if score < worstScore {
                        worstScore = score
                        worstMove = (x, y)
                    }
                }
            }
        }

        return worstMove
    }

    /// Random move (used when AI is victim of Hacked).
    static func chooseRandomMove(board: Board, color: DiscColor) -> (x: Int, y: Int)? {
        var validMoves: [(Int, Int)] = []
        for x in 0..<8 {
            for y in 0..<8 {
                if board.canPlace(color, at: x, y) {
                    validMoves.append((x, y))
                }
            }
        }
        return validMoves.randomElement()
    }

    /// AI hand disc selection: prefer Normal > Bomb > Hacked.
    static func chooseHandDisc(hand: Hand) -> Int {
        var bestIdx = 0
        var bestPriority = -1

        for i in 0..<hand.discs.count {
            let disc = hand.discs[i]
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

    private static func evaluateMove(board: Board, x: Int, y: Int, color: DiscColor) -> Int {
        // Count how many would be flipped (using a temporary board)
        var tempBoard = board
        let flipped = tempBoard.place(color, at: x, y)
        let flipCount = flipped?.count ?? 0
        let posValue = positionWeights[x][y]
        return posValue * 2 + flipCount
    }

    // MARK: - Effect Resolution

    /// Resolve Bomb effect: destroy adjacent enemy discs. Returns affected positions.
    static func resolveBomb(board: inout Board, x: Int, y: Int,
                            placerColor: DiscColor) -> [(Int, Int)] {
        let enemy = placerColor.opponent
        let directions = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),           (0, 1),
            (1, -1),  (1, 0),  (1, 1)
        ]

        var affected: [(Int, Int)] = []

        for (dx, dy) in directions {
            let nx = x + dx, ny = y + dy
            guard nx >= 0 && nx < 8 && ny >= 0 && ny < 8 else { continue }
            if let disc = board.grid[nx][ny], disc.color == enemy {
                affected.append((nx, ny))
                board.grid[nx][ny] = nil
            }
        }

        return affected
    }
}
