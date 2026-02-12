import SceneKit

class GameScene: SCNScene {

    // 盤面の親ノード（回転やアニメーション用）
    let boardNode = SCNNode()

    override init() {
        super.init()
        setupCamera()
        setupBoard()
        setupLights() // 自動ライティングと併用（演出用）
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        // 盤面全体（8x8）が見渡せる位置
        // x:3.5, z:3.5 が盤面の中心なので、そこを見下ろす
        cameraNode.position = SCNVector3(x: 3.5, y: 10, z: 8.5)
        // 60度くらい見下ろす
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi / 3, y: 0, z: 0)
        rootNode.addChildNode(cameraNode)
    }

    private func setupLights() {
        // 雰囲気を出すための環境光
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.3, alpha: 1.0)
        rootNode.addChildNode(ambientLight)
    }

    private func setupBoard() {
        rootNode.addChildNode(boardNode)

        let cellSize: CGFloat = 1.0
        let spacing: CGFloat = 0.05 // セル間の隙間（メカニカルな感じが出る）

        for x in 0..<8 {
            for y in 0..<8 {
                // セルのジオメトリ（ローポリなのでchamferRadiusは0）
                let box = SCNBox(width: cellSize - spacing,
                                 height: 0.2,
                                 length: cellSize - spacing,
                                 chamferRadius: 0.0)

                // マテリアル（オセロっぽい緑）
                let material = SCNMaterial()
                material.diffuse.contents = UIColor(red: 0.0, green: 0.6, blue: 0.2, alpha: 1.0)
                // 少しメタリックにして「機械的な実験装置」感を出す
                material.lightingModel = .physicallyBased
                material.metalness.contents = 0.3
                material.roughness.contents = 0.4
                box.materials = [material]

                let cellNode = SCNNode(geometry: box)
                // 位置設定（y=0が基準）
                cellNode.position = SCNVector3(x: Float(x), y: 0, z: Float(y))

                // 【重要】ここがタップ判定のキーになる名前
                cellNode.name = "cell_\(x)_\(y)"

                boardNode.addChildNode(cellNode)
            }
        }
    }

    // 盤面に石を置く演出（後で使います）
    func placeDisc(at x: Int, _ y: Int, color: UIColor) {
        let cylinder = SCNCylinder(radius: 0.4, height: 0.2)
        cylinder.radialSegmentCount = 32 // 円柱の滑らかさ

        let material = SCNMaterial()
        material.diffuse.contents = color
        cylinder.materials = [material]

        let discNode = SCNNode(geometry: cylinder)
        discNode.position = SCNVector3(x: Float(x), y: 0.5, z: Float(y)) // y=0.5で上から降ってくる演出用

        // アニメーション：上から「ストン」と落ちる
        discNode.position.y += 2.0
        let moveAction = SCNAction.move(to: SCNVector3(Float(x), 0.15, Float(y)), duration: 0.3)
        moveAction.timingMode = .easeOut

        discNode.runAction(moveAction)
        boardNode.addChildNode(discNode)
    }
}
