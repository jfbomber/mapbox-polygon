//
//  ViewController.swift
//  MapBoxTest
//
//  Created by Jason S Foster on 2/21/19.
//  Copyright © 2019 Jason S Foster. All rights reserved.
//

import UIKit
import Mapbox

class RootViewController: UIViewController {

    let mapView = MGLMapView()
    
    private var mapDrawView : MapDrawView?
    
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
        
        /// Create Toolbar Buttons
        let drawBarButton = UIBarButtonItem(title: "Draw", style: .plain, target: self, action: #selector(self.drawMode))
        let viewButton = UIBarButtonItem(title: "View", style: .plain, target: self, action: #selector(self.changeView))
        let clearButton = UIBarButtonItem(title: "Clear Polygons", style: .plain, target: self, action: #selector(self.clearPolygons))
        
        
        toolBar.items = [drawBarButton, viewButton, clearButton]
        
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: toolBar.topAnchor)
        ])
        
        self.loadMapView()
    }

    
    func loadMapView() {
        // Puts the center of the map on a lat long on URE Headquarters
        let startingCoordinate = CLLocationCoordinate2D(latitude: 40.578679, longitude: -111.892347)
        mapView.setCenter(startingCoordinate, zoomLevel : 12, animated: false)
        
        // Sets the map view style
        // .satelliteStyleURL, .streetsStyleURL, .lightStyleURL
        mapView.styleURL = MGLStyle.streetsStyleURL
        
        
        let ureHeadquarters = MGLPointAnnotation()
        ureHeadquarters.coordinate = startingCoordinate
        ureHeadquarters.title = "URE"
        ureHeadquarters.subtitle = "Headquarters for all things URE!"
        mapView.addAnnotation(ureHeadquarters)
        
        let listingCoordinate = CLLocationCoordinate2D(latitude: 40.574679, longitude: -111.898347)
        let listingMarker = CustomMGLPointAnnotation()
        listingMarker.useCircle = true
        listingMarker.coordinate = listingCoordinate
        listingMarker.title = "Not URE"
        listingMarker.subtitle = "Not the headquarters for all things URE!"
        mapView.addAnnotation(listingMarker)
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
        
        print("map view isDrawMode:\(isDrawMode)")
        print("mapDrawView is Hidden : \(mapDrawView!.isHidden)")
        
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

extension RootViewController : MapDrawViewDelegate {
    func polygonFinish(points : [CGPoint]) {
        addPolygonWithPoints(points)
    }
}


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

