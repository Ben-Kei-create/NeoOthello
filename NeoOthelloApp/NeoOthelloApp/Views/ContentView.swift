import SwiftUI
import SceneKit

struct ContentView: View {
    // 3Dシーンを保持（再生成を防ぐためStateObjectか定数で）
    let scene = GameScene()

    var body: some View {
        ZStack {
            // 3Dレイヤー
            SceneKitContainer(scene: scene) { nodeName in
                // タップされたノード名を受け取る
                print("Tapped Node: \(nodeName)")

                // 簡易テスト：タップした場所に黒い石を落としてみる
                // "cell_3_4" -> [3, 4]
                let components = nodeName.split(separator: "_")
                if components.count == 3,
                   let x = Int(components[1]),
                   let y = Int(components[2]) {

                    // UIスレッドで描画更新
                    Task { @MainActor in
                        scene.placeDisc(at: x, y, color: .black)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)

            // UIレイヤー（仮）
            VStack {
                Text("Neo Othello Prototype")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(.black.opacity(0.5))
                    .cornerRadius(10)
                Spacer()
            }
        }
    }
}
