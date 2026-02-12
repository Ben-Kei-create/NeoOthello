import SwiftUI
import SceneKit

struct ContentView: View {
    // ViewModelをここで所有する
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            // 背景
            Color.black.edgesIgnoringSafeArea(.all)

            // 3Dシーン層
            SceneKitContainer(scene: viewModel.scene) { nodeName in
                // タップ処理をViewModelに丸投げ
                let components = nodeName.split(separator: "_")
                if components.count == 3,
                   let x = Int(components[1]),
                   let y = Int(components[2]) {
                    viewModel.handleBoardTap(x: x, y: y)
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                // 初回描画
                viewModel.renderBoard()
            }

            // UI層（手牌・スコア・メッセージ）
            GameOverlayView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView()
}
