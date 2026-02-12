import SceneKit

/// SceneKit scene for the 3D Othello board.
/// Creates board cells as flat boxes, discs as cylinders.
/// chamferRadius = 0 for the low-poly aesthetic.
final class GameScene: SCNScene {

    static let cellSize: Float = 1.0
    static let discRadius: Float = 0.38
    static let discHeight: Float = 0.12
    static let boardSize = 8

    private var cellNodes: [[SCNNode]] = []
    private var discNodes: [[SCNNode?]] = []
    private var highlightNodes: [[SCNNode]] = []
    private let boardRoot = SCNNode()

    override init() {
        super.init()
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        rootNode.addChildNode(boardRoot)
        buildBoard()
        setupCamera()
        setupLighting()
    }

    // MARK: - Board Construction

    private func buildBoard() {
        let offset = Float(GameScene.boardSize - 1) * GameScene.cellSize * 0.5

        cellNodes = Array(repeating: Array(repeating: SCNNode(), count: GameScene.boardSize),
                          count: GameScene.boardSize)
        discNodes = Array(repeating: Array(repeating: nil, count: GameScene.boardSize),
                          count: GameScene.boardSize)
        highlightNodes = Array(repeating: Array(repeating: SCNNode(), count: GameScene.boardSize),
                               count: GameScene.boardSize)

        for r in 0..<GameScene.boardSize {
            for c in 0..<GameScene.boardSize {
                let x = Float(c) * GameScene.cellSize - offset
                let z = Float(GameScene.boardSize - 1 - r) * GameScene.cellSize - offset

                // Cell tile (flat box, chamferRadius 0 for low-poly)
                let cellGeo = SCNBox(width: CGFloat(GameScene.cellSize * 0.95),
                                     height: 0.1,
                                     length: CGFloat(GameScene.cellSize * 0.95),
                                     chamferRadius: 0)
                let cellMat = SCNMaterial()
                cellMat.diffuse.contents = boardGreen(row: r, col: c)
                cellGeo.materials = [cellMat]

                let cellNode = SCNNode(geometry: cellGeo)
                cellNode.position = SCNVector3(x, 0, z)
                cellNode.name = "cell_\(r)_\(c)"
                boardRoot.addChildNode(cellNode)
                cellNodes[r][c] = cellNode

                // Valid-move highlight (slightly above cell)
                let hlGeo = SCNBox(width: CGFloat(GameScene.cellSize * 0.85),
                                   height: 0.02,
                                   length: CGFloat(GameScene.cellSize * 0.85),
                                   chamferRadius: 0)
                let hlMat = SCNMaterial()
                hlMat.diffuse.contents = UIColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 0.5)
                hlMat.transparency = 0.5
                hlGeo.materials = [hlMat]

                let hlNode = SCNNode(geometry: hlGeo)
                hlNode.position = SCNVector3(x, 0.08, z)
                hlNode.name = "hl_\(r)_\(c)"
                hlNode.isHidden = true
                boardRoot.addChildNode(hlNode)
                highlightNodes[r][c] = hlNode
            }
        }

        // Board frame
        let frameGeo = SCNBox(width: CGFloat(Float(GameScene.boardSize) * GameScene.cellSize + 0.3),
                              height: 0.15,
                              length: CGFloat(Float(GameScene.boardSize) * GameScene.cellSize + 0.3),
                              chamferRadius: 0)
        let frameMat = SCNMaterial()
        frameMat.diffuse.contents = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1)
        frameGeo.materials = [frameMat]

        let frameNode = SCNNode(geometry: frameGeo)
        frameNode.position = SCNVector3(0, -0.08, 0)
        boardRoot.addChildNode(frameNode)
    }

    private func boardGreen(row: Int, col: Int) -> UIColor {
        // Checkerboard-style subtle variation
        let base: CGFloat = (row + col) % 2 == 0 ? 0.28 : 0.32
        return UIColor(red: 0, green: base, blue: 0.05, alpha: 1)
    }

    // MARK: - Camera & Lighting

    private func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.position = SCNVector3(0, 10, 7)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        rootNode.addChildNode(cameraNode)
    }

    private func setupLighting() {
        // Key light
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 800
        keyLight.light?.color = UIColor.white
        keyLight.light?.castsShadow = true
        keyLight.position = SCNVector3(5, 12, 5)
        keyLight.look(at: SCNVector3(0, 0, 0))
        rootNode.addChildNode(keyLight)

        // Ambient
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 400
        ambient.light?.color = UIColor(white: 0.7, alpha: 1)
        rootNode.addChildNode(ambient)
    }

    // MARK: - Update Board State

    func updateBoard(_ board: Board) {
        let offset = Float(GameScene.boardSize - 1) * GameScene.cellSize * 0.5

        for r in 0..<GameScene.boardSize {
            for c in 0..<GameScene.boardSize {
                let cell = board.cells[r][c]

                if cell.isEmpty {
                    // Remove disc if present
                    if let existing = discNodes[r][c] {
                        existing.removeFromParentNode()
                        discNodes[r][c] = nil
                    }
                } else {
                    let x = Float(c) * GameScene.cellSize - offset
                    let z = Float(GameScene.boardSize - 1 - r) * GameScene.cellSize - offset

                    if let existing = discNodes[r][c] {
                        // Update color
                        updateDiscColor(existing, color: cell.color, type: cell.placedType)
                    } else {
                        // Create new disc
                        let discNode = createDiscNode(color: cell.color, type: cell.placedType)
                        discNode.position = SCNVector3(x, 0.12, z)
                        discNode.name = "disc_\(r)_\(c)"
                        boardRoot.addChildNode(discNode)
                        discNodes[r][c] = discNode

                        // Drop animation
                        animateDiscDrop(discNode, targetY: 0.12)
                    }
                }
            }
        }
    }

    func updateHighlights(_ positions: [(row: Int, col: Int)]) {
        let validSet = Set(positions.map { "\($0.row)_\($0.col)" })

        for r in 0..<GameScene.boardSize {
            for c in 0..<GameScene.boardSize {
                highlightNodes[r][c].isHidden = !validSet.contains("\(r)_\(c)")
            }
        }
    }

    // MARK: - Disc Creation

    private func createDiscNode(color: DiscColor, type: DiscType) -> SCNNode {
        // Low-poly cylinder (chamferRadius not applicable to cylinder,
        // so we use segmentCount for the angular look)
        let geo = SCNCylinder(radius: CGFloat(GameScene.discRadius),
                              height: CGFloat(GameScene.discHeight))
        geo.radialSegmentCount = type == .bomb ? 6 : 24  // Hexagonal for bomb
        geo.heightSegmentCount = 1

        let mat = SCNMaterial()
        mat.diffuse.contents = discUIColor(color: color, type: type)
        mat.specular.contents = UIColor.white
        geo.materials = [mat]

        let node = SCNNode(geometry: geo)
        return node
    }

    private func updateDiscColor(_ node: SCNNode, color: DiscColor, type: DiscType) {
        guard let geo = node.geometry as? SCNCylinder else { return }
        geo.materials.first?.diffuse.contents = discUIColor(color: color, type: type)
    }

    private func discUIColor(color: DiscColor, type: DiscType) -> UIColor {
        switch type {
        case .hacked:
            return color == .black
                ? UIColor(red: 0.3, green: 0, blue: 0, alpha: 1)
                : UIColor(red: 0.9, green: 0.6, blue: 0.6, alpha: 1)
        case .bomb:
            return color == .black
                ? UIColor(red: 0.4, green: 0.2, blue: 0, alpha: 1)
                : UIColor(red: 1, green: 0.85, blue: 0.5, alpha: 1)
        case .normal:
            return color == .black ? UIColor.black : UIColor.white
        }
    }

    // MARK: - Animations

    private func animateDiscDrop(_ node: SCNNode, targetY: Float) {
        let startY = targetY + 2.0
        node.position.y = startY

        let dropAction = SCNAction.move(to: SCNVector3(node.position.x, targetY, node.position.z),
                                        duration: 0.25)
        dropAction.timingMode = .easeIn

        // Small bounce
        let bounceUp = SCNAction.move(to: SCNVector3(node.position.x, targetY + 0.15, node.position.z),
                                      duration: 0.1)
        bounceUp.timingMode = .easeOut
        let bounceDown = SCNAction.move(to: SCNVector3(node.position.x, targetY, node.position.z),
                                        duration: 0.1)
        bounceDown.timingMode = .easeIn

        node.runAction(SCNAction.sequence([dropAction, bounceUp, bounceDown]))
    }

    /// Flash a cell red for bomb effect.
    func animateBombEffect(positions: [(Int, Int)]) {
        for (r, c) in positions {
            if let discNode = discNodes[r][c] {
                let flash = SCNAction.customAction(duration: 0.3) { node, elapsed in
                    let progress = Float(elapsed) / 0.3
                    let mat = node.geometry?.materials.first
                    mat?.diffuse.contents = UIColor(red: CGFloat(1.0),
                                                    green: CGFloat(1.0 - progress),
                                                    blue: 0,
                                                    alpha: CGFloat(1.0 - progress * 0.5))
                }
                let remove = SCNAction.removeFromParentNode()
                discNode.runAction(SCNAction.sequence([flash, remove]))
                discNodes[r][c] = nil
            }
        }
    }

    // MARK: - Hit Testing Helper

    /// Parse a node name like "cell_3_4" into (row, col).
    static func parseCellName(_ name: String) -> (row: Int, col: Int)? {
        let parts = name.split(separator: "_")
        guard parts.count == 3, parts[0] == "cell",
              let row = Int(parts[1]), let col = Int(parts[2]) else {
            return nil
        }
        return (row, col)
    }
}
