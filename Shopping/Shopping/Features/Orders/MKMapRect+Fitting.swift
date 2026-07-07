import MapKit

extension MKMapRect {
    init(fitting coordinates: [CLLocationCoordinate2D]) {
        self = coordinates
            .map { MKMapPoint($0) }
            .map { MKMapRect(x: $0.x, y: $0.y, width: 1, height: 1) }
            .reduce(.null) { $0.union($1) }
    }

    func padded(by fraction: Double) -> MKMapRect {
        insetBy(
            dx: -size.width * fraction,
            dy: -size.height * fraction
        )
    }
}
