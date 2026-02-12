import SwiftUI
import SceneKit

// @MainActor: UI更新をメインスレッドでやる保証
@MainActor
class GameViewModel: ObservableObject {
    // --- モデル ---
    @Published var board = Board()
    @Published var currentTurn: DiscColor = .black

    // --- ローグライク要素 ---
    @Published var deck = Deck()
    @Published var playerHand = Hand()
    @Published var enemyHand = Hand() // AI用（データとしては持っておく）

    // --- 状態管理 ---
    @Published var selectedDiscIndex: Int? = nil // 手牌のどれを選んでる？(0~4)
    @Published var message: String = "Select a disc..."
    @Published var isGameOver: Bool = false
    @Published var winner: DiscColor = .none
    @Published var blackCount: Int = 2
    @Published var whiteCount: Int = 2

    // 3Dシーン（Viewから参照させる）
    let scene = GameScene()

    init() {
        startNewGame()
    }

    func startNewGame() {
        board = Board()
        deck = Deck()
        playerHand = Hand()
        enemyHand = Hand()
        currentTurn = .black
        selectedDiscIndex = nil
        isGameOver = false
        winner = .none

        // 初期手札を配る
        playerHand.refill(from: &deck, owner: .black)
        enemyHand.refill(from: &deck, owner: .white)

        // 3D盤面リセット
        renderBoard()
        updateCounts()
        message = "Select a disc from your hand"
    }

    // 手牌を選択したときの処理
    func selectDisc(at index: Int) {
        // 自分の番じゃないと選べない
        guard currentTurn == .black else { return }
        guard index >= 0 && index < playerHand.discs.count else { return }

        selectedDiscIndex = index
        let disc = playerHand.discs[index]

        // 石の種類によってメッセージを変える
        switch disc.type {
        case .normal: message = "Normal Disc selected"
        case .bomb:   message = "BOMB! Destroys surroundings"
        case .hacked: message = "HACKED... AI controls this move"
        }

        // 選択フィードバック
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // 盤面をタップしたときの処理
    func handleBoardTap(x: Int, y: Int) {
        // 1. 自分のターンか？
        guard currentTurn == .black else { return }

        // 2. 手牌を選んでいるか？
        guard let index = selectedDiscIndex, index < playerHand.discs.count else {
            message = "Select a disc first!"
            notifyError()
            return
        }

        // 3. 置ける場所か？
        guard board.canPlace(currentTurn, at: x, y) else {
            message = "Invalid Move!"
            notifyError()
            return
        }

        // --- 実行フェーズ ---

        // 手牌から石を消費
        guard let _ = playerHand.useDisc(at: index) else { return }
        selectedDiscIndex = nil // 選択解除

        executeMove(color: currentTurn, x: x, y: y)
    }

    // 石を置いてひっくり返す共通処理
    private func executeMove(color: DiscColor, x: Int, y: Int) {
        if let flipped = board.place(color, at: x, y) {

            // 3D更新（置く）
            scene.placeDisc(at: x, y, color: color.uiColor)
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            // ひっくり返す演出（非同期）
            Task {
                try? await Task.sleep(nanoseconds: 150_000_000) // 0.15秒待つ
                for (fx, fy) in flipped {
                    scene.flipDisc(at: fx, fy, to: color.uiColor)
                }

                // スコア更新
                updateCounts()

                // ターン終了処理へ
                endTurn()
            }
        }
    }

    private func endTurn() {
        // ゲーム終了チェック
        let blackMoves = hasValidMoves(for: .black)
        let whiteMoves = hasValidMoves(for: .white)

        if !blackMoves && !whiteMoves {
            finishGame()
            return
        }

        currentTurn = currentTurn.opponent

        if currentTurn == .white {
            message = "AI Thinking..."
            // --- AIターン ---
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒考えるフリ

                // 敵も手札補充
                enemyHand.refill(from: &deck, owner: .white)

                // 合法手チェック
                if !hasValidMoves(for: .white) {
                    // 置く場所がない（パス）
                    currentTurn = .black
                    playerHand.refill(from: &deck, owner: .black)
                    message = "AI Passed. Your Turn."
                    return
                }

                // ランダムに置ける場所を探して置く（仮AI）
                var validMoves: [(Int, Int)] = []
                for x in 0..<8 {
                    for y in 0..<8 {
                        if board.canPlace(.white, at: x, y) {
                            validMoves.append((x, y))
                        }
                    }
                }

                if let move = validMoves.randomElement() {
                    // AI手牌を消費（中身は問わない）
                    let _ = enemyHand.useDisc(at: 0)
                    executeMove(color: .white, x: move.0, y: move.1)
                }
            }
        } else {
            // プレイヤーのターンに戻ってきた
            if !hasValidMoves(for: .black) {
                // プレイヤーもパス
                message = "No valid moves. Turn skipped."
                Task {
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    endTurn()
                }
                return
            }
            playerHand.refill(from: &deck, owner: .black) // 手札補充
            message = "Your Turn. Select a disc."
        }
    }

    private func finishGame() {
        isGameOver = true
        updateCounts()

        if blackCount > whiteCount {
            winner = .black
            message = "You Win! Black \(blackCount) - White \(whiteCount)"
        } else if whiteCount > blackCount {
            winner = .white
            message = "AI Wins! Black \(blackCount) - White \(whiteCount)"
        } else {
            winner = .none
            message = "Draw! Black \(blackCount) - White \(whiteCount)"
        }
    }

    // 3D盤面再描画（リセット用）
    func renderBoard() {
        scene.resetBoard()
        // 初期配置を描画
        for x in 0..<8 {
            for y in 0..<8 {
                if let disc = board.grid[x][y] {
                    scene.placeDisc(at: x, y, color: disc.color.uiColor)
                }
            }
        }
    }

    // MARK: - Helpers

    private func hasValidMoves(for color: DiscColor) -> Bool {
        for x in 0..<8 {
            for y in 0..<8 {
                if board.canPlace(color, at: x, y) { return true }
            }
        }
        return false
    }

    private func updateCounts() {
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
        blackCount = b
        whiteCount = w
    }

    private func notifyError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
