import CoreLocation
import Foundation

enum ShipmentGeometry {
    static func coordinate(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        fraction t: Double
    ) -> CLLocationCoordinate2D {
        let fraction = min(max(t, 0), 1)
        let startLatitude = start.latitude.radians
        let startLongitude = start.longitude.radians
        let endLatitude = end.latitude.radians
        let endLongitude = end.longitude.radians

        let latitudeDelta = endLatitude - startLatitude
        let longitudeDelta = endLongitude - startLongitude
        let haversine = pow(sin(latitudeDelta / 2), 2)
            + cos(startLatitude) * cos(endLatitude)
            * pow(sin(longitudeDelta / 2), 2)
        let centralAngle = 2 * asin(min(1, sqrt(haversine)))

        guard centralAngle > 0.000_001 else {
            return start
        }

        let scale = sin(centralAngle)
        let startWeight = sin((1 - fraction) * centralAngle) / scale
        let endWeight = sin(fraction * centralAngle) / scale

        let x = startWeight * cos(startLatitude) * cos(startLongitude)
            + endWeight * cos(endLatitude) * cos(endLongitude)
        let y = startWeight * cos(startLatitude) * sin(startLongitude)
            + endWeight * cos(endLatitude) * sin(endLongitude)
        let z = startWeight * sin(startLatitude) + endWeight * sin(endLatitude)

        let latitude = atan2(z, sqrt(pow(x, 2) + pow(y, 2)))
        let longitude = atan2(y, x)

        return CLLocationCoordinate2D(
            latitude: latitude.degrees,
            longitude: longitude.degrees
        )
    }

    static func routeCoordinates(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        sampleCount: Int = 64
    ) -> [CLLocationCoordinate2D] {
        let count = max(sampleCount, 2)

        return (0..<count).map { index in
            coordinate(
                from: start,
                to: end,
                fraction: Double(index) / Double(count - 1)
            )
        }
    }
}

private extension Double {
    var radians: Double {
        self * .pi / 180
    }

    var degrees: Double {
        self * 180 / .pi
    }
}
