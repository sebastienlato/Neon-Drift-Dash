import SwiftUI

struct HowToPlayView: View {
    @Binding var screen: AppScreen

    private let tips: [(String, String, String, Color)] = [
        ("Drift", "Drag from the rider or anywhere on the screen. The board follows with a smooth offset.", "hand.draw.fill", DesignSystem.cyan),
        ("Dodge", "Hazards break shields. After a hit, use the flash window to reposition.", "exclamationmark.triangle.fill", DesignSystem.orange),
        ("Shard Rush", "Shards are generous pickups. Every three clean grabs pushes the combo higher.", "diamond.fill", DesignSystem.magenta),
        ("Overdrive", "Waves ramp every 28 seconds with faster traffic and tighter patterns.", "bolt.fill", DesignSystem.gold),
        ("Decks", "Best runs unlock Nova, Phantom, and Solar boards.", "sparkles", DesignSystem.mint)
    ]

    var body: some View {
        ZStack {
            NeonAnimatedBackground(showRooftop: false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HeaderBar(title: "How To Play", subtitle: "Stay loose, chain shards, keep shields alive") {
                        screen = .home
                    }
                    .padding(.top, 18)

                    GlassCard {
                        HStack(spacing: 16) {
                            if DesignSystem.assetExists("EnergyShard") {
                                Image("EnergyShard")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 74, height: 74)
                                    .shadow(color: DesignSystem.cyan.opacity(0.5), radius: 16)
                            } else {
                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 54))
                                    .foregroundStyle(DesignSystem.neonGradient)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Combo flow")
                                    .font(.system(.title3, design: .rounded, weight: .black))
                                    .foregroundStyle(.white)
                                Text("Score comes from survival time and shard streaks. Hits or missed shard chains drop combo back to x1.")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.68))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    ForEach(tips, id: \.0) { tip in
                        tipCard(title: tip.0, body: tip.1, icon: tip.2, tint: tip.3)
                    }

                    Spacer(minLength: 28)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
    }

    private func tipCard(title: String, body: String, icon: String, tint: Color) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.18))
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(.white)
                    Text(body)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.66))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}
