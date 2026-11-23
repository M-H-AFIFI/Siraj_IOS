import CoreLocation
import Foundation
import Observation
import SirajCore

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    var isLocating: Bool = false
    var errorMessage: String?

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Place?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentPlace() async -> Place? {
        errorMessage = nil
        isLocating = true
        defer { isLocating = false }

        return await withCheckedContinuation { cont in
            self.continuation = cont
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                self.errorMessage = "location_permission_denied"
                self.finish(with: nil)
            @unknown default:
                self.finish(with: nil)
            }
        }
    }

    private func finish(with place: Place?) {
        let pending = continuation
        continuation = nil
        pending?.resume(returning: place)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard self.continuation != nil else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.requestLocation()
            case .denied, .restricted:
                self.errorMessage = "location_permission_denied"
                self.finish(with: nil)
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else {
            Task { @MainActor in self.finish(with: nil) }
            return
        }
        let coord = loc.coordinate
        Task { @MainActor in
            let geocoder = CLGeocoder()
            let placemark = try? await geocoder.reverseGeocodeLocation(loc).first
            let zoneId = Zones.plausibleZoneId(
                preferred: placemark?.timeZone?.identifier,
                latitude: coord.latitude,
                longitude: coord.longitude,
                now: Date()
            )
            let country = placemark?.isoCountryCode ?? Zones.countryOf(zoneId)
            let nearest = Cities.nearest(latitude: coord.latitude, longitude: coord.longitude)
            let cityName = placemark?.locality ?? placemark?.administrativeArea ?? nearest?.name ?? "My Location"
            let place = Place(
                latitude: coord.latitude,
                longitude: coord.longitude,
                cityName: cityName,
                cityNameAr: nearest?.nameAr,
                timeZoneId: zoneId,
                countryCode: country
            )
            self.finish(with: place)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
            self.finish(with: nil)
        }
    }
}
