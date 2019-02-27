//
//  ViewController.swift
//  MapBoxTest
//
//  Created by Jason S Foster on 2/21/19.
//  Copyright © 2019 Jason S Foster. All rights reserved.
//

import UIKit
import Mapbox
import MapboxGeocoder

class RootViewController: UIViewController {

    let mapView = MGLMapView()
    lazy var geocoder : Geocoder = {
        let accessToken = Bundle.main.infoDictionary?["MGLMapboxAccessToken"] as! String
        return Geocoder(accessToken: accessToken)
    }()
    
    private var mapDrawView : MapDrawView?
    private let searchTextField = UITextField()
    
    private var toolBar : UIToolbar!
    
    private var isDrawMode = false
    
    private var polygons = [MGLPolygon]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let toolbarHeight : CGFloat = 50
        toolBar = UIToolbar()
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.barStyle = .default
        toolBar.tintColor = .black
        toolBar.backgroundColor = .white
        self.view.addSubview(toolBar)
        
        NSLayoutConstraint.activate([
            toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant : -30.0),
            toolBar.heightAnchor.constraint(equalToConstant: toolbarHeight)
        ])
        
        // Create Toolbar Buttons
        // Sets the map into a draw mode, so we can draw polygons
        let drawBarButton = UIBarButtonItem(title: "Draw", style: .plain, target: self, action: #selector(self.drawMode))
        // View, switches the style URL
        let viewButton = UIBarButtonItem(title: "View", style: .plain, target: self, action: #selector(self.changeView))
        // Removes the drawn polygons
        let clearButton = UIBarButtonItem(title: "Clear Polygons", style: .plain, target: self, action: #selector(self.clearPolygons))
        
        toolBar.items = [drawBarButton, viewButton, clearButton]
        
        // Creates the MapBox MapView
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(mapView)
        
        // sets the constraints for the map view
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: toolBar.topAnchor)
        ])
        
        // Set up the map view
        let startingCoordinate = CLLocationCoordinate2D(latitude: 40.578679, longitude: -111.892347)
        mapView.setCenter(startingCoordinate, zoomLevel : 12, animated: false)
        
        // Sets the map view style
        // .satelliteStyleURL, .streetsStyleURL, .lightStyleURL
        mapView.styleURL = MGLStyle.streetsStyleURL
        
        // Adding two different markers the first on is the default marker, the second will be a custom one using a view
        let defaultMarker = MGLPointAnnotation()
        defaultMarker.coordinate = startingCoordinate
        defaultMarker.title = "Default"
        defaultMarker.subtitle = "This is a default marker!"
        mapView.addAnnotation(defaultMarker)
        
        let listingCoordinate = CLLocationCoordinate2D(latitude: 40.574679, longitude: -111.898347)
        let customCircleMarker = CustomMGLPointAnnotation()
        customCircleMarker.useCircle = true
        customCircleMarker.coordinate = listingCoordinate
        customCircleMarker.title = "Circle marker"
        customCircleMarker.subtitle = "This is not the default marker but a custom marker!"
        mapView.addAnnotation(customCircleMarker)
        
        // Setup the search bar view
        let searchView = UIView()
        searchView.translatesAutoresizingMaskIntoConstraints = false
        searchView.backgroundColor = .white
        view.addSubview(searchView)
        
        NSLayoutConstraint.activate([
            searchView.topAnchor.constraint(equalTo: view.topAnchor, constant : 50.0),
            searchView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchView.heightAnchor.constraint(equalToConstant: 35.0),
            searchView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.90) // 90% the width of its parent
        ])
        
        
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.placeholder = "Enter address, zip, state"
        searchView.addSubview(searchTextField)
        
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: searchView.topAnchor, constant : 0.0),
            searchTextField.leadingAnchor.constraint(equalTo: searchView.leadingAnchor, constant: 5),
            searchTextField.heightAnchor.constraint(equalTo : searchView.heightAnchor),
            searchTextField.widthAnchor.constraint(equalTo: searchView.widthAnchor, multiplier: 0.75) // 90% the width of its parent
        ])
        
        let searchButton = UIButton(type: .custom)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.setTitle("Search", for: .normal)
        searchButton.setTitleColor(.black, for: .normal)
        searchButton.titleLabel?.font = .systemFont(ofSize:12.0)
        searchButton.addTarget(self, action: #selector(self.geocode), for: .touchUpInside)
        searchView.addSubview(searchButton)
        
        NSLayoutConstraint.activate([
            searchButton.topAnchor.constraint(equalTo: searchView.topAnchor, constant : 0.0),
            searchButton.trailingAnchor.constraint(equalTo: searchView.trailingAnchor, constant: -0.5),
            searchButton.heightAnchor.constraint(equalTo : searchView.heightAnchor),
            searchButton.widthAnchor.constraint(equalTo: searchView.widthAnchor, multiplier: 0.15) // 90% the width of its parent
        ])
        
    }

    ///
    /// Sets the draw mode
    /// When the draw mode is set to true then the user will be able to draw a polygon.
    ///
    @objc func drawMode() {
        // Check the current draw mode and toggle the value
        if mapDrawView == nil {
            mapDrawView = MapDrawView(frame: CGRect(x: 0.0, y: 0.0, width: mapView.bounds.width, height: mapView.bounds.height))
            mapDrawView!.delegate = self
            self.view.addSubview(mapDrawView!)
        }
        mapDrawView!.isHidden = isDrawMode
        
        if isDrawMode {
            isDrawMode = false
        } else {
            isDrawMode = true
        }
    }
    
    ///
    /// Removes the polygons
    ///
    @objc func clearPolygons() {
        isDrawMode = false
        mapDrawView?.isHidden = true
        
        for polygon in polygons {
            mapView.removeAnnotation(polygon)
        }
    }
    
    
    ///
    /// The function will loop through various StyleURLs It is called from the Toolbar
    ///
    @objc func changeView() {
        if mapView.styleURL == MGLStyle.darkStyleURL {
            mapView.styleURL = MGLStyle.lightStyleURL
        } else if mapView.styleURL == MGLStyle.lightStyleURL {
            mapView.styleURL = MGLStyle.streetsStyleURL
        } else if mapView.styleURL == MGLStyle.streetsStyleURL {
             mapView.styleURL =  MGLStyle.darkStyleURL
        }
    }
    
    
    ///
    /// Finds the location entered
    ///
    @objc func geocode() {
        if let searchText = searchTextField.text {
            let options = ForwardGeocodeOptions(query: searchText)
            options.allowedISOCountryCodes = ["US"]
            options.allowedScopes = [.address, .place, .postalCode, .locality, .pointOfInterest]
            
            let _ = geocoder.geocode(options) { (placemarks, attribute, error) in
                // If nothing is returned then just return
                guard let placemark = placemarks?.first else {
                    return
                }
                
                let coordinate = placemark.location!.coordinate
                
                let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                self.mapView.setCenter(locationCoordinate, animated: true)
                
                //
                let locationMarker = MGLPointAnnotation()
                locationMarker.coordinate = locationCoordinate
                locationMarker.title = placemark.name
                locationMarker.subtitle = placemark.qualifiedName
                self.mapView.addAnnotation(locationMarker)
            }
            
        }
        
        // reset the search text field
        searchTextField.text = ""
    }
    
    
    ///
    /// Creats a polygon from the points created in the MapDrawView
    ///
    func addPolygonWithPoints(_ points : [CGPoint]) {
        guard points.count != 0 else { return }
        
        var latLongPoints = [CLLocationCoordinate2D]()
        for point : CGPoint in points {
            let latLng = mapView.convert(point, toCoordinateFrom: nil)
            latLongPoints.append(latLng)
        }
        
        let polygon = MGLPolygon(coordinates: latLongPoints, count: UInt(latLongPoints.count))
        mapView.addAnnotation(polygon)
        polygons.append(polygon)
    }
}


// MARK: MapDrawViewDelegate
extension RootViewController : MapDrawViewDelegate {
    func polygonFinish(points : [CGPoint]) {
        addPolygonWithPoints(points)
    }
}



// MARK: MGLMapViewDelegate
extension RootViewController : MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }
    
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // This example is only concerned with point annotations.
//        guard annotation is MGLPointAnnotation else {
//            return nil
//        }
        
        guard let pointAnnotation = annotation as? CustomMGLPointAnnotation else {
            return nil
        }
        
        if pointAnnotation.useCircle == false {
            return nil
        }
        
        
        let reuseIdentifier = "\(annotation.coordinate.longitude) - \(annotation.coordinate.latitude)"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        // If there is no view available then we need to create a new one similar to a UITableView
        if annotationView == nil {
            annotationView = MapCircle(frame:  CGRect(x: 0, y: 0, width: 30.0, height: 30.0),
                                       reuseIdentifier: reuseIdentifier,
                                       color: .green)
            
        }
        
        return annotationView
        
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        if let title = annotation.title {
            print(title! as Any)
        }
    }
    
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        return 0.5
    }
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return .white
    }
    
    func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        return UIColor(red: 59/255, green: 178/255, blue: 208/255, alpha: 1)
    }
}

