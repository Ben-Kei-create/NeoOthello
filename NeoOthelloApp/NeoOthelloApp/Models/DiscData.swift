import Foundation

// MARK: - Enums

enum GameMode: String, CaseIterable {
    case classic = "Classic"
    case rogue = "Rogue"
}

enum DiscType: String, CaseIterable {
    case normal = "Normal"
    case hacked = "Hacked"
    case bomb = "Bomb"
}

enum DiscColor: Equatable {
    case none
    case black
    case white

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
}

enum TurnPhase {
    case startTurn
    case draw
    case selectHand
    case place
    case effect
    case endTurn
}

// MARK: - DiscData

struct DiscData: Identifiable, Equatable {
    let id: UUID
    var type: DiscType
    var color: DiscColor

    init(type: DiscType = .normal, color: DiscColor = .none) {
        self.id = UUID()
        self.type = type
        self.color = color
    }

    static func == (lhs: DiscData, rhs: DiscData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - BoardCell

struct BoardCell {
    let row: Int
    let col: Int
    var color: DiscColor = .none
    var placedType: DiscType = .normal

    var isEmpty: Bool { color == .none }

    mutating func place(color: DiscColor, type: DiscType = .normal) {
        self.color = color
        self.placedType = type
    }

    mutating func flip() {
        color = color.opponent
    }

    mutating func clear() {
        color = .none
        placedType = .normal
    }
}
