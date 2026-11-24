import SwiftUI
import SirajCore

struct OnboardingView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let locationService: LocationService
    var onPreviewVoice: ((String) -> Void)? = nil
    var onStopPreview: (() -> Void)? = nil
    var onRequestNotifications: (() async -> Void)? = nil

    @State private var stepIndex: Int = 0
    @State private var cityQuery: String = ""

    private let totalSteps = 6

    var body: some View {
        VStack(spacing: 0) {
            progressHeader
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)

            TabView(selection: $stepIndex) {
                OnboardingWelcomeStep(appState: appState)
                    .tag(0)
                OnboardingLanguageStep(appState: appState)
                    .tag(1)
                OnboardingLocationStep(appState: appState, locationService: locationService, cityQuery: $cityQuery)
                    .tag(2)
                OnboardingMethodStep(appState: appState)
                    .tag(3)
                OnboardingAlertsStep(
                    appState: appState,
                    onPreviewVoice: onPreviewVoice,
                    onStopPreview: onStopPreview,
                    onRequestNotifications: onRequestNotifications
                )
                .tag(4)
                OnboardingAppearanceStep(appState: appState)
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(theme.motionEnabled ? .easeInOut(duration: 0.25) : nil, value: stepIndex)

            bottomBar
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 8)
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                if stepIndex > 0 {
                    Button {
                        onStopPreview?()
                        stepIndex -= 1
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: theme.isRTL ? "chevron.right" : "chevron.left")
                                .font(.system(size: 13, weight: .bold))
                            Text(theme.t("back"))
                                .font(theme.scaledFont(size: 13.5, weight: .semibold))
                        }
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(theme.primary.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 68, height: 30)
                }

                Spacer()

                Text(
                    theme.tf(
                        "onboarding_polish_step_of",
                        theme.digits("\(stepIndex + 1)"),
                        theme.digits("\(totalSteps)")
                    )
                )
                .font(theme.scaledFont(size: 12.5, weight: .bold))
                .foregroundStyle(theme.onSurfaceVariant)

                Spacer()

                Color.clear.frame(width: 68, height: 30)
            }

            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { idx in
                    Capsule()
                        .fill(idx <= stepIndex ? theme.primary : theme.outlineVariant.opacity(0.5))
                        .frame(height: 4)
                }
            }
        }
    }

    private var bottomBar: some View {
        Button {
            onStopPreview?()
            if stepIndex < totalSteps - 1 {
                stepIndex += 1
            } else {
                appState.completeOnboarding()
            }
        } label: {
            Text(stepIndex == totalSteps - 1 ? theme.t("onboarding_get_started") : theme.t("next"))
                .font(theme.scaledFont(size: 16, weight: .bold))
                .foregroundStyle(theme.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.primary))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(stepIndex == totalSteps - 1 ? "onboarding_finish" : "onboarding_next")
    }
}
