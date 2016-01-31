//
//  TravelLocationsVC.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 1/29/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsVC: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tapPinsToDeleteButton: UIButton!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
         tapPinsToDeleteButton.hidden = true
    }

    /********************************************************************************************************
     * Set up annotation visuals                                                                            *
     ********************************************************************************************************/
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            //pinView!.pinTintColor = UIColor.redColor()
            //pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }

    @IBAction func edit(sender: AnyObject) {
        print("here")
        tapPinsToDeleteButton.hidden = false
    }
    
    /********************************************************************************************************
     * When the map starts renders show the activity indicator                                              *
     ********************************************************************************************************/
    func mapViewDidStarthRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        mapView.alpha = 0.25
        activityIndicator.startAnimating()
        activityIndicator.hidden = false
    }

    
    /********************************************************************************************************
     * Once the map finishes rendering stop the activity indicator                                           *
     ********************************************************************************************************/
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        mapView.alpha = 1.0
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
    }

}

