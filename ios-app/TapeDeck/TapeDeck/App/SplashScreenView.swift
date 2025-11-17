import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.95
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.tdBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Logo/Title
                VStack(spacing: 12) {
                    Text("TapeDeck")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.tdPurple)

                    Text("Time Machine")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.tdCyan)
                }
                .scaleEffect(scale)

                Spacer()

                // Welcome message
                VStack(spacing: 8) {
                    Text("Generate playlists from any moment in music history")
                        .font(.body)
                        .foregroundColor(.tdTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Powered by Billboard Hot 100 charts")
                        .font(.caption)
                        .foregroundColor(.tdTextSecondary)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .opacity(opacity)
        }
        .onAppear {
            // Animate in
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            // Animate out and dismiss after 3.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onDismiss()
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(onDismiss: {})
}
