import SwiftUI

struct HeaderBar: View {
    let title: String
    let subtitle: String
    let backAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: backAction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(DesignSystem.cyan.opacity(0.4), lineWidth: 1)
                    }
            }
            .buttonStyle(NeonPressButtonStyle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }

            Spacer()
        }
    }
}
