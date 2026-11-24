import Foundation

public enum CompassAccuracy: String, Sendable, Equatable {
    case high
    case medium
    case low
    case unknown
}

public enum QiblaAlignment {
    public static let enterDegrees: Double = 3.0
    public static let exitDegrees: Double = 6.0

    public static func shortestDelta(from current: Double, to target: Double) -> Double {
        var delta = (target - current).truncatingRemainder(dividingBy: 360.0)
        if delta > 180.0 { delta -= 360.0 }
        if delta < -180.0 { delta += 360.0 }
        return delta
    }

    public static func relativeBearing(qiblaBearing: Double, unwrappedAzimuth: Double) -> Double {
        var delta = (qiblaBearing + unwrappedAzimuth).truncatingRemainder(dividingBy: 360.0)
        if delta > 180.0 { delta -= 360.0 }
        if delta < -180.0 { delta += 360.0 }
        return delta
    }

    // Two thresholds avoid jittery buzzing when resting right on the edge of alignment.
    public static func isAligned(relativeBearing: Double, wasAligned: Bool) -> Bool {
        let threshold = wasAligned ? exitDegrees : enterDegrees
        return abs(relativeBearing) < threshold
    }

    public static func accuracy(fromHeadingAccuracy degrees: Double) -> CompassAccuracy {
        if degrees < 0 { return .unknown }
        if degrees <= 15 { return .high }
        if degrees <= 35 { return .medium }
        return .low
    }
}
