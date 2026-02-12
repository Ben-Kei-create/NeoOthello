import SwiftUI
import SceneKit

struct SceneKitContainer: UIViewRepresentable {
    let scene: SCNScene
    var onTap: (String) -> Void // タップされたノード名を返すクロージャ

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene

        // 開発用設定（ライトやカメラ操作を許可するか）
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.antialiasingMode = .multisampling4X

        // タップジェスチャーの登録
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // ViewModelから変更があった場合にここでSceneを更新することも可能
        // 今回はContentViewの.onChangeでSceneを直接叩く設計なので、ここは空でもOK
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // タップイベントを処理するコーディネーター
    class Coordinator: NSObject {
        var parent: SceneKitContainer

        init(_ parent: SceneKitContainer) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }

            let location = gesture.location(in: scnView)
            // 3D空間へのヒットテスト（ここが重要！）
            let hitResults = scnView.hitTest(location, options: [.boundingBoxOnly: true])

            if let firstHit = hitResults.first {
                // ノード名（例: "cell_3_4"）を取得して親に返す
                if let nodeName = firstHit.node.name {
                    parent.onTap(nodeName)
                }
            }
        }
    }
}
