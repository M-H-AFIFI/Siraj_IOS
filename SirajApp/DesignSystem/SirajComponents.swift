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
    var color: Color = .white

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(color)
            .contentTransition(theme.motionEnabled ? .numericText(countsDown: true) : .identity)
            .animation(theme.motionEnabled ? .easeInOut(duration: 0.22) : nil, value: text)
            .environment(\.layoutDirection, .leftToRight)
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
