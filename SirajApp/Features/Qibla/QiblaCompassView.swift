import CoreLocation
import Observation
import SwiftUI
import UIKit
import SirajCore

@MainActor
@Observable
final class QiblaHeadingTracker: NSObject, CLLocationManagerDelegate {
    var azimuth: Double = 0
    var accuracy: CompassAccuracy = .unknown
    var compassAvailable: Bool = CLLocationManager.headingAvailable()
    var isRunning = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 0.5
    }

    func start() {
        compassAvailable = CLLocationManager.headingAvailable()
        guard compassAvailable else { return }
        if !isRunning {
            isRunning = true
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        manager.stopUpdatingHeading()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        let acc = QiblaAlignment.accuracy(fromHeadingAccuracy: newHeading.headingAccuracy)
        Task { @MainActor in
            if heading >= 0 {
                self.azimuth = heading
            }
            self.accuracy = acc
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        false
    }
}

struct QiblaCompassView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let locationService: LocationService

    @State private var tracker = QiblaHeadingTracker()
    @State private var unwrappedAzimuth: Double = 0
    @State private var isAligned = false
    @State private var isRefreshingLocation = false
    @State private var locationError = false

    private var coordinates: Coordinates {
        Coordinates(latitude: appState.activePlace.latitude, longitude: appState.activePlace.longitude)
    }

    private var qiblaBearing: Double {
        QiblaMath.bearing(from: coordinates)
    }

    private var distanceKm: Double {
        QiblaMath.distanceKm(from: coordinates)
    }

    private var relativeBearing: Double {
        QiblaAlignment.relativeBearing(qiblaBearing: qiblaBearing, unwrappedAzimuth: unwrappedAzimuth)
    }

    private var hasFix: Bool {
        !locationError && !isRefreshingLocation
    }

    private var canAlign: Bool {
        hasFix && tracker.compassAvailable
    }

    var body: some View {
        let alignment = theme.alignmentColors
        let largeText = appState.settings.textScale >= 1.2

        ScrollView {
            VStack(spacing: 0) {
                Text(theme.t("qibla_title"))
                    .font(theme.scaledFont(size: 24, weight: .black))
                    .foregroundStyle(theme.onSurface)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                if isRefreshingLocation {
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(theme.primary)
                        Text(theme.t("qibla_getting_direction"))
                            .font(theme.scaledFont(size: 15, weight: .semibold))
                            .foregroundStyle(theme.onSurface)
                        Text(theme.t("qibla_wait_msg"))
                            .font(theme.scaledFont(size: 12.5))
                            .foregroundStyle(theme.outline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else if locationError {
                    qiblaErrorCard
                        .padding(.vertical, 20)
                } else {
                    QiblaAstrolabeDial(
                        azimuth: unwrappedAzimuth,
                        qiblaBearing: qiblaBearing,
                        relativeBearing: relativeBearing,
                        isAligned: isAligned,
                        alignmentColors: alignment
                    )

                    qiblaTurnHint(alignment: alignment)
                        .padding(.top, 12)
                }

                Spacer(minLength: 20)

                if hasFix {
                    makkahInfoCard(alignment: alignment, largeText: largeText)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 124)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .onAppear {
            unwrappedAzimuth = -tracker.azimuth
            tracker.start()
        }
        .onDisappear {
            tracker.stop()
        }
        .onChange(of: tracker.azimuth) { _, newValue in
            let delta = QiblaAlignment.shortestDelta(from: unwrappedAzimuth, to: -newValue)
            let next = unwrappedAzimuth + delta
            if theme.motionEnabled {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.92)) {
                    unwrappedAzimuth = next
                }
            } else {
                unwrappedAzimuth = next
            }
            let rb = QiblaAlignment.relativeBearing(qiblaBearing: qiblaBearing, unwrappedAzimuth: next)
            let alignedNow = canAlign && QiblaAlignment.isAligned(relativeBearing: rb, wasAligned: isAligned)
            if alignedNow && !isAligned && appState.settings.isHapticEnabled {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
            }
            if alignedNow != isAligned {
                isAligned = alignedNow
            }
        }
    }

    private func qiblaTurnHint(alignment: QiblaAlignmentColors) -> some View {
        let offDeg = theme.digits(String(Int(abs(relativeBearing).rounded())))
        let bearingDeg = theme.digits(String(Int(qiblaBearing.rounded())))

        let text: String
        let color: Color
        if !tracker.compassAvailable {
            text = theme.t("tools_qibla_no_compass", bearingDeg)
            color = theme.onSurfaceVariant
        } else if isAligned {
            text = theme.t("tools_qibla_facing")
            color = alignment.accent
        } else if relativeBearing > 0 {
            text = theme.t("tools_qibla_turn_right", offDeg)
            color = theme.onSurface
        } else {
            text = theme.t("tools_qibla_turn_left", offDeg)
            color = theme.onSurface
        }

        return Text(text)
            .font(theme.scaledFont(size: isAligned ? 17 : 15.5, weight: isAligned ? .bold : .medium))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .frame(maxWidth: .infinity, minHeight: 48)
    }

    private func makkahInfoCard(alignment: QiblaAlignmentColors, largeText: Bool) -> some View {
        let groupedDistance = Self.formatDistance(distanceKm)
        let localizedDist = theme.digits(groupedDistance)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill((isAligned ? alignment.accent : theme.primary).opacity(isAligned ? 0.15 : 0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isAligned ? alignment.accent : theme.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.t("tools_qibla_makkah"))
                            .font(theme.scaledFont(size: 14.5, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                            .lineLimit(2)
                        if distanceKm > 0 {
                            Text(theme.t("tools_qibla_distance", localizedDist))
                                .font(theme.scaledFont(size: 12.5, weight: .semibold))
                                .foregroundStyle(theme.primary)
                                .lineLimit(largeText ? 2 : 1)
                        }
                    }
                }

                Spacer(minLength: 4)

                if tracker.compassAvailable && !largeText {
                    compassAccuracyChip
                }
            }

            if tracker.compassAvailable && largeText {
                compassAccuracyChip
            }

            if tracker.compassAvailable {
                if tracker.accuracy == .low {
                    CalibrateFigureEightGuide()
                } else {
                    Text(theme.t("tools_qibla_guide"))
                        .font(theme.scaledFont(size: 12.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineSpacing(3)
                }
            }
        }
        .padding(20)
        .sirajCardSurface(cornerRadius: 24, isElevated: true)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    isAligned ? alignment.accent.opacity(0.55) : Color.clear,
                    lineWidth: isAligned ? 1.4 : 0
                )
        )
    }

    private var compassAccuracyChip: some View {
        let info: (label: String, tint: Color) = {
            switch tracker.accuracy {
            case .high: return (theme.t("tools_qibla_compass_good"), Color(hex: 0xFF12805C))
            case .medium: return (theme.t("tools_qibla_compass_fair"), Color(hex: 0xFFB7791F))
            case .low: return (theme.t("tools_qibla_compass_poor"), theme.error)
            case .unknown: return (theme.t("tools_qibla_compass_checking"), theme.outline)
            }
        }()

        return HStack(spacing: 6) {
            Circle()
                .fill(info.tint)
                .frame(width: 6, height: 6)
            Text(info.label)
                .font(theme.scaledFont(size: 11, weight: .bold))
                .foregroundStyle(info.tint)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(info.tint.opacity(0.12)))
    }

    private var qiblaErrorCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "location.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(theme.primary)
            }

            Text(theme.t("qibla_title_accurate"))
                .font(theme.scaledFont(size: 19, weight: .black))
                .foregroundStyle(theme.onSurface)
                .multilineTextAlignment(.center)

            Text(theme.t(locationService.isPermissionDenied ? "qibla_desc_permission" : "qibla_desc_failed"))
                .font(theme.scaledFont(size: 14))
                .foregroundStyle(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    isRefreshingLocation = true
                    locationError = false
                    if let place = await locationService.requestCurrentPlace() {
                        appState.updateSettings {
                            $0.cachedLocation = place
                            $0.isManualLocation = false
                        }
                    } else {
                        locationError = true
                    }
                    isRefreshingLocation = false
                }
            } label: {
                Label(
                    theme.t(locationService.isPermissionDenied ? "qibla_btn_grant_permission" : "qibla_btn_enable_location"),
                    systemImage: "location.fill"
                )
                .font(theme.scaledFont(size: 15, weight: .bold))
                .foregroundStyle(theme.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(theme.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                locationError = false
                tracker.start()
            } label: {
                Label(theme.t("retry"), systemImage: "arrow.clockwise")
                    .font(theme.scaledFont(size: 13.5, weight: .semibold))
                    .foregroundStyle(theme.outline)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .sirajCardSurface(cornerRadius: 28, isElevated: true)
    }

    private static func formatDistance(_ km: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: NSNumber(value: Int(km.rounded()))) ?? String(Int(km.rounded()))
    }
}

private struct QiblaAstrolabeDial: View {
    @Environment(\.sirajTheme) private var theme
    let azimuth: Double
    let qiblaBearing: Double
    let relativeBearing: Double
    let isAligned: Bool
    let alignmentColors: QiblaAlignmentColors

    private var gold: Color {
        Color(hex: theme.isDark ? 0xFFD4AF37 : 0xFFC59B27)
    }

    private var cardinalSpecs: [(label: String, angle: Double, isNorth: Bool)] {
        let lang = SirajLocalizer.baseLanguage(theme.language)
        switch lang {
        case "ar": return [("ش", 0, true), ("ق", 90, false), ("ج", 180, false), ("غ", 270, false)]
        case "ur": return [("ش", 0, true), ("مش", 90, false), ("ج", 180, false), ("مغ", 270, false)]
        case "tr": return [("K", 0, true), ("D", 90, false), ("G", 180, false), ("B", 270, false)]
        default: return [("N", 0, true), ("E", 90, false), ("S", 180, false), ("W", 270, false)]
        }
    }

    var body: some View {
        let dialA11y = theme.t("tools_qibla_dial_a11y", theme.digits(String(Int(qiblaBearing.rounded()))))

        ZStack {
            TimelineView(.animation(minimumInterval: isAligned && theme.motionEnabled ? 1.0 / 30.0 : 1.0)) { timeline in
                let pulse: Double = {
                    guard isAligned else { return 0.85 }
                    guard theme.motionEnabled else { return 0.85 }
                    let phase = timeline.date.timeIntervalSinceReferenceDate * (.pi / 1.2)
                    return 0.35 + 0.50 * (0.5 + 0.5 * sin(phase))
                }()

                Canvas { context, size in
                    drawAstrolabe(context: &context, size: size, alignedPulse: pulse)
                }
            }

            centerHub
        }
        .frame(width: 328, height: 328)
        .padding(6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dialA11y)
    }

    private var centerHub: some View {
        let degreeText = theme.digits("\(Int(qiblaBearing))°")
        let borderGradient: AnyShapeStyle = isAligned
            ? AnyShapeStyle(AngularGradient(
                colors: [alignmentColors.border, alignmentColors.borderLight, alignmentColors.borderDark, alignmentColors.border],
                center: .center
            ))
            : AnyShapeStyle(LinearGradient(
                colors: [theme.outlineVariant.opacity(0.65), theme.outlineVariant.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            ))

        return ZStack {
            Circle()
                .fill(isAligned ? alignmentColors.hubFill : theme.surface)
                .shadow(color: Color.black.opacity(isAligned ? 0.22 : 0.08), radius: isAligned ? 10 : 4, y: 2)
                .overlay(
                    Circle().strokeBorder(borderGradient, lineWidth: isAligned ? 2.5 : 1.2)
                )
                .animation(theme.motionEnabled ? .easeInOut(duration: 0.32) : nil, value: isAligned)

            QiblaDirectionalArrow(
                color: isAligned ? .white : theme.primary,
                shadowAlpha: isAligned ? 0.16 : (theme.isDark ? 0.35 : 0.16)
            )
            .rotationEffect(.degrees(relativeBearing))

            VStack(spacing: 1) {
                Spacer()
                Text(degreeText)
                    .font(theme.scaledFont(size: 16, weight: .black))
                    .foregroundStyle(isAligned ? .white : theme.onSurface)
                if isAligned {
                    Text(theme.t("qibla_aligned"))
                        .font(theme.scaledFont(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.22)))
                }
            }
            .padding(.bottom, 12)
        }
        .frame(width: 164, height: 164)
    }

    private func drawAstrolabe(context: inout GraphicsContext, size: CGSize, alignedPulse: Double) {
        let w = size.width
        let h = size.height
        guard w > 0, h > 0 else { return }
        let center = CGPoint(x: w / 2, y: h / 2)
        let radius = min(w, h) / 2 - 24

        // 1. Outer brass bezel ring
        let brassColors: [Color] = theme.isDark
            ? [Color(hex: 0xFFD4AF37).opacity(0.45), Color(hex: 0xFF785918).opacity(0.25), Color(hex: 0xFFF3E5AB).opacity(0.50), Color(hex: 0xFF8C6212).opacity(0.30), Color(hex: 0xFFD4AF37).opacity(0.45)]
            : [Color(hex: 0xFFC59B27).opacity(0.50), Color(hex: 0xFF996515).opacity(0.25), Color(hex: 0xFFFDE68A).opacity(0.55), Color(hex: 0xFF926712).opacity(0.35), Color(hex: 0xFFC59B27).opacity(0.50)]

        let outerBezelR = radius + 10
        let outerBezelPath = Path(ellipseIn: CGRect(x: center.x - outerBezelR, y: center.y - outerBezelR, width: outerBezelR * 2, height: outerBezelR * 2))
        context.stroke(
            outerBezelPath,
            with: .conicGradient(Gradient(colors: brassColors), center: center),
            lineWidth: 4
        )

        // Outer fine guide ring
        let fineR = radius + 4
        let finePath = Path(ellipseIn: CGRect(x: center.x - fineR, y: center.y - fineR, width: fineR * 2, height: fineR * 2))
        context.stroke(
            finePath,
            with: .color(isAligned ? alignmentColors.glow.opacity(0.45 * alignedPulse) : theme.outlineVariant.opacity(0.30)),
            lineWidth: 1
        )

        // Inner graduation rim
        let innerRimR = radius - 16
        let innerRimPath = Path(ellipseIn: CGRect(x: center.x - innerRimR, y: center.y - innerRimR, width: innerRimR * 2, height: innerRimR * 2))
        context.stroke(
            innerRimPath,
            with: .color(theme.primary.opacity(theme.isDark ? 0.25 : 0.15)),
            lineWidth: 1.2
        )

        // Top fixed gold lubber triangle
        let tipY = center.y - radius - 12
        var lubber = Path()
        lubber.move(to: CGPoint(x: center.x, y: tipY))
        lubber.addLine(to: CGPoint(x: center.x - 7, y: tipY - 11))
        lubber.addLine(to: CGPoint(x: center.x + 7, y: tipY - 11))
        lubber.closeSubpath()
        context.fill(lubber, with: .color(isAligned ? alignmentColors.accent : gold))

        // 2. 8-pointed Islamic rosette (Khatim)
        var octagram = Path()
        let innerStarR = radius * 0.38
        let outerStarR = radius * 0.54
        for i in 0..<16 {
            let r = (i % 2 == 0) ? outerStarR : innerStarR
            let rad = (Double(i) * 22.5 - 90.0) * .pi / 180.0
            let pt = CGPoint(x: center.x + CGFloat(cos(rad)) * r, y: center.y + CGFloat(sin(rad)) * r)
            if i == 0 { octagram.move(to: pt) } else { octagram.addLine(to: pt) }
        }
        octagram.closeSubpath()
        context.fill(octagram, with: .color(theme.primary.opacity(theme.isDark ? 0.08 : 0.04)))
        context.stroke(octagram, with: .color(theme.primary.opacity(theme.isDark ? 0.18 : 0.10)), lineWidth: 0.8)

        // 3. Rotating compass ticks & cardinal letters
        for deg in stride(from: 0, to: 360, by: 5) {
            let angleRad = (Double(deg) + azimuth - 90.0) * .pi / 180.0
            let cosA = CGFloat(cos(angleRad))
            let sinA = CGFloat(sin(angleRad))

            let isMajor30 = deg % 30 == 0
            let isMedium10 = deg % 10 == 0
            let tickLen: CGFloat = isMajor30 ? 16 : (isMedium10 ? 10 : 5)
            let strokeW: CGFloat = isMajor30 ? 2.5 : (isMedium10 ? 1.5 : 0.8)
            let tickColor: Color = isMajor30
                ? theme.primary.opacity(0.75)
                : (isMedium10 ? theme.primary.opacity(0.40) : theme.outlineVariant.opacity(0.30))

            var line = Path()
            line.move(to: CGPoint(x: center.x + radius * cosA, y: center.y + radius * sinA))
            line.addLine(to: CGPoint(x: center.x + (radius - tickLen) * cosA, y: center.y + (radius - tickLen) * sinA))
            context.stroke(line, with: .color(tickColor), style: StrokeStyle(lineWidth: strokeW, lineCap: .round))

            if isMajor30 {
                let dotR = radius + 3
                let dotCenter = CGPoint(x: center.x + dotR * cosA, y: center.y + dotR * sinA)
                let dotRect = CGRect(x: dotCenter.x - 1.8, y: dotCenter.y - 1.8, width: 3.6, height: 3.6)
                context.fill(Path(ellipseIn: dotRect), with: .color(Color(hex: 0xFFD4AF37).opacity(0.85)))
            }
        }

        let labelR = radius - 30
        for spec in cardinalSpecs {
            let rad = (spec.angle + azimuth - 90.0) * .pi / 180.0
            let pt = CGPoint(x: center.x + labelR * CGFloat(cos(rad)), y: center.y + labelR * CGFloat(sin(rad)))
            let color: Color = spec.isNorth
                ? Color(hex: 0xFFE65100)
                : (theme.isDark ? Color.white.opacity(0.86) : Color.black.opacity(0.75))
            let text = Text(spec.label)
                .font(.system(size: spec.isNorth ? 14 : 12.5, weight: .heavy))
                .foregroundStyle(color)
            context.draw(text, at: pt, anchor: .center)
        }

        // 4. Kaaba target vector & cube marker
        let kaabaAngle = (qiblaBearing + azimuth - 90.0) * .pi / 180.0
        let kCos = CGFloat(cos(kaabaAngle))
        let kSin = CGFloat(sin(kaabaAngle))
        let kaabaDist = radius - 2
        let kaabaCenter = CGPoint(x: center.x + kaabaDist * kCos, y: center.y + kaabaDist * kSin)

        var vector = Path()
        vector.move(to: center)
        vector.addLine(to: CGPoint(x: center.x + (radius - 18) * kCos, y: center.y + (radius - 18) * kSin))
        context.stroke(
            vector,
            with: .color(isAligned ? alignmentColors.accent.opacity(0.65) : theme.primary.opacity(0.30)),
            style: StrokeStyle(lineWidth: isAligned ? 2.5 : 1.8, dash: [6, 5])
        )

        if isAligned {
            let auraR: CGFloat = 28
            let auraRect = CGRect(x: kaabaCenter.x - auraR, y: kaabaCenter.y - auraR, width: auraR * 2, height: auraR * 2)
            context.fill(
                Path(ellipseIn: auraRect),
                with: .radialGradient(
                    Gradient(colors: [
                        alignmentColors.glow.opacity(0.70 * alignedPulse),
                        alignmentColors.hubFill.opacity(0.35 * alignedPulse),
                        .clear
                    ]),
                    center: kaabaCenter,
                    startRadius: 2,
                    endRadius: auraR
                )
            )
        }

        var kaabaCtx = context
        kaabaCtx.translateBy(x: kaabaCenter.x, y: kaabaCenter.y)
        kaabaCtx.rotate(by: .degrees(qiblaBearing + azimuth))

        let cubeRect = CGRect(x: -11, y: -11, width: 22, height: 22)
        kaabaCtx.fill(Path(cubeRect), with: .color(Color(hex: 0xFF1A1A1A)))
        kaabaCtx.fill(Path(CGRect(x: -11, y: -4.5, width: 22, height: 3.5)), with: .color(Color(hex: 0xFFFFD700)))
        kaabaCtx.fill(Path(CGRect(x: 1.5, y: 0, width: 5, height: 7)), with: .color(Color(hex: 0xFFFFC107)))
        kaabaCtx.stroke(Path(cubeRect), with: .color(isAligned ? alignmentColors.accent : Color(hex: 0xFFD4AF37)), lineWidth: 1.2)
    }
}

private struct QiblaDirectionalArrow: View {
    let color: Color
    let shadowAlpha: Double

    var body: some View {
        Canvas { context, size in
            let path = arrowPath(in: size, offset: .zero)
            let shadow = arrowPath(in: size, offset: CGPoint(x: 1.2, y: 2.2))
            context.fill(shadow, with: .color(Color.black.opacity(shadowAlpha)))
            context.fill(path, with: .color(color))
        }
    }

    private func arrowPath(in size: CGSize, offset: CGPoint) -> Path {
        let cx = size.width / 2 + offset.x
        let cy = size.height / 2 + offset.y
        let totalH: CGFloat = 60
        let headW: CGFloat = 36
        let headH: CGFloat = 24
        let stemW: CGFloat = 8.8
        let halfHeadW = headW / 2
        let halfStemW = stemW / 2
        let tipY = cy - totalH / 2
        let headBaseY = tipY + headH
        let stemBotY = tipY + totalH - halfStemW
        let botCapY = stemBotY + halfStemW
        let rTip: CGFloat = 2.4
        let rWing: CGFloat = 2.4
        let k: CGFloat = 0.5522847

        var p = Path()
        p.move(to: CGPoint(x: cx, y: tipY))
        p.addQuadCurve(to: CGPoint(x: cx - rTip * 0.7, y: tipY + rTip * 1.2), control: CGPoint(x: cx, y: tipY))
        p.addLine(to: CGPoint(x: cx - halfHeadW + rWing * 0.8, y: headBaseY - rWing * 1.2))
        p.addQuadCurve(to: CGPoint(x: cx - halfHeadW + rWing * 1.2, y: headBaseY), control: CGPoint(x: cx - halfHeadW, y: headBaseY))
        p.addLine(to: CGPoint(x: cx - halfStemW, y: headBaseY))
        p.addLine(to: CGPoint(x: cx - halfStemW, y: stemBotY))
        p.addCurve(
            to: CGPoint(x: cx, y: botCapY),
            control1: CGPoint(x: cx - halfStemW, y: stemBotY + halfStemW * k),
            control2: CGPoint(x: cx - halfStemW * k, y: botCapY)
        )
        p.addCurve(
            to: CGPoint(x: cx + halfStemW, y: stemBotY),
            control1: CGPoint(x: cx + halfStemW * k, y: botCapY),
            control2: CGPoint(x: cx + halfStemW, y: stemBotY + halfStemW * k)
        )
        p.addLine(to: CGPoint(x: cx + halfStemW, y: headBaseY))
        p.addLine(to: CGPoint(x: cx + halfHeadW - rWing * 1.2, y: headBaseY))
        p.addQuadCurve(to: CGPoint(x: cx + halfHeadW - rWing * 0.8, y: headBaseY - rWing * 1.2), control: CGPoint(x: cx + halfHeadW, y: headBaseY))
        p.addLine(to: CGPoint(x: cx + rTip * 0.7, y: tipY + rTip * 1.2))
        p.addQuadCurve(to: CGPoint(x: cx, y: tipY), control: CGPoint(x: cx, y: tipY))
        p.closeSubpath()
        return p
    }
}

private struct CalibrateFigureEightGuide: View {
    @Environment(\.sirajTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            TimelineView(.animation(minimumInterval: theme.motionEnabled ? 1.0 / 30.0 : 1.0)) { timeline in
                let phase = theme.motionEnabled
                    ? (timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.4) / 2.4) * 2.0 * .pi
                    : 0.0

                Canvas { context, size in
                    let cx = size.width / 2
                    let cy = size.height / 2
                    let a = size.width / 2 - 4
                    let b = size.height / 2 - 3
                    var loop = Path()
                    for i in 0...48 {
                        let t = Double(i) / 48.0 * 2.0 * .pi
                        let x = cx + a * CGFloat(sin(t))
                        let y = cy + 2 * b * CGFloat(sin(t) * cos(t))
                        if i == 0 { loop.move(to: CGPoint(x: x, y: y)) } else { loop.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    context.stroke(loop, with: .color(theme.error.opacity(0.45)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                    let dotX = cx + a * CGFloat(sin(phase))
                    let dotY = cy + 2 * b * CGFloat(sin(phase) * cos(phase))
                    context.fill(
                        Path(ellipseIn: CGRect(x: dotX - 3.5, y: dotY - 3.5, width: 7, height: 7)),
                        with: .color(theme.error)
                    )
                }
            }
            .frame(width: 56, height: 32)

            Text(theme.t("tools_qibla_calibrate_now"))
                .font(theme.scaledFont(size: 12.5))
                .foregroundStyle(theme.onSurface)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.error.opacity(0.08)))
    }
}
