import SwiftUI
import UIKit

enum DesignSystem {
    static let background = Color(red: 0.02, green: 0.00, blue: 0.08)
    static let panel = Color.white.opacity(0.08)
    static let panelStroke = Color.white.opacity(0.18)
    static let cyan = Color(red: 0.07, green: 0.82, blue: 1.0)
    static let magenta = Color(red: 1.0, green: 0.10, blue: 0.78)
    static let violet = Color(red: 0.55, green: 0.16, blue: 1.0)
    static let orange = Color(red: 1.0, green: 0.34, blue: 0.12)
    static let gold = Color(red: 1.0, green: 0.72, blue: 0.22)
    static let mint = Color(red: 0.25, green: 1.0, blue: 0.62)

    static let neonGradient = LinearGradient(
        colors: [cyan, magenta, orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func assetExists(_ name: String) -> Bool {
        UIImage(named: name) != nil
    }
}

struct NeonAnimatedBackground: View {
    var showRooftop: Bool = true

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { proxy in
                ZStack {
                    if DesignSystem.assetExists("NightSky") {
                        Image("NightSky")
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    } else {
                        LinearGradient(
                            colors: [
                                Color(red: 0.02, green: 0.00, blue: 0.08),
                                Color(red: 0.11, green: 0.02, blue: 0.20),
                                Color(red: 0.01, green: 0.01, blue: 0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }

                    skylineLayer("FarSkyline", opacity: 0.72, yOffset: CGFloat(sin(time * 0.24)) * 8, in: proxy.size)
                    skylineLayer("MidBuildings", opacity: 0.76, yOffset: CGFloat(sin(time * 0.34 + 0.7)) * 12, in: proxy.size)

                    NeonGridOverlay(time: time)
                        .opacity(0.32)
                        .blendMode(.screen)

                    RadialGradient(
                        colors: [DesignSystem.magenta.opacity(0.28), .clear],
                        center: .topTrailing,
                        startRadius: 10,
                        endRadius: proxy.size.width * 0.9
                    )

                    RadialGradient(
                        colors: [DesignSystem.cyan.opacity(0.22), .clear],
                        center: .bottomLeading,
                        startRadius: 10,
                        endRadius: proxy.size.width * 0.8
                    )

                    if showRooftop, DesignSystem.assetExists("RooftopForeground") {
                        VStack {
                            Spacer()
                            Image("RooftopForeground")
                                .resizable()
                                .scaledToFill()
                                .frame(width: proxy.size.width, height: proxy.size.height * 0.33)
                                .clipped()
                                .offset(y: 24 + CGFloat(sin(time * 0.6)) * 3)
                                .opacity(0.9)
                        }
                    }

                    Color.black.opacity(0.18)
                }
                .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private func skylineLayer(_ name: String, opacity: Double, yOffset: CGFloat, in size: CGSize) -> some View {
        if DesignSystem.assetExists(name) {
            VStack {
                Spacer()
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height * 0.72)
                    .clipped()
                    .offset(y: yOffset)
                    .opacity(opacity)
            }
        }
    }
}

struct NeonGridOverlay: View {
    let time: TimeInterval

    var body: some View {
        Canvas { context, size in
            let horizon = size.height * 0.55
            let spacing: CGFloat = 34
            let phase = CGFloat(time.truncatingRemainder(dividingBy: 1.4)) / 1.4 * spacing

            var horizontal = Path()
            var y = horizon + phase
            while y < size.height {
                let progress = max(0, min(1, (y - horizon) / max(1, size.height - horizon)))
                let lineWidth = 0.5 + progress * 1.5
                horizontal.move(to: CGPoint(x: 0, y: y))
                horizontal.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(horizontal, with: .color(DesignSystem.cyan.opacity(0.22)), lineWidth: lineWidth)
                horizontal = Path()
                y += spacing * (1 + progress)
            }

            for index in -8...8 {
                var path = Path()
                let startX = size.width * 0.5 + CGFloat(index) * 18
                let endX = size.width * 0.5 + CGFloat(index) * 92
                path.move(to: CGPoint(x: startX, y: horizon))
                path.addLine(to: CGPoint(x: endX, y: size.height))
                context.stroke(path, with: .color(DesignSystem.magenta.opacity(0.18)), lineWidth: 1)
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [DesignSystem.cyan.opacity(0.5), DesignSystem.magenta.opacity(0.45), .white.opacity(0.16)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: DesignSystem.magenta.opacity(0.18), radius: 18, y: 10)
    }
}

struct NeonButton: View {
    let title: String
    var systemImage: String?
    var style: ButtonTone = .primary
    let action: () -> Void

    enum ButtonTone {
        case primary
        case secondary
        case danger
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .bold))
                }
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(background)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(stroke, lineWidth: 1.4)
            }
            .shadow(color: glow, radius: 18, y: 8)
        }
        .buttonStyle(NeonPressButtonStyle())
    }

    private var background: some ShapeStyle {
        switch style {
        case .primary:
            LinearGradient(colors: [DesignSystem.magenta.opacity(0.92), DesignSystem.violet.opacity(0.88), DesignSystem.cyan.opacity(0.86)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .secondary:
            LinearGradient(colors: [Color.white.opacity(0.12), DesignSystem.violet.opacity(0.26)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .danger:
            LinearGradient(colors: [Color.red.opacity(0.75), DesignSystem.orange.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var stroke: some ShapeStyle {
        switch style {
        case .primary:
            LinearGradient(colors: [.white.opacity(0.8), DesignSystem.cyan.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .secondary:
            LinearGradient(colors: [DesignSystem.cyan.opacity(0.55), DesignSystem.magenta.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .danger:
            LinearGradient(colors: [.white.opacity(0.55), DesignSystem.orange.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var glow: Color {
        switch style {
        case .primary: DesignSystem.magenta.opacity(0.35)
        case .secondary: DesignSystem.cyan.opacity(0.18)
        case .danger: DesignSystem.orange.opacity(0.25)
        }
    }
}

struct NeonPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.spring(response: 0.24, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

struct StatPill: View {
    let title: String
    let value: String
    var tint: Color = DesignSystem.cyan

    var body: some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(minWidth: 72, minHeight: 46)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial.opacity(0.68), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.55), lineWidth: 1)
        }
        .shadow(color: tint.opacity(0.18), radius: 12)
    }
}

struct BoardPreview: View {
    let board: BoardStyle
    var locked: Bool = false

    var body: some View {
        ZStack {
            Capsule()
                .fill(board.gradient)
                .frame(width: 142, height: 34)
                .blur(radius: 10)
                .opacity(locked ? 0.28 : 0.9)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.88), Color(red: 0.12, green: 0.08, blue: 0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 138, height: 26)
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(board.gradient)
                        .frame(height: 7)
                        .blur(radius: 0.4)
                }
                .overlay {
                    Capsule()
                        .stroke(board.gradient, lineWidth: 2)
                }
                .rotationEffect(.degrees(-5))
                .opacity(locked ? 0.42 : 1)

            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(width: 160, height: 62)
    }
}
