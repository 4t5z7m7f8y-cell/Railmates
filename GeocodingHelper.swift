//
//  GeocodingHelper.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import Foundation
import MapKit
import SwiftUI
import CoreLocation

func geocode(locationName: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
    Task {
        do {
            guard let request = MKGeocodingRequest(addressString: locationName) else {
                print("Failed to create geocoding request for: \(locationName)")
                completion(nil)
                return
            }
            let mapItems = try await request.mapItems
            print("Got \(mapItems.count) map items")
            if let coordinate = mapItems.first?.location.coordinate {
                print("Coordinate: \(coordinate.latitude), \(coordinate.longitude)")
                completion(coordinate)
            } else {
                print("No coordinate found in first map item")
                completion(nil)
            }
        } catch {
            print("Geocoding error: \(error)")
            completion(nil)
        }
    }
}
