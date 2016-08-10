//
//  TravelLocationsVC.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 1/29/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsVC: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    
    // MARK: IBOutlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var tapPinsLabel: UILabel!
    
    @IBOutlet weak var mapViewBottom: NSLayoutConstraint!
    
    // MARK: Vars
 
    var mapViewTopStartPosition: CGFloat = 0
    var mapViewBottomStartPosition: CGFloat = 0
    
    var selectedLocation: CLLocationCoordinate2D?
    var selectedPin: Pin?
    
    
    // MARK: Lazy frc's. Use two frcs rather than change predicates in code
    
    lazy var allPinsFetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Pin")
        request.sortDescriptors = []
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: SharedMethod.sharedContext,sectionNameKeyPath: nil,cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    lazy var onePinFetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Pin")
        request.sortDescriptors = []
        request.predicate = nil
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: SharedMethod.sharedContext,sectionNameKeyPath: nil,cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    
    // MARK: Init override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapViewBottomStartPosition = mapViewBottom.constant     // store initial value of the mapView bottom margin constraint
        mapViewBottom.constant = self.mapViewBottomStartPosition
        tapPinsLabel.hidden = true                              // hide the "Tap Pins to Delete" label
        
        if let pinError = getPins() { //get pins to populate map. If no data returned it is all good. If data is returned data is the NSError
            SharedMethod.showAlert(Status.codeIs.pinErrorWithCode(code: pinError.code,text: pinError.localizedDescription), title: "Error", viewController: self)
        }
    }
    
    
    // MARK: Process the "Edit / Done" button - change the map view and show the button at the bottom of the view
    
    @IBAction func edit(sender: AnyObject) {
        
        switch editButton.title! {

        case "Edit":
            editButton.title = "Done"
            self.view.layoutIfNeeded()
            tapPinsLabel.hidden = false // show the "Tap Pins to Delete" button

            // Move up the map view
            UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.mapViewBottom.constant -= self.tapPinsLabel.frame.height
                self.view.layoutIfNeeded()
                }, completion: nil)
            
        default :   // button has to be "Done"
            editButton.title = "Edit"
            self.mapViewBottom.constant = self.mapViewBottomStartPosition   // reset the map position
            tapPinsLabel.hidden = true                                      // hide the "Tap Pins to Delete" button
        }
    }
    
    
    // MARK:  Add a pin after a long touch   
    
    func handleLongPressGesture(sender: AnyObject) {
        
        if sender.state == UIGestureRecognizerState.Began && editButton.title == "Edit" {
            let touchLocation = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Latitude   : coordinate.latitude as NSNumber,
                Pin.Keys.Longitude  : coordinate.longitude as NSNumber
            ]
            selectedPin = Pin(dictionary: dictionary, context: SharedMethod.sharedContext)
            CoreDataStackManager.sharedInstance.saveContext()
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            // start to add photos
            SharedNetworkServices.sharedInstance.savePhotos(Constants.maxNumOfPhotos, pin: selectedPin!) {(inner: () throws -> Bool) -> Void in
                do {
                    try inner() // if successful continue else catch the error code
                } catch let error {
                    SharedMethod.showAlert(error, title: "Error", viewController: self)
                }
            }
        }
    }
   
    
    // MARK: didSelectAnnovationView: A pin has been selected. Either delete the pin or go to the PhotoAlbumVC
    
    func mapView(mapView: MKMapView,
        didSelectAnnotationView view: MKAnnotationView) {
        
        selectedLocation = view.annotation!.coordinate
        
        if let pin = getPinFromCoordinate(selectedLocation!, frc: self.onePinFetchedResultsController) {
        
            switch editButton.title! {
            
            case "Edit":    // got to PhotoAlbumVC
                let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumVC")
                    as! PhotoAlbumVC
                controller.selectedPin = pin
                self.navigationController!.pushViewController(controller, animated: true)
                mapView.deselectAnnotation(view.annotation, animated: false)
                break
            
            default:    // case: "Done"  - delete the pin
                SharedMethod.sharedContext.deleteObject(pin)
                CoreDataStackManager.sharedInstance.saveContext()
                mapView.removeAnnotation(view.annotation!)
                break
            }
        } else {
            SharedMethod.showAlert(Status.codeIs.pinError, title: "Error", viewController: self)
        }
    }
    
    
    // MARK: Get all pins on the map
    
    func getPins() -> NSError? {
        
        do {
            try self.allPinsFetchedResultsController.performFetch()
            let fetchedObjects = allPinsFetchedResultsController.fetchedObjects
            if fetchedObjects!.count > 0 {
                var annotations = [MKPointAnnotation]()
                for pin in fetchedObjects as! [Pin] {
                    let annotation = MKPointAnnotation()
                    let coordinate  = CLLocationCoordinate2D(latitude: pin.latitude as Double, longitude: pin.longitude as Double)
                    annotation.coordinate = coordinate
                    annotations.append(annotation)
                }
                mapView.addAnnotations(annotations)
            }
        } catch let error as NSError {
            return error
        }
        return nil
    }
    
    
    // MARK: Return the pin of a location.
    
    func getPinFromCoordinate(coordinate: CLLocationCoordinate2D, frc: NSFetchedResultsController) -> Pin? {
        // Saving and retrieving of coordinates can mismatch due to double precision processing (e.g. may drop least significant decimal digit)
        // Use a bounding approach to get the pin using a map coordinate
        
        // Approach inspired by: http://stackoverflow.com/questions/2026649/nspredicate-dont-work-with-double-values-f
        let epsilon:Double = DBL_EPSILON
        let firstPredicate = NSPredicate(format: "latitude <= %lf and latitude => %lf",coordinate.latitude as Double + epsilon, coordinate.latitude as Double - epsilon)
        let secondPredicate = NSPredicate(format: "longitude <= %lf and longitude => %lf",coordinate.longitude as Double + epsilon, coordinate.longitude as Double - epsilon)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
        onePinFetchedResultsController.fetchRequest.predicate = predicate
        
        do {                                            // fetch the pin
            try frc.performFetch()
            if (frc.fetchedObjects!.count == 1) {
                for pin in frc.fetchedObjects as! [Pin] {
                    return pin
                }
            }   // if here, pin count != 1 so pin not set, nil is returned
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
        return nil
    }
  
    
    // MARK: Map functions
    
    func mapViewDidStarthRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        mapView.alpha = 0.25
        activityIndicator.startAnimating()
        activityIndicator.hidden = false
    }

    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        mapView.alpha = 1.0
        activityIndicator.stopAnimating() 
        activityIndicator.hidden = true
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var pinOnMap = mapView.dequeueReusableAnnotationViewWithIdentifier("PinOnMap") as? MKPinAnnotationView
        if pinOnMap == nil {
            pinOnMap = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "MapPin")
        }
        else {
            pinOnMap!.annotation = annotation
        }
        return pinOnMap
    }
    
}

