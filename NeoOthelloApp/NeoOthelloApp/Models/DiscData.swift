import Foundation
import SwiftUI // Color用にインポート

// MARK: - Game Enums

enum GameMode: String, CaseIterable {
    case classic = "Classic"
    case rogue = "Rogue"
}

enum TurnPhase {
    case startTurn
    case draw
    case selectHand
    case place
    case effect
    case endTurn
}

// MARK: - Disc Color

enum DiscColor: Int {
    case black = 1
    case white = 2
    case none = 0

    var opponent: DiscColor {
        switch self {
        case .black: return .white
        case .white: return .black
        case .none: return .none
        }
    }

    var displayName: String {
        switch self {
        case .black: return "Black"
        case .white: return "White"
        case .none: return "None"
        }
    }

    // 3D表示用の色
    var uiColor: UIColor {
        switch self {
        case .black: return .black
        case .white: return .white
        case .none: return .clear
        }
    }
}

// MARK: - Disc Type & Data

enum DiscType {
    case normal
    case bomb    // 周囲破壊
    case hacked  // 乗っ取り

    var label: String {
        switch self {
        case .normal: return "Normal"
        case .bomb: return "Bomb"
        case .hacked: return "Hacked"
        }
    }
}

struct Disc {
    var color: DiscColor
    var type: DiscType = .normal
    var id: UUID = UUID() // アニメーション識別用
}
