import SceneKit

class GameScene: SCNScene {

    // 盤面全体を操作するための親ノード
    let boardNode = SCNNode()

    override init() {
        super.init()
        setupCamera()
        setupLights()
        setupBoard()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        // 盤面中心(3.5, 3.5)を見下ろす位置
        cameraNode.position = SCNVector3(x: 3.5, y: 10, z: 9.0)
        // 60度くらいの角度で見下ろす
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi / 2.8, y: 0, z: 0)
        rootNode.addChildNode(cameraNode)
    }

    private func setupLights() {
        // 全体を照らす環境光（暗くなりすぎないように）
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 800
        ambientLight.light?.color = UIColor(white: 0.8, alpha: 1.0)
        rootNode.addChildNode(ambientLight)

        // 影を落とすための指向性ライト（右上から）
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 1000
        directionalLight.light?.castsShadow = true // 影を有効化
        directionalLight.position = SCNVector3(x: 5, y: 10, z: 5)
        directionalLight.eulerAngles = SCNVector3(x: -Float.pi / 3, y: -Float.pi / 4, z: 0)
        rootNode.addChildNode(directionalLight)
    }

    private func setupBoard() {
        rootNode.addChildNode(boardNode)

        let cellSize: CGFloat = 1.0
        let spacing: CGFloat = 0.05 // 【こだわり】この隙間がメカニカル感を出す

        for x in 0..<8 {
            for y in 0..<8 {
                // ローポリ＝角ばった直方体 (chamferRadius: 0)
                let box = SCNBox(width: cellSize - spacing,
                                 height: 0.2,
                                 length: cellSize - spacing,
                                 chamferRadius: 0.0)

                // PBRマテリアル設定（実験装置っぽい金属感）
                let material = SCNMaterial()
                material.lightingModel = .physicallyBased
                material.diffuse.contents = UIColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1.0) // 深めの緑
                material.metalness.contents = 0.4 // 金属っぽさ
                material.roughness.contents = 0.3 // ツルツルしすぎない
                box.materials = [material]

                let cellNode = SCNNode(geometry: box)
                cellNode.position = SCNVector3(x: Float(x), y: 0, z: Float(y))

                // 【重要】タップ判定用の名前（ID）
                cellNode.name = "cell_\(x)_\(y)"

                boardNode.addChildNode(cellNode)
            }
        }

        // 土台（床）も少し作っておくとかっこいい
        let floor = SCNBox(width: 10, height: 0.1, length: 10, chamferRadius: 0)
        let floorMat = SCNMaterial()
        floorMat.diffuse.contents = UIColor.darkGray
        floor.materials = [floorMat]
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(3.5, -0.2, 3.5)
        rootNode.addChildNode(floorNode)
    }

    // MARK: - Actions

    /// 指定した座標に石を落とすアニメーション
    func placeDisc(at x: Int, _ y: Int, color: UIColor) {
        // 石のジオメトリ
        let cylinder = SCNCylinder(radius: 0.4, height: 0.15)
        cylinder.radialSegmentCount = 32 // 円柱の滑らかさ

        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = color
        material.specular.contents = UIColor.white // ハイライト
        material.roughness.contents = 0.1 // ツルツル
        cylinder.materials = [material]

        let discNode = SCNNode(geometry: cylinder)
        discNode.name = "disc_\(x)_\(y)" // ★名前を追加！これで後で検索できる

        // 開始位置：盤面の少し上
        let targetY: Float = 0.15 + 0.075 // 盤面(0.1) + 石の半分の高さ
        discNode.position = SCNVector3(x: Float(x), y: 2.0, z: Float(y)) // 高さ2.0から落とす

        // 落下アクション
        let fallAction = SCNAction.move(to: SCNVector3(x: Float(x), y: targetY, z: Float(y)), duration: 0.25)
        fallAction.timingMode = .easeIn // 重力加速っぽく

        // 着地した瞬間の「揺れ」や「音」を入れるならここ

        discNode.runAction(fallAction)
        boardNode.addChildNode(discNode)
    }

    // MARK: - Game Logic Updates

    /// 指定した座標の石の色を変える（ひっくり返す）
    func flipDisc(at x: Int, _ y: Int, to color: UIColor) {
        // ノード名で既存の石を検索
        let discName = "disc_\(x)_\(y)"
        if let existingDisc = boardNode.childNode(withName: discName, recursively: false) {

            // 回転アニメーション（ジャンプ → 回転 → 色変更 → 着地）
            let jumpUp = SCNAction.moveBy(x: 0, y: 0.5, z: 0, duration: 0.1)
            let flip = SCNAction.rotate(by: .pi, around: SCNVector3(1, 0, 0), duration: 0.2)
            let jumpDown = SCNAction.moveBy(x: 0, y: -0.5, z: 0, duration: 0.1)
            let changeColor = SCNAction.run { node in
                node.geometry?.firstMaterial?.diffuse.contents = color
            }

            let sequence = SCNAction.sequence([jumpUp, flip, changeColor, jumpDown])
            existingDisc.runAction(sequence)

        } else {
            // 見つからなければ置く（初期配置用のフォールバック）
            placeDisc(at: x, y, color: color)
        }
    }

    /// ボム爆発パーティクルエフェクト
    func showExplosion(at x: Int, y: Int) {
        let particleSystem = SCNParticleSystem()
        particleSystem.loops = false
        particleSystem.birthRate = 1000
        particleSystem.emissionDuration = 0.1
        particleSystem.particleLifeSpan = 0.5
        particleSystem.particleSize = 0.05
        particleSystem.particleColor = .orange
        particleSystem.emitterShape = SCNSphere(radius: 0.1)
        particleSystem.spreadingAngle = 180

        let node = SCNNode()
        node.addParticleSystem(particleSystem)
        node.position = SCNVector3(x: Float(x), y: 0.2, z: Float(y))

        boardNode.addChildNode(node)

        // 1秒後に掃除
        node.runAction(SCNAction.sequence([
            SCNAction.wait(duration: 1.0),
            SCNAction.removeFromParentNode()
        ]))
    }

    /// 盤面のリセット（石だけ削除、セルは残す）
    func resetBoard() {
        boardNode.childNodes.forEach { node in
            if node.name?.starts(with: "disc_") == true {
                node.removeFromParentNode()
            }
        }
    }
}
