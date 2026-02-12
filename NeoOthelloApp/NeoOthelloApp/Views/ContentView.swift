import SwiftUI
import SceneKit

struct ContentView: View {
    @State private var scene = GameScene()

    // ゲームの状態管理
    @State private var board = Board()
    @State private var currentTurn: DiscColor = .black

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            SceneKitContainer(scene: scene) { nodeName in
                handleTap(nodeName: nodeName)
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                // アプリ起動時に初期配置を描画
                renderInitialBoard()
            }

            VStack {
                // ターン表示
                HStack {
                    Circle()
                        .fill(currentTurn == .black ? Color.white : Color.clear)
                        .frame(width: 10, height: 10)
                    Text(currentTurn == .black ? "Black's Turn" : "White's Turn")
                        .font(.title2)
                        .bold()
                        .foregroundColor(currentTurn == .black ? .white : .gray)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.top, 50)

                Spacer()
            }
        }
    }

    private func renderInitialBoard() {
        // Boardモデルの初期状態を見て、3Dシーンに石を置く
        scene.resetBoard()
        for x in 0..<8 {
            for y in 0..<8 {
                if let disc = board.grid[x][y] {
                    scene.placeDisc(at: x, y, color: disc.color.uiColor)
                }
            }
        }
    }

    private func handleTap(nodeName: String) {
        let components = nodeName.split(separator: "_")
        guard components.count == 3,
              let x = Int(components[1]),
              let y = Int(components[2]) else { return }

        // 【重要】ロジック判定：置ける場所か？
        guard board.canPlace(currentTurn, at: x, y) else {
            print("Invalid Move!")
            // 「ブブー」というエラー振動
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }

        // ロジック更新：石を置く＆ひっくり返すリストを取得
        if let flipped = board.place(currentTurn, at: x, y) {

            Task { @MainActor in
                // 1. 新しい石を置く
                scene.placeDisc(at: x, y, color: currentTurn.uiColor)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                // 2. 挟んだ石をひっくり返す（少し遅らせると気持ちいい）
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機

                for (fx, fy) in flipped {
                    scene.flipDisc(at: fx, fy, to: currentTurn.uiColor)
                }

                // 3. ターン交代
                currentTurn = currentTurn.opponent

                // ※ 本来はここで「パス」の判定や「ゲーム終了」判定が入ります
            }
        }
    }
}

#Preview {
    ContentView()
}
