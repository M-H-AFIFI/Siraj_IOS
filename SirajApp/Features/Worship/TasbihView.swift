import SwiftUI
import SirajCore

struct TasbihView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let worshipStore: WorshipStore

    @State private var showCustomDialog = false
    @State private var customDhikrText = ""
    @State private var showResetAlert = false
    @State private var counterScale: CGFloat = 1.0
    @State private var rippleRadius: CGFloat = 0.28
    @State private var rippleOpacity: Double = 0.0
    @Namespace private var goalPillNamespace

    private var gold: Color {
        Color(hex: theme.isDark ? 0xFFD4AF37 : 0xFFC59B27)
    }

    private var isGoalCompleted: Bool {
        worshipStore.tasbih.count > 0 && worshipStore.tasbih.goal > 0 && worshipStore.tasbih.count % worshipStore.tasbih.goal == 0
    }

    private var goalProgress: Double {
        guard worshipStore.tasbih.goal > 0 else { return 0 }
        return min(1.0, max(0.0, Double(worshipStore.tasbih.count) / Double(worshipStore.tasbih.goal)))
    }

    var body: some View {
        let current = worshipStore.currentTasbihDhikr
        let allDhikrs = worshipStore.allTasbihDhikrs
        let translation = current.translation(language: theme.language)
        let beadRotation = Double(worshipStore.tasbih.count) * (360.0 / 33.0)

        ZStack {
            LinearGradient(
                colors: [theme.primary.opacity(0.08), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 12)

                // Dhikr Carousel
                HStack(spacing: 8) {
                    Button {
                        worshipStore.previousTasbihDhikr()
                    } label: {
                        Image(systemName: theme.isRTL ? "chevron.right" : "chevron.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(theme.primary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.t("previous"))

                    Text(current.arabic)
                        .font(theme.amiriFont(size: current.arabic.count > 24 ? 26 : 32, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)

                    Button {
                        worshipStore.nextTasbihDhikr()
                    } label: {
                        Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(theme.primary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.t("next"))
                }

                if !current.transliteration.isEmpty {
                    Text(current.transliteration)
                        .font(theme.scaledFont(size: 15, weight: .heavy))
                        .foregroundStyle(theme.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(theme.primaryContainer.opacity(0.35))
                        )
                        .padding(.top, 10)
                }

                if !translation.isEmpty {
                    Text(translation)
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.outline.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }

                goalPresetRow
                    .padding(.top, 16)

                Spacer(minLength: 16)

                counterOrb(beadRotation: beadRotation)

                Spacer(minLength: 16)

                bottomControls
                    .padding(.bottom, 112)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle(theme.t("tasbih_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(Array(allDhikrs.enumerated()), id: \.element.id) { idx, item in
                        Button {
                            worshipStore.selectTasbihDhikr(at: idx)
                        } label: {
                            HStack {
                                Text(item.arabic)
                                if worshipStore.tasbih.currentDhikrIndex == idx {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    Divider()
                    Button {
                        customDhikrText = ""
                        showCustomDialog = true
                    } label: {
                        Label(theme.t("tasbih_add_custom"), systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(theme.onSurface)
                }
                .accessibilityLabel(theme.t("tools_tasbih_choose_dhikr"))
            }
        }
        .alert(theme.t("tasbih_add_custom"), isPresented: $showCustomDialog) {
            TextField(theme.t("tasbih_arabic_label"), text: $customDhikrText)
            Button(theme.t("settings_cancel"), role: .cancel) {}
            Button(theme.t("settings_save")) {
                worshipStore.addCustomTasbihDhikr(customDhikrText)
            }
        }
        .alert(theme.t("tasbih_reset_title"), isPresented: $showResetAlert) {
            Button(theme.t("settings_cancel"), role: .cancel) {}
            Button(theme.t("tools_tasbih_reset_confirm"), role: .destructive) {
                worshipStore.resetTasbihRound()
            }
        } message: {
            Text(theme.t("tools_tasbih_reset_body"))
        }
    }

    private var goalPresetRow: some View {
        HStack(spacing: 8) {
            ForEach(TasbihDhikr.goalPresets, id: \.self) { goal in
                let selected = worshipStore.tasbih.goal == goal
                Button {
                    if theme.motionEnabled {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            worshipStore.setTasbihGoal(goal)
                        }
                    } else {
                        worshipStore.setTasbihGoal(goal)
                    }
                } label: {
                    Text(theme.digits(String(goal)))
                        .font(theme.scaledFont(size: 13.5, weight: .bold))
                        .foregroundStyle(selected ? theme.onPrimary : theme.onSurface)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if selected {
                                Capsule()
                                    .fill(theme.primary)
                                    .shadow(color: theme.primary.opacity(0.4), radius: 6, y: 2)
                                    .matchedGeometryEffect(id: "tasbihGoalPill", in: goalPillNamespace)
                            } else {
                                Capsule()
                                    .fill(theme.isGlass ? Color.clear : theme.surfaceVariant.opacity(0.45))
                                    .overlay(Capsule().strokeBorder(theme.outlineVariant.opacity(0.45), lineWidth: 1))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 320)
    }

    private func counterOrb(beadRotation: Double) -> some View {
        let countStr = theme.digits(String(worshipStore.tasbih.count))
        let goalStr = theme.digits(String(worshipStore.tasbih.goal))
        let accent = isGoalCompleted ? gold : theme.primary

        return Button {
            worshipStore.incrementTasbih(
                haptics: appState.settings.isHapticEnabled,
                sound: appState.settings.isSoundEnabled
            )
            triggerTapFeedback()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(isGoalCompleted ? 0.22 : 0.14), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 155
                        )
                    )

                // Expanding shockwave ripple
                if rippleOpacity > 0.01 {
                    Circle()
                        .stroke(theme.primary.opacity(rippleOpacity), lineWidth: 2.5)
                        .scaleEffect(rippleRadius)
                }

                // Orbital 33-bead ring
                TasbihBeadRingCanvas(
                    count: worshipStore.tasbih.count,
                    isGoalCompleted: isGoalCompleted,
                    primaryColor: theme.primary,
                    goldColor: gold
                )
                .rotationEffect(.degrees(-beadRotation))
                .animation(
                    theme.motionEnabled ? .spring(response: 0.36, dampingFraction: 0.72) : nil,
                    value: beadRotation
                )
                .padding(10)

                // Inner goal progress ring
                ZStack {
                    Circle()
                        .stroke(theme.primary.opacity(0.08), lineWidth: 9)
                    Circle()
                        .trim(from: 0, to: goalProgress)
                        .stroke(accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(theme.motionEnabled ? .easeOut(duration: 0.18) : nil, value: goalProgress)
                }
                .padding(38)

                // Count readout
                VStack(spacing: 2) {
                    Text(countStr)
                        .font(.system(size: countStr.count > 2 ? 68 : 88, weight: .black))
                        .foregroundStyle(isGoalCompleted ? gold : theme.onSurface)
                        .contentTransition(.numericText(countsDown: false))
                        .animation(theme.motionEnabled ? .easeOut(duration: 0.14) : nil, value: worshipStore.tasbih.count)

                    Text("/ \(goalStr)")
                        .font(theme.scaledFont(size: 20, weight: .bold))
                        .foregroundStyle(isGoalCompleted ? gold.opacity(0.85) : theme.primary.opacity(0.65))
                        .environment(\.layoutDirection, .leftToRight)

                    if isGoalCompleted {
                        Text(theme.t("tasbih_goal_reached"))
                            .font(theme.scaledFont(size: 12, weight: .black))
                            .foregroundStyle(gold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(gold.opacity(0.16)))
                            .overlay(Capsule().strokeBorder(gold.opacity(0.6), lineWidth: 1))
                            .padding(.top, 6)
                    }
                }
            }
            .frame(maxWidth: 316)
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(counterScale)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.t("tools_tasbih_counter_a11y", countStr, goalStr))
        .accessibilityHint(theme.t("tools_tasbih_count_action"))
    }

    private var bottomControls: some View {
        let todayCount = theme.digits(String(worshipStore.tasbih.todayTotal))
        return HStack(spacing: 16) {
            Button {
                showResetAlert = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(worshipStore.tasbih.count > 0 ? theme.onSurface : theme.outline.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(theme.surfaceVariant.opacity(0.7)))
            }
            .buttonStyle(.plain)
            .disabled(worshipStore.tasbih.count == 0)
            .accessibilityLabel(theme.t("tools_tasbih_reset"))

            Spacer()

            Text(theme.t("tasbih_today", todayCount))
                .font(theme.scaledFont(size: 13.5, weight: .bold))
                .foregroundStyle(theme.onSurface)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .sirajCardSurface(cornerRadius: 20)

            Spacer()

            Button {
                appState.updateSettings { $0.isSoundEnabled.toggle() }
            } label: {
                Image(systemName: appState.settings.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.onSurface)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(theme.surfaceVariant.opacity(0.7)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(theme.t(appState.settings.isSoundEnabled ? "tools_tasbih_sound_off" : "tools_tasbih_sound_on"))
        }
    }

    private func triggerTapFeedback() {
        guard theme.motionEnabled else { return }
        rippleRadius = 0.28
        rippleOpacity = 0.65
        withAnimation(.easeOut(duration: 0.42)) {
            rippleRadius = 1.12
            rippleOpacity = 0.0
        }
        withAnimation(.easeOut(duration: 0.06)) {
            counterScale = 1.04
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(65))
            withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
                counterScale = 1.0
            }
        }
    }
}

private struct TasbihBeadRingCanvas: View {
    let count: Int
    let isGoalCompleted: Bool
    let primaryColor: Color
    let goldColor: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let orbitRadius = min(size.width, size.height) / 2 - 14

            let trackRect = CGRect(x: center.x - orbitRadius, y: center.y - orbitRadius, width: orbitRadius * 2, height: orbitRadius * 2)
            context.stroke(Path(ellipseIn: trackRect), with: .color(primaryColor.opacity(0.12)), lineWidth: 1.5)

            let cycleComplete = count > 0 && count % 33 == 0
            let currentIdx = cycleComplete ? 32 : (count % 33)

            for i in 0..<33 {
                let rad = (Double(i) * (360.0 / 33.0) - 90.0) * .pi / 180.0
                let bx = center.x + orbitRadius * CGFloat(cos(rad))
                let by = center.y + orbitRadius * CGFloat(sin(rad))

                let isPassed = isGoalCompleted || cycleComplete || (i <= currentIdx && count > 0)
                let isCurrent = (isGoalCompleted || cycleComplete) ? true : (i == currentIdx && count > 0)
                let isImam = i == 0

                let r: CGFloat = isImam ? 6.5 : (isCurrent ? 6.0 : (isPassed ? 4.5 : 3.5))

                if isCurrent || isImam || isGoalCompleted {
                    let glowR = r * 1.8
                    context.fill(
                        Path(ellipseIn: CGRect(x: bx - glowR, y: by - glowR, width: glowR * 2, height: glowR * 2)),
                        with: .color((isGoalCompleted ? goldColor : primaryColor).opacity(isGoalCompleted ? 0.45 : 0.35))
                    )
                }

                let beadColor: Color = isGoalCompleted
                    ? goldColor
                    : (isCurrent ? primaryColor : (isPassed ? primaryColor.opacity(0.85) : primaryColor.opacity(0.20)))
                context.fill(
                    Path(ellipseIn: CGRect(x: bx - r, y: by - r, width: r * 2, height: r * 2)),
                    with: .color(beadColor)
                )

                if isPassed || isCurrent || isImam || isGoalCompleted {
                    let hr = r * 0.35
                    let hx = bx - r * 0.3
                    let hy = by - r * 0.3
                    context.fill(
                        Path(ellipseIn: CGRect(x: hx - hr, y: hy - hr, width: hr * 2, height: hr * 2)),
                        with: .color(.white.opacity(0.65))
                    )
                }
            }
        }
    }
}
