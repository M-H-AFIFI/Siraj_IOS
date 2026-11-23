import Foundation

public struct ArcMilestone: Sendable, Equatable {
    public let type: PrayerType
    public let progress: Double
    public let isPast: Bool
    public let isNext: Bool
}

public struct SolarArc: Sendable, Equatable {
    public static let sunriseOnArc = 0.18
    public static let sunsetOnArc = 0.84

    public let progress: Double
    public let isDaytime: Bool
    public let phaseKey: String
    public let milestones: [ArcMilestone]

    public static func at(_ now: Date, prayers: [PrayerTimeEntry], next: PrayerTimeEntry? = nil) -> SolarArc {
        func find(_ type: PrayerType) -> Date? { prayers.first { $0.type == type }?.time }
        let dayStart = floor(now.timeIntervalSince1970 / 86_400.0) * 86_400.0
        func fallback(_ h: Int, _ m: Int) -> Date { Date(timeIntervalSince1970: dayStart + Double(h * 3600 + m * 60)) }

        let sunrise = find(.sunrise) ?? fallback(6, 0)
        let dhuhr = find(.dhuhr) ?? fallback(12, 30)
        let asr = find(.asr) ?? fallback(16, 0)
        let maghrib = find(.maghrib) ?? fallback(18, 30)
        var fajr = find(.fajr) ?? sunrise.addingTimeInterval(-90 * 60)
        let isha = find(.isha) ?? maghrib.addingTimeInterval(90 * 60)
        if fajr > sunrise { fajr = fajr.addingTimeInterval(-86_400) }

        func isNext(_ type: PrayerType) -> Bool {
            if let next { return next.type == type }
            return prayers.filter { $0.time > now }.min { $0.time < $1.time }?.type == type
        }

        func segment(_ from: Date, _ to: Date, _ pFrom: Double, _ pTo: Double) -> Double {
            let total = max(1.0, to.timeIntervalSince(from))
            let elapsed = max(0.0, now.timeIntervalSince(from))
            return pFrom + min(1.0, max(0.0, elapsed / total)) * (pTo - pFrom)
        }

        if now >= sunrise && now < maghrib {
            let pFajr = 0.08, pDhuhr = 0.50, pIsha = 0.92
            let asrRatio = (asr > dhuhr && maghrib > asr)
                ? min(0.65, max(0.35, asr.timeIntervalSince(dhuhr) / max(1.0, maghrib.timeIntervalSince(dhuhr))))
                : 0.52
            let pAsr = min(0.74, max(0.62, pDhuhr + asrRatio * (sunsetOnArc - pDhuhr)))
            let progress: Double
            if now < dhuhr { progress = segment(sunrise, dhuhr, sunriseOnArc, pDhuhr) }
            else if now < asr { progress = segment(dhuhr, asr, pDhuhr, pAsr) }
            else { progress = segment(asr, maghrib, pAsr, sunsetOnArc) }

            let phase: String
            if now < dhuhr {
                let factor = min(1.0, max(0.0, now.timeIntervalSince(sunrise) / max(1.0, dhuhr.timeIntervalSince(sunrise))))
                phase = factor < 0.15 ? "phase_sunrise" : (factor > 0.88 ? "phase_solar_noon" : "phase_duha")
            } else if now > maghrib.addingTimeInterval(-35 * 60) {
                phase = "phase_golden_sunset"
            } else if now >= asr {
                phase = "phase_asr"
            } else if now.timeIntervalSince(dhuhr) < 45 * 60 {
                phase = "phase_solar_noon"
            } else {
                phase = "phase_dhuhr"
            }

            return SolarArc(
                progress: min(0.92, max(0.08, progress)),
                isDaytime: true,
                phaseKey: phase,
                milestones: [
                    ArcMilestone(type: .fajr, progress: pFajr, isPast: now > fajr, isNext: isNext(.fajr)),
                    ArcMilestone(type: .sunrise, progress: sunriseOnArc, isPast: now > sunrise, isNext: isNext(.sunrise)),
                    ArcMilestone(type: .dhuhr, progress: pDhuhr, isPast: now > dhuhr, isNext: isNext(.dhuhr)),
                    ArcMilestone(type: .asr, progress: pAsr, isPast: now > asr, isNext: isNext(.asr)),
                    ArcMilestone(type: .maghrib, progress: sunsetOnArc, isPast: now > maghrib, isNext: isNext(.maghrib)),
                    ArcMilestone(type: .isha, progress: pIsha, isPast: now > isha, isNext: isNext(.isha))
                ]
            )
        }

        let dawnWindow = now >= fajr && now < sunrise
        let nextFajr = (fajr > now || dawnWindow) ? fajr : fajr.addingTimeInterval(86_400)
        let prevMaghrib = maghrib > now ? maghrib.addingTimeInterval(-86_400) : maghrib
        let night = max(1.0, nextFajr.timeIntervalSince(prevMaghrib))
        let midnight = prevMaghrib.addingTimeInterval(night / 2.0)
        let tahajjud = prevMaghrib.addingTimeInterval(night * 2.0 / 3.0)
        var nightIsha = now < sunrise ? isha.addingTimeInterval(-86_400) : isha
        if nightIsha < prevMaghrib { nightIsha = nightIsha.addingTimeInterval(86_400) }

        let pMaghrib = 0.08, pMidnight = 0.50, pTahajjud = 0.72, pFajr = 0.92
        let ishaRatio = (nightIsha > prevMaghrib && midnight > nightIsha)
            ? min(0.50, max(0.20, nightIsha.timeIntervalSince(prevMaghrib) / max(1.0, midnight.timeIntervalSince(prevMaghrib))))
            : 0.35
        let pIsha = min(0.28, max(0.18, pMaghrib + ishaRatio * (pMidnight - pMaghrib)))

        let nightProgress: Double
        if now < nightIsha { nightProgress = segment(prevMaghrib, nightIsha, pMaghrib, pIsha) }
        else if now < midnight { nightProgress = segment(nightIsha, midnight, pIsha, pMidnight) }
        else if now < tahajjud { nightProgress = segment(midnight, tahajjud, pMidnight, pTahajjud) }
        else if now < nextFajr { nightProgress = segment(tahajjud, nextFajr, pTahajjud, pFajr) }
        else { nightProgress = pFajr }

        let nightFactor = min(1.0, max(0.0, now.timeIntervalSince(prevMaghrib) / night))
        let nightPhase: String
        if dawnWindow { nightPhase = "phase_true_dawn" }
        else if nightFactor > 0.92 && now < nextFajr { nightPhase = "phase_sahur" }
        else if nightFactor >= 0.66 && nightFactor <= 0.92 { nightPhase = "phase_last_third" }
        else if nightFactor >= 0.45 && nightFactor <= 0.66 { nightPhase = "phase_midnight" }
        else if now < nightIsha { nightPhase = "phase_maghrib" }
        else { nightPhase = "phase_isha" }

        return SolarArc(
            progress: min(0.92, max(0.08, nightProgress)),
            isDaytime: false,
            phaseKey: nightPhase,
            milestones: [
                ArcMilestone(type: .maghrib, progress: pMaghrib, isPast: now > prevMaghrib, isNext: isNext(.maghrib)),
                ArcMilestone(type: .isha, progress: pIsha, isPast: now > nightIsha, isNext: isNext(.isha)),
                ArcMilestone(type: .fajr, progress: pFajr, isPast: false, isNext: isNext(.fajr))
            ]
        )
    }
}
