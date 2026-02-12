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

            // Deck info
            deckInfoBar
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            // Hand slots（常に表示）
            handView
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

            // Game Over overlay
            if viewModel.isGameOver {
                gameOverOverlay
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
        return viewModel.currentTurn == .black ? "YOUR TURN" : "AI THINKING..."
    }

    private var turnColor: Color {
        viewModel.currentTurn == .black ? .green : .orange
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
        if viewModel.isGameOver {
            return viewModel.winner == .black ? .green : .red
        }
        return .gray
    }

    // MARK: - Deck Info

    private var deckInfoBar: some View {
        HStack {
            Label("\(viewModel.deck.count)", systemImage: "square.stack.3d.up")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text("Hand: \(viewModel.playerHand.discs.count)/\(viewModel.playerHand.capacity)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Hand View

    private var handView: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.playerHand.capacity, id: \.self) { index in
                handSlot(index: index)
            }
        }
    }

    @ViewBuilder
    private func handSlot(index: Int) -> some View {
        if index < viewModel.playerHand.discs.count {
            // Disc in slot
            let disc = viewModel.playerHand.discs[index]
            let isSelected = viewModel.selectedDiscIndex == index

            Button(action: {
                viewModel.selectDisc(at: index)
            }) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(discSlotColor(type: disc.type))
                    .frame(height: 60)
                    .overlay(
                        VStack(spacing: 2) {
                            discIcon(type: disc.type)
                                .font(.system(size: 20))
                            Text(disc.type.label)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.yellow : Color.white.opacity(0.3),
                                    lineWidth: isSelected ? 3 : 1)
                    )
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .disabled(viewModel.currentTurn != .black)
        } else {
            // Empty slot
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
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

    // MARK: - Game Over

    private var gameOverOverlay: some View {
        VStack(spacing: 20) {
            Text(resultTitle)
                .font(.system(size: 32, weight: .black, design: .monospaced))
                .foregroundColor(resultColor)

            Text("Black \(viewModel.blackCount) - White \(viewModel.whiteCount)")
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.white)

            Button("Restart") {
                viewModel.startNewGame()
            }
            .buttonStyle(GameButtonStyle(color: .green))
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
        )
        .transition(.scale.combined(with: .opacity))
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
