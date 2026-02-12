import SwiftUI

/// Root view: switches between TitleScreen and Game view.
struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var gameScene = GameScene()

    var body: some View {
        ZStack {
            if viewModel.showingTitleScreen {
                TitleScreenView(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                gameView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showingTitleScreen)
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }

    private var gameView: some View {
        ZStack {
            // 3D board (SceneKit)
            SceneKitContainer(scene: gameScene) { nodeName in
                // ノード名 "cell_3_4" をパースして配置処理へ
                if let cell = GameScene.parseCellName(nodeName) {
                    viewModel.playerPlaceDisc(row: cell.row, col: cell.col)
                }
            }
            .ignoresSafeArea()

            // 2D overlay (SwiftUI)
            GameOverlayView(viewModel: viewModel)

            // Game over panel
            GameOverOverlay(viewModel: viewModel)
        }
        .onChange(of: viewModel.board.cells.flatMap { $0.map { $0.color } }) {
            gameScene.updateBoard(viewModel.board)
        }
        .onChange(of: viewModel.validMovePositions.map { "\($0.row)_\($0.col)" }) {
            gameScene.updateHighlights(viewModel.validMovePositions)
        }
        .onChange(of: viewModel.bombAffectedCells.map { "\($0.0)_\($0.1)" }) {
            if !viewModel.bombAffectedCells.isEmpty {
                gameScene.animateBombEffect(positions: viewModel.bombAffectedCells)
            }
        }
        .onAppear {
            gameScene.updateBoard(viewModel.board)
        }
    }
}
