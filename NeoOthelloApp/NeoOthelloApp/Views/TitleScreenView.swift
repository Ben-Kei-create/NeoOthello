import SwiftUI

/// Title screen with mode selection.
struct TitleScreenView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.12),
                    Color(red: 0.1, green: 0.15, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("NEO")
                        .font(.system(size: 48, weight: .thin, design: .monospaced))
                        .foregroundColor(.green.opacity(0.8))
                    Text("OTHELLO")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }

                Spacer()

                // Mode buttons
                VStack(spacing: 16) {
                    modeButton(
                        title: "CLASSIC",
                        subtitle: "Standard 8x8 Reversi",
                        icon: "circle.grid.3x3.fill",
                        color: .blue,
                        mode: .classic
                    )

                    modeButton(
                        title: "ROGUE",
                        subtitle: "Deck & Hand Management",
                        icon: "suit.spade.fill",
                        color: .purple,
                        mode: .rogue
                    )
                }
                .padding(.horizontal, 40)

                Spacer()

                Text("v0.1 prototype")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.bottom, 20)
            }
        }
    }

    private func modeButton(title: String, subtitle: String,
                             icon: String, color: Color, mode: GameMode) -> some View {
        Button(action: {
            viewModel.startGame(mode: mode)
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
