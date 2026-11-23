import SwiftUI
import SirajCore

public struct OnboardingView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let locationService: LocationService
    let onPreviewVoice: ((String) -> Void)?
    let onStopPreview: (() -> Void)?
    let onRequestNotifications: (() async -> Void)?

    @State private var stepIndex: Int = 0
    @State private var cityQuery: String = ""

    private let totalSteps = 6

    public init(
        appState: AppState,
        locationService: LocationService,
        onPreviewVoice: ((String) -> Void)? = nil,
        onStopPreview: (() -> Void)? = nil,
        onRequestNotifications: (() async -> Void)? = nil
    ) {
        self.appState = appState
        self.locationService = locationService
        self.onPreviewVoice = onPreviewVoice
        self.onStopPreview = onStopPreview
        self.onRequestNotifications = onRequestNotifications
    }

    public var body: some View {
        VStack(spacing: 0) {
            progressHeader
                .padding(.horizontal, 20)
                .padding(.top, 12)

            TabView(selection: $stepIndex) {
                OnboardingWelcomeStep()
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
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { idx in
                Capsule()
                    .fill(idx <= stepIndex ? theme.primary : theme.outlineVariant.opacity(0.5))
                    .frame(height: 4)
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if stepIndex > 0 {
                Button {
                    onStopPreview?()
                    stepIndex -= 1
                } label: {
                    Text(theme.t("back"))
                        .font(theme.scaledFont(size: 15, weight: .semibold))
                        .foregroundStyle(theme.onSurface)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(theme.surfaceVariant))
                }
                .buttonStyle(.plain)
            }

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
                    .padding(.vertical, 15)
                    .background(Capsule().fill(theme.primary))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(stepIndex == totalSteps - 1 ? "onboarding_finish" : "onboarding_next")
        }
    }
}
