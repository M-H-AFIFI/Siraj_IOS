import Foundation

public enum QiblaMath {
    public static let makkah = Coordinates(latitude: 21.4225241, longitude: 39.8261818)
    private static let earthRadiusKm = 6371.0088

    /// Degrees clockwise from true north (0..<360).
    public static func bearing(from coordinates: Coordinates) -> Double {
        let lonDelta = DoubleUtil.toRadians(makkah.longitude) - DoubleUtil.toRadians(coordinates.longitude)
        let latRad = DoubleUtil.toRadians(coordinates.latitude)
        let term1 = sin(lonDelta)
        let term2 = cos(latRad) * tan(DoubleUtil.toRadians(makkah.latitude))
        let term3 = sin(latRad) * cos(lonDelta)
        let angle = atan2(term1, term2 - term3)
        return DoubleUtil.unwindAngle(DoubleUtil.toDegrees(angle))
    }

    /// Great-circle Haversine distance to the Kaaba in kilometers.
    public static func distanceKm(from coordinates: Coordinates) -> Double {
        let dLat = DoubleUtil.toRadians(makkah.latitude - coordinates.latitude)
        let dLon = DoubleUtil.toRadians(makkah.longitude - coordinates.longitude)
        let lat1 = DoubleUtil.toRadians(coordinates.latitude)
        let lat2 = DoubleUtil.toRadians(makkah.latitude)
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(max(0, 1 - a)))
        return earthRadiusKm * c
    }
}
