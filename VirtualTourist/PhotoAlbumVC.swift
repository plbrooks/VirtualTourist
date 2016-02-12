//
//  PhotoAlbumVC.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/6/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumVC: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    
    @IBOutlet weak var mapView: MKMapView!
    
    var mapCenterPosition = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setMap(mapCenterPosition)       // set up the map view of the selected annotation
    }
    
    @IBAction func addNewCollection(sender: AnyObject) {
    }

    
    func setMap(center: CLLocationCoordinate2D) {
        // add the one annotation to the map view
        let myAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = center
        self.mapView.addAnnotation(myAnnotation)
        
        // do some map housekeeping - set span, center, etc.
        let span = MKCoordinateSpanMake(1.0,1.0)        // set reasonable granularity
        let region = MKCoordinateRegion(center: center , span: span ) // center map
        self.mapView.setRegion(region, animated: true)  // show the map
    }
    
    
    
}