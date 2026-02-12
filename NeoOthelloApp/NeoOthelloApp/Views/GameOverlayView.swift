import SwiftUI

/// 2D overlay UI: score, turn indicator, hand slots, messages.
struct GameOverlayView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: score and turn info
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Spacer()

            // Message banner
            if !viewModel.message.isEmpty {
                messageBanner
            }

            // Rogue mode: deck info + hand slots
            if viewModel.gameMode == .rogue {
                deckInfoBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                handView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Black score
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                Text("\(viewModel.blackCount)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            Spacer()

            // Turn indicator
            Text(turnText)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(turnColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.6))
                )

            Spacer()

            // White score
            HStack(spacing: 6) {
                Text("\(viewModel.whiteCount)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
            }
        }
    }

    private var turnText: String {
        if viewModel.isGameOver {
            return "GAME OVER"
        }
        return viewModel.currentPlayer == .black ? "YOUR TURN" : "AI THINKING..."
    }

    private var turnColor: Color {
        viewModel.currentPlayer == .black ? .green : .orange
    }

    // MARK: - Message Banner

    private var messageBanner: some View {
        Text(viewModel.message)
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(bannerColor.opacity(0.85))
            )
            .padding(.bottom, 8)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: viewModel.message)
    }

    private var bannerColor: Color {
        if viewModel.limitBreakTriggered { return .purple }
        if viewModel.hackedForcePosition != nil { return .red }
        if viewModel.isGameOver {
            return viewModel.winner == .black ? .green : .red
        }
        return .gray
    }

    // MARK: - Deck Info

    private var deckInfoBar: some View {
        HStack {
            Label("\(viewModel.deck.remainingCount)", systemImage: "square.stack.3d.up")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text("Hand: \(viewModel.blackHand.count)/\(viewModel.blackHand.capacity)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Hand View

    private var handView: some View {
        HStack(spacing: 8) {
            ForEach(0..<Hand.maxCapacity, id: \.self) { index in
                handSlot(index: index)
            }
        }
    }

    @ViewBuilder
    private func handSlot(index: Int) -> some View {
        let hand = viewModel.blackHand

        if index >= hand.capacity {
            // Locked slot
            lockedSlotView
        } else if index < hand.count, let disc = hand.disc(at: index) {
            // Disc in slot
            discSlotView(disc: disc, index: index)
        } else {
            // Empty unlocked slot
            emptySlotView
        }
    }

    private var lockedSlotView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.15))
            .frame(height: 60)
            .overlay(
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray.opacity(0.3))
                    .font(.system(size: 16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }

    private func discSlotView(disc: DiscData, index: Int) -> some View {
        let isSelectable = viewModel.isWaitingForHandSelection
            && viewModel.currentPhase == .selectHand

        return Button(action: {
            if isSelectable {
                viewModel.playerSelectHandDisc(index: index)
            }
        }) {
            RoundedRectangle(cornerRadius: 8)
                .fill(discSlotColor(type: disc.type))
                .frame(height: 60)
                .overlay(
                    VStack(spacing: 2) {
                        discIcon(type: disc.type)
                            .font(.system(size: 20))
                        Text(disc.type.rawValue)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelectable ? Color.yellow : Color.white.opacity(0.3),
                                lineWidth: isSelectable ? 2 : 1)
                )
                .scaleEffect(isSelectable ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                           value: isSelectable)
        }
        .disabled(!isSelectable)
    }

    private var emptySlotView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.05))
            .frame(height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }

    private func discSlotColor(type: DiscType) -> Color {
        switch type {
        case .normal: return Color(red: 0.3, green: 0.3, blue: 0.35)
        case .hacked: return Color(red: 0.6, green: 0.15, blue: 0.15)
        case .bomb: return Color(red: 0.7, green: 0.4, blue: 0.05)
        }
    }

    private func discIcon(type: DiscType) -> Image {
        switch type {
        case .normal: return Image(systemName: "circle.fill")
        case .hacked: return Image(systemName: "exclamationmark.triangle.fill")
        case .bomb: return Image(systemName: "flame.fill")
        }
    }
}

// MARK: - Game Over Overlay

struct GameOverOverlay: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        if viewModel.isGameOver {
            VStack(spacing: 20) {
                Text(resultTitle)
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundColor(resultColor)

                Text("Black \(viewModel.blackCount) - White \(viewModel.whiteCount)")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)

                HStack(spacing: 16) {
                    Button("Restart") {
                        viewModel.startGame(mode: viewModel.gameMode)
                    }
                    .buttonStyle(GameButtonStyle(color: .green))

                    Button("Title") {
                        viewModel.returnToTitle()
                    }
                    .buttonStyle(GameButtonStyle(color: .blue))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.85))
            )
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var resultTitle: String {
        switch viewModel.winner {
        case .black: return "YOU WIN"
        case .white: return "AI WINS"
        case .none: return "DRAW"
        }
    }

    private var resultColor: Color {
        switch viewModel.winner {
        case .black: return .green
        case .white: return .red
        case .none: return .yellow
        }
    }
}

// MARK: - Button Style

struct GameButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(configuration.isPressed ? 0.5 : 0.8))
            )
    }
}
