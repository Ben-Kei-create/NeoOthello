import SwiftUI
import SceneKit

struct ContentView: View {
    // 3Dシーンの実体を保持（Viewが再描画されても消えないように）
    // ※ 本来はViewModelに持たせますが、まずはテスト動作なのでここでOK
    @State private var scene = GameScene()

    var body: some View {
        ZStack {
            // 背景色（宇宙っぽい黒）
            Color.black.edgesIgnoringSafeArea(.all)

            // 3Dレイヤー
            SceneKitContainer(scene: scene) { nodeName in
                handleTap(nodeName: nodeName)
            }
            .edgesIgnoringSafeArea(.all)

            // UIレイヤー（デバッグ用）
            VStack {
                Text("Neo Othello Prototype")
                    .font(.headline)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .foregroundColor(.white)
                Spacer()
                Text("Tap any cell to place a disc")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
        }
    }

    // タップ処理のロジック
    private func handleTap(nodeName: String) {
        // "cell_3_4" 形式の文字列を分解
        let components = nodeName.split(separator: "_")

        // 安全に Int に変換できた場合のみ実行
        if components.count == 3,
           let x = Int(components[1]),
           let y = Int(components[2]) {

            print("Tapped Node: \(nodeName) -> (\(x), \(y))")

            // UIスレッドで描画更新（アニメーション実行）
            // テストとして、交互に色を変えたりせず「黒」を落とす
            Task { @MainActor in
                scene.placeDisc(at: x, y, color: .black)

                // 振動フィードバック（触覚）を入れると気持ちいい
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
}

#Preview {
    ContentView()
}
