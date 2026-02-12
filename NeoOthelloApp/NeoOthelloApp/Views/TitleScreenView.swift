import SwiftUI

/// Title screen with mode selection (reserved for future use).
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

                // Start button
                Button(action: {
                    viewModel.startNewGame()
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "suit.spade.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.purple)
                            .frame(width: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("ROGUE")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Deck & Hand Management")
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
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 40)

                Spacer()

                Text("v0.2 prototype")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.bottom, 20)
            }
        }
    }
}
