import Foundation
import Combine

/// Main ViewModel bridging game logic and SwiftUI/SceneKit views.
@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published State

    @Published var board: Board = Board()
    @Published var gameMode: GameMode = .classic
    @Published var currentPlayer: DiscColor = .black
    @Published var currentPhase: TurnPhase = .startTurn
    @Published var blackHand: Hand = Hand(ownerColor: .black)
    @Published var whiteHand: Hand = Hand(ownerColor: .white)
    @Published var deck: Deck = Deck()
    @Published var selectedDiscIndex: Int? = nil
    @Published var selectedDisc: Disc? = nil
    @Published var message: String = ""
    @Published var isGameOver: Bool = false
    @Published var winner: DiscColor = .none
    @Published var blackCount: Int = 2
    @Published var whiteCount: Int = 2
    @Published var isWaitingForPlacement: Bool = false
    @Published var isWaitingForHandSelection: Bool = false
    @Published var validMovePositions: [(x: Int, y: Int)] = []
    @Published var lastPlacedPosition: (x: Int, y: Int)? = nil
    @Published var bombAffectedCells: [(Int, Int)] = []
    @Published var hackedForcePosition: (x: Int, y: Int)? = nil
    @Published var limitBreakTriggered: Bool = false
    @Published var showingTitleScreen: Bool = true

    // MARK: - Board Helpers

    private func validMoves(for color: DiscColor) -> [(x: Int, y: Int)] {
        var moves: [(Int, Int)] = []
        for x in 0..<8 {
            for y in 0..<8 {
                if board.canPlace(color, at: x, y) {
                    moves.append((x, y))
                }
            }
        }
        return moves
    }

    private var isGameOverCheck: Bool {
        validMoves(for: .black).isEmpty && validMoves(for: .white).isEmpty
    }

    private func countDiscs() -> (black: Int, white: Int) {
        var b = 0, w = 0
        for x in 0..<8 {
            for y in 0..<8 {
                if let disc = board.grid[x][y] {
                    switch disc.color {
                    case .black: b += 1
                    case .white: w += 1
                    case .none: break
                    }
                }
            }
        }
        return (b, w)
    }

    // MARK: - Init & Start

    func startGame(mode: GameMode) {
        gameMode = mode
        board = Board() // Board() already sets up initial state
        currentPlayer = .black
        isGameOver = false
        winner = .none
        message = ""
        selectedDisc = nil
        selectedDiscIndex = nil
        lastPlacedPosition = nil
        bombAffectedCells = []
        hackedForcePosition = nil
        limitBreakTriggered = false
        showingTitleScreen = false

        blackHand = Hand(ownerColor: .black)
        whiteHand = Hand(ownerColor: .white)
        deck = Deck()

        if mode == .rogue {
            deck.build()
        }

        updateCounts()
        beginTurn()
    }

    // MARK: - Turn Flow

    private func beginTurn() {
        guard !isGameOver else { return }

        let moves = validMoves(for: currentPlayer)
        if moves.isEmpty {
            let opponentMoves = validMoves(for: currentPlayer.opponent)
            if opponentMoves.isEmpty {
                endGame()
                return
            }
            // Skip turn
            message = "\(currentPlayer.displayName) has no valid moves. Turn skipped."
            Task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                switchPlayer()
                beginTurn()
            }
            return
        }

        currentPhase = .startTurn
        message = "\(currentPlayer.displayName)'s turn"

        if gameMode == .rogue {
            drawPhase()
        } else {
            selectedDisc = Disc(color: currentPlayer, type: .normal)
            enterPlacePhase()
        }
    }

    // MARK: - Draw Phase (Rogue)

    private func drawPhase() {
        currentPhase = .draw

        var hand = currentHand
        while !hand.isFull && !deck.isEmpty {
            if let drawn = deck.draw(for: currentPlayer) {
                hand.add(drawn)
            }
        }
        setCurrentHand(hand)

        enterSelectHandPhase()
    }

    // MARK: - Select Hand Phase (Rogue)

    private func enterSelectHandPhase() {
        currentPhase = .selectHand

        let hand = currentHand
        if hand.count == 0 {
            selectedDisc = Disc(color: currentPlayer, type: .normal)
            enterPlacePhase()
            return
        }

        if currentPlayer == .black {
            // Human: wait for tap on hand slot
            isWaitingForHandSelection = true
        } else {
            // AI: auto-select
            let idx = GameEngine.chooseHandDisc(hand: hand)
            aiSelectHandDisc(index: idx)
        }
    }

    /// Called when player taps a hand slot.
    func playerSelectHandDisc(index: Int) {
        guard isWaitingForHandSelection, currentPhase == .selectHand else { return }

        var hand = currentHand
        guard let disc = hand.remove(at: index) else { return }
        setCurrentHand(hand)
        selectedDisc = disc
        selectedDiscIndex = index
        isWaitingForHandSelection = false

        enterPlacePhase()
    }

    private func aiSelectHandDisc(index: Int) {
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            var hand = currentHand
            guard let disc = hand.remove(at: index) else { return }
            setCurrentHand(hand)
            selectedDisc = disc
            selectedDiscIndex = index

            enterPlacePhase()
        }
    }

    // MARK: - Place Phase

    private func enterPlacePhase() {
        currentPhase = .place
        validMovePositions = validMoves(for: currentPlayer)

        let isHacked = selectedDisc?.type == .hacked

        if isHacked {
            handleHackedPlacement()
        } else if currentPlayer == .black {
            isWaitingForPlacement = true
        } else {
            aiPlace()
        }
    }

    /// Called when player taps a board cell.
    func playerPlaceDisc(x: Int, y: Int) {
        guard isWaitingForPlacement, currentPhase == .place else { return }
        guard board.canPlace(currentPlayer, at: x, y) else { return }

        let flipped = board.place(currentPlayer, at: x, y)
        lastPlacedPosition = (x, y)
        isWaitingForPlacement = false
        validMovePositions = []

        updateCounts()

        if gameMode == .rogue {
            checkLimitBreak(flippedCount: flipped?.count ?? 0)
        }

        afterPlacement(x: x, y: y)
    }

    private func aiPlace() {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)

            guard let move = GameEngine.chooseBestMove(board: board, color: currentPlayer) else {
                endTurn()
                return
            }

            let flipped = board.place(currentPlayer, at: move.x, move.y)
            lastPlacedPosition = (move.x, move.y)
            validMovePositions = []
            updateCounts()

            if gameMode == .rogue {
                checkLimitBreak(flippedCount: flipped?.count ?? 0)
            }

            afterPlacement(x: move.x, y: move.y)
        }
    }

    private func handleHackedPlacement() {
        message = "HACKED! Opponent controls placement!"

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)

            let move: (x: Int, y: Int)?

            if currentPlayer == .black {
                move = GameEngine.chooseWorstMoveFor(board: board, victimColor: .black)
            } else {
                move = GameEngine.chooseRandomMove(board: board, color: .white)
            }

            guard let m = move else {
                endTurn()
                return
            }

            let flipped = board.place(currentPlayer, at: m.x, m.y)
            lastPlacedPosition = (m.x, m.y)
            hackedForcePosition = (m.x, m.y)
            validMovePositions = []
            updateCounts()

            message = "Forced placement at (\(m.x), \(m.y))!"

            afterPlacement(x: m.x, y: m.y)
        }
    }

    // MARK: - Effect Phase

    private func afterPlacement(x: Int, y: Int) {
        if gameMode == .rogue, let disc = selectedDisc, disc.type == .bomb {
            effectPhase(x: x, y: y)
        } else {
            endTurn()
        }
    }

    private func effectPhase(x: Int, y: Int) {
        currentPhase = .effect

        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)

            let affected = GameEngine.resolveBomb(board: &board, x: x, y: y,
                                                  placerColor: currentPlayer)
            if !affected.isEmpty {
                bombAffectedCells = affected
                message = "BOMB! Destroyed \(affected.count) enemy disc(s)!"
                updateCounts()
            }

            try? await Task.sleep(nanoseconds: 500_000_000)
            bombAffectedCells = []

            endTurn()
        }
    }

    // MARK: - Limit Break

    private func checkLimitBreak(flippedCount: Int) {
        var hand = currentHand
        if hand.checkLimitBreak(flippedCount: flippedCount) {
            if hand.tryExpandCapacity() {
                limitBreakTriggered = true
                message = "LIMIT BREAK! Hand capacity → \(hand.capacity)!"

                // Bonus draw
                if !deck.isEmpty {
                    if let bonus = deck.draw(for: currentPlayer) {
                        hand.add(bonus)
                    }
                }

                setCurrentHand(hand)

                // Reset after a delay
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    limitBreakTriggered = false
                }
            }
        }
    }

    // MARK: - End Turn

    private func endTurn() {
        currentPhase = .endTurn
        selectedDisc = nil
        selectedDiscIndex = nil
        hackedForcePosition = nil

        if isGameOverCheck || (gameMode == .rogue && deck.isEmpty
            && blackHand.count == 0 && whiteHand.count == 0
            && validMoves(for: currentPlayer.opponent).isEmpty) {
            endGame()
            return
        }

        switchPlayer()

        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            beginTurn()
        }
    }

    // MARK: - Game Over

    private func endGame() {
        isGameOver = true
        let counts = countDiscs()
        blackCount = counts.black
        whiteCount = counts.white

        if counts.black > counts.white {
            winner = .black
            message = "You Win! Black \(counts.black) - White \(counts.white)"
        } else if counts.white > counts.black {
            winner = .white
            message = "AI Wins! Black \(counts.black) - White \(counts.white)"
        } else {
            winner = .none
            message = "Draw! Black \(counts.black) - White \(counts.white)"
        }
    }

    // MARK: - Helpers

    private var currentHand: Hand {
        currentPlayer == .black ? blackHand : whiteHand
    }

    private func setCurrentHand(_ hand: Hand) {
        if currentPlayer == .black {
            blackHand = hand
        } else {
            whiteHand = hand
        }
    }

    private func switchPlayer() {
        currentPlayer = currentPlayer.opponent
    }

    private func updateCounts() {
        let counts = countDiscs()
        blackCount = counts.black
        whiteCount = counts.white
    }

    func returnToTitle() {
        showingTitleScreen = true
        isGameOver = false
    }
}
