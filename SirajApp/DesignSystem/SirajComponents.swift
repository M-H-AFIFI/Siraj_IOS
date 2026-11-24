import SwiftUI
import SirajCore

struct SirajSwitch: View {
    @Environment(\.sirajTheme) private var theme
    @Binding var isOn: Bool

    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .tint(theme.primary)
    }
}

struct SirajSegmentedPills<Option: Identifiable & Hashable>: View {
    @Environment(\.sirajTheme) private var theme
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options) { option in
                let active = option == selection
                Button {
                    if theme.motionEnabled {
                        withAnimation(.easeInOut(duration: 0.2)) { selection = option }
                    } else {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(theme.scaledFont(size: 13, weight: active ? .bold : .medium))
                        .foregroundStyle(active ? theme.onPrimary : theme.onSurfaceVariant)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule().fill(active ? theme.primary : theme.surfaceVariant.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(theme.surfaceContainerLow))
    }
}

struct SirajSettingsSection<Content: View>: View {
    @Environment(\.sirajTheme) private var theme
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(theme.scaledFont(size: 12, weight: .bold))
                .foregroundStyle(theme.primary)
                .textCase(.uppercase)
                .padding(.horizontal, 6)

            VStack(spacing: 0) {
                content
            }
            .sirajCardSurface(cornerRadius: 22)
        }
    }
}

struct SirajSettingsRow: View {
    @Environment(\.sirajTheme) private var theme
    let icon: String
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.primary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(theme.primary.opacity(0.12)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.scaledFont(size: 15, weight: .semibold))
                        .foregroundStyle(theme.onSurface)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(theme.scaledFont(size: 12))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 8)
                if let value, !value.isEmpty {
                    Text(value)
                        .font(theme.scaledFont(size: 13, weight: .medium))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(1)
                }
                Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.outline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SirajSettingsToggleRow: View {
    @Environment(\.sirajTheme) private var theme
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.primary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(theme.primary.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.scaledFont(size: 15, weight: .semibold))
                    .foregroundStyle(theme.onSurface)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(3)
                }
            }
            Spacer(minLength: 8)
            SirajSwitch(isOn: $isOn)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct RollingCountdownText: View {
    @Environment(\.sirajTheme) private var theme
    let text: String
    var fontSize: CGFloat = 34
    var weight: Font.Weight = .bold
    var color: Color = .white
    var gradient: LinearGradient? = nil
    var hasShadow: Bool = false
    var countingUp: Bool = false

    var body: some View {
        Group {
            if let gradient {
                ZStack {
                    if hasShadow {
                        digitText
                            .foregroundStyle(.white)
                            .shadow(color: Color.black.opacity(0.55), radius: 6, x: 0, y: 2)
                    }
                    digitText
                        .foregroundStyle(gradient)
                }
            } else {
                digitText
                    .foregroundStyle(color)
                    .shadow(color: hasShadow ? Color.black.opacity(0.55) : .clear, radius: hasShadow ? 6 : 0, x: 0, y: hasShadow ? 2 : 0)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var digitText: some View {
        Text(text)
            .font(.system(size: fontSize, weight: weight, design: .rounded).monospacedDigit())
            .lineLimit(1)
            .contentTransition(theme.motionEnabled ? .numericText(countsDown: !countingUp) : .identity)
            .animation(theme.motionEnabled ? .easeInOut(duration: 0.24) : nil, value: text)
    }
}

struct HeroText: View {
    let text: String
    let font: Font
    let gradient: LinearGradient

    var body: some View {
        // Two layers so the shadow stays dark over bright daytime skies instead of taking the gradient tint.
        ZStack {
            Text(text)
                .font(font)
                .foregroundStyle(.white)
                .lineLimit(1)
                .shadow(color: Color.black.opacity(0.55), radius: 6, x: 0, y: 2)
            Text(text)
                .font(font)
                .foregroundStyle(gradient)
                .lineLimit(1)
                .accessibilityHidden(true)
        }
    }
}

struct IslamicOccasionBadge: View {
    @Environment(\.sirajTheme) private var theme
    let occasionId: String
    var size: CGFloat = 48
    var highlighted: Bool = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
        ZStack {
            shape
                .fill(
                    highlighted
                        ? LinearGradient(colors: [theme.primary, theme.primary.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [theme.primary.opacity(0.14), theme.gold.opacity(0.20)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Image(Self.iconName(for: occasionId))
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.54, height: size * 0.54)
                .foregroundStyle(highlighted ? theme.onPrimary : theme.primary)
        }
        .frame(width: size, height: size)
        .overlay {
            if !highlighted {
                shape.strokeBorder(theme.gold.opacity(0.35), lineWidth: 1)
            }
        }
    }

    static func iconName(for id: String) -> String {
        switch id {
        case "islamic_new_year": return "ic_occasion_islamic_new_year"
        case "ashura": return "ic_occasion_ashura"
        case "isra_miraj": return "ic_occasion_isra_miraj"
        case "mid_shaban": return "ic_occasion_mid_shaban"
        case "ramadan", "ramadan_start": return "ic_occasion_ramadan"
        case "last_ten_ramadan": return "ic_occasion_laylat_qadr"
        case "eid_al_fitr": return "ic_occasion_eid_al_fitr"
        case "day_of_arafah": return "ic_occasion_day_of_arafah"
        case "eid_al_adha": return "ic_occasion_eid_al_adha"
        default: return "ic_occasion_default"
        }
    }
}

/// Builds the astronomical lit lunar limb path for a phase fraction in 0...1 (0 new, 0.5 full).
func moonLimbPath(center: CGPoint, radius: CGFloat, phaseFraction: Double) -> Path {
    var path = Path()
    let k = cos(phaseFraction * 2.0 * .pi)
    let isWaxing = phaseFraction >= 0.0 && phaseFraction <= 0.5

    if phaseFraction >= 0.47 && phaseFraction <= 0.53 {
        path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        return path
    }
    if phaseFraction < 0.02 || phaseFraction > 0.98 {
        return path
    }

    let m: CGFloat = 0.55228475
    let cx = center.x
    let cy = center.y
    let limbX: CGFloat = isWaxing ? radius : -radius
    let rx = CGFloat(k) * limbX

    path.move(to: CGPoint(x: cx, y: cy - radius))
    path.addCurve(
        to: CGPoint(x: cx + limbX, y: cy),
        control1: CGPoint(x: cx + limbX * m, y: cy - radius),
        control2: CGPoint(x: cx + limbX, y: cy - radius * m)
    )
    path.addCurve(
        to: CGPoint(x: cx, y: cy + radius),
        control1: CGPoint(x: cx + limbX, y: cy + radius * m),
        control2: CGPoint(x: cx + limbX * m, y: cy + radius)
    )

    let isCrescent = (phaseFraction >= 0.02 && phaseFraction <= 0.22) || (phaseFraction >= 0.78 && phaseFraction <= 0.98)
    if isCrescent && k > 0.05 {
        let cuspTightness = CGFloat(min(0.85, max(0.18, k * 0.90)))
        let innerRx = limbX * cuspTightness
        path.addCurve(
            to: CGPoint(x: cx + innerRx, y: cy),
            control1: CGPoint(x: cx + innerRx * 0.22, y: cy + radius * 0.68),
            control2: CGPoint(x: cx + innerRx, y: cy + radius * 0.38)
        )
        path.addCurve(
            to: CGPoint(x: cx, y: cy - radius),
            control1: CGPoint(x: cx + innerRx, y: cy - radius * 0.38),
            control2: CGPoint(x: cx + innerRx * 0.22, y: cy - radius * 0.68)
        )
    } else {
        path.addCurve(
            to: CGPoint(x: cx + rx, y: cy),
            control1: CGPoint(x: cx + rx * m, y: cy + radius),
            control2: CGPoint(x: cx + rx, y: cy + radius * m)
        )
        path.addCurve(
            to: CGPoint(x: cx, y: cy - radius),
            control1: CGPoint(x: cx + rx, y: cy - radius * m),
            control2: CGPoint(x: cx + rx * m, y: cy - radius)
        )
    }
    path.closeSubpath()
    return path
}

struct MoonPhaseGlyph: View {
    let phaseFraction: Double
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2.0 - 0.5
            let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
            ctx.fill(
                Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                with: .color(color.opacity(0.22))
            )
            let lit = moonLimbPath(center: center, radius: r, phaseFraction: phaseFraction)
            ctx.fill(lit, with: .color(color))
        }
    }
}

struct MihrabTimePickerSheet: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let title: String
    @State private var selectedDate: Date
    let onSave: (Int, Int) -> Void

    init(title: String, hour: Int, minute: Int, onSave: @escaping (Int, Int) -> Void) {
        self.title = title
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        self._selectedDate = State(initialValue: Calendar.current.date(from: comps) ?? Date())
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                Spacer()
            }
            .padding()
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(theme.t("settings_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(theme.t("settings_save")) {
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
                        onSave(comps.hour ?? 9, comps.minute ?? 0)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct SirajAppIconBadge: View {
    let icon: SirajAppIconDefinition
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [Color(argbHex: icon.centerColor), Color(argbHex: icon.midColor), Color(argbHex: icon.edgeColor)],
                        center: UnitPoint(x: 0.5, y: 0.46),
                        startRadius: 2,
                        endRadius: size * 0.68
                    )
                )
            SirajEmblemMark(height: size * 0.62, tint: Color(argbHex: icon.emblemColor))
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .strokeBorder(Color.white.opacity(icon.isLightGround ? 0.35 : 0.16), lineWidth: 0.8)
        }
    }
}
