//
//  ViewController.swift
//  User-Location Map
//
//  Created by NIKOLAI BORISOV on 14.04.2021.
//

import UIKit
import MapKit
import CoreLocation

class MapScreen: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var goButton: UIButton!
    
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 10_000
    var previousLocation: CLLocation?
    var directionsArray: [MKDirections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        goButton.layer.cornerRadius = goButton.frame.height / 2
        checkLocationServices()
        
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization(locationManager)
        } else {
            
        }
    }
    
    func checkLocationAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            //mapView.showsUserLocation = true
            startTrackingUserLocation()
            break
        case .denied:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .authorizedAlways:
            break
        default:
            break
        }
    }
    
    func startTrackingUserLocation() {
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterlocation(for: mapView)
    }
    
    func getCenterlocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else { return }
        let request = createDirectionRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (response, error) in
            guard let response = response else { return }
            
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate = getCenterlocation(for: mapView).coordinate
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() }
    }
    
    @IBAction func goButtonTapped(_ sender: UIButton) {
        getDirections()
    }
    
}

extension MapScreen: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization(locationManager)
    }
}

extension MapScreen: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterlocation(for: mapView)
        let geoCoder = CLGeocoder()
        
        guard let previousLocation = self.previousLocation else { return }
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center) { [weak self] (placemarks, error) in
            guard let self = self else{ return }
            
            if let _ = error {
                return
            }
            
            guard let placemark = placemarks?.first else {
                return
            }
            
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.addressLabel.text = "\(streetNumber) \(streetName)"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        render.strokeColor = .blue
        
        return render
    }
}
