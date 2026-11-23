import SwiftUI

struct CleaningView: View {
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.teal)
                .padding(.bottom, 10)
            Text("Cleaning Mode")
                .font(.title.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.bottom, 10)
            Text("Screen and keyboard are locked, you can start cleaning.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.55))
            Button(action: onExit) {
                Text("Exit")
                    .fontWeight(.semibold)
                    .frame(width: 82, height: 40)
                    .background(Capsule().fill(Color.teal))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.top, 30)
        }
        // ponytail: dimmed so the content doesn't hide smudges; raise if Exit gets hard to find
        .opacity(0.4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.03, green: 0.03, blue: 0.035))
    }
}

#Preview {
    CleaningView(onExit: {})
        .frame(width: 800, height: 500)
}
