import SwiftUI
import SceneKit

/// Wraps a SceneKit SCNView for use in SwiftUI with tap gesture support.
struct SceneKitContainer: UIViewRepresentable {
    let scene: GameScene
    let onCellTapped: (Int, Int) -> Void

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = false
        scnView.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1)
        scnView.antialiasingMode = .multisampling4X

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        scnView.addGestureRecognizer(tapGesture)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Scene updates are handled via GameScene methods directly
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scene: scene, onCellTapped: onCellTapped)
    }

    class Coordinator: NSObject {
        let scene: GameScene
        let onCellTapped: (Int, Int) -> Void

        init(scene: GameScene, onCellTapped: @escaping (Int, Int) -> Void) {
            self.scene = scene
            self.onCellTapped = onCellTapped
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [
                .searchMode: SCNHitTestSearchMode.closest.rawValue
            ])

            for hit in hitResults {
                // Check the tapped node and its ancestors for a cell name
                var node: SCNNode? = hit.node
                while let current = node {
                    if let name = current.name,
                       let cell = GameScene.parseCellName(name) {
                        onCellTapped(cell.row, cell.col)
                        return
                    }
                    node = current.parent
                }
            }
        }
    }
}
