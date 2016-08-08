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
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var tapPinsLabel: UILabel!
    
   // @IBOutlet weak var mapViewTop: NSLayoutConstraint!
    @IBOutlet weak var mapViewBottom: NSLayoutConstraint!
        
    var mapViewTopStartPosition: CGFloat = 0
    var mapViewBottomStartPosition: CGFloat = 0
    
    
    var selectedLocation: CLLocationCoordinate2D?
    var selectedPin: Pin?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        //mapViewTopStartPosition = mapViewTop.constant       // store initial value of the mapView top margin constraint
        mapViewBottomStartPosition = mapViewBottom.constant // store initial value of the mapView bottom margin constraint
        getPins()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
            editButton.title = "Edit"
            //mapViewTop.constant = self.mapViewTopStartPosition
            mapViewBottom.constant = self.mapViewBottomStartPosition
            tapPinsLabel.hidden = true
            
        activityIndicator.startAnimating()
    }
    
    /********************************************************************************************************
     * Process the "Edit" button                                                                            *
     ********************************************************************************************************/
    @IBAction func edit(sender: AnyObject) {
        switch editButton.title! {
        case "Edit":
            editButton.title = "Done"
            
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                //self.mapViewTop.constant -= self.tapPinsLabel.frame.height
                self.mapViewBottom.constant -= self.tapPinsLabel.frame.height
                self.tapPinsLabel.hidden = true
                self.view.layoutIfNeeded()
                }, completion: nil)

            tapPinsLabel.hidden = false
        
        case "Done":
            editButton.title = "Edit"
            //self.mapViewTop.constant = self.mapViewTopStartPosition
            self.mapViewBottom.constant = self.mapViewBottomStartPosition
                        tapPinsLabel.hidden = true
        
        default:
            print("error")
        }
    }
    /********************************************************************************************************
     * Let the FetchedResultsController handle showing annotations                                          *
     ********************************************************************************************************/
    /*func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        let pin = anObject as! Pin
        print("pin in did change object = \(pin.latitude), \(pin.longitude)")
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude as Double, longitude: pin.longitude as Double)
        switch type {
        case .Insert:
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
        //case .Delete:
            /*let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            print("annotation to remove = \(annotation.coordinate.latitude), \(annotation.coordinate.longitude) ")
            mapView.removeAnnotation(annotation)*/
            
            
            
        default:
            return
        }
    }*/
    
    
    /********************************************************************************************************
     * Add a pin after a long touch                                                                         *
     ********************************************************************************************************/
    func handleLongPressGesture(sender: AnyObject) {
        if sender.state == UIGestureRecognizerState.Began && editButton.title == "Edit" {
            let touchLocation = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Latitude   : coordinate.latitude as NSNumber,
                Pin.Keys.Longitude  : coordinate.longitude as NSNumber
            ]
            
            print ("pin lat,long to store = \(dictionary["latitude"]), \(dictionary["longitude"])")
            
            selectedPin = Pin(dictionary: dictionary, context: SharedMethod.sharedContext)
            CoreDataStackManager.sharedInstance.saveContext()
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            
            // start to add photos
            
            SharedNetworkServices.sharedInstance.savePhotos(Constants.maxNumOfPhotos, pin: selectedPin!) {(inner: () throws -> Bool) -> Void in
                do {
                    //print("in test inner")
                    try inner() // if successful continue else catch the error code
                } catch let error {
                    SharedMethod.showAlert(error, title: "Error", viewController: self)
                }
            }
        }
    }
    
    /********************************************************************************************************
     * A pin has been selected, go to the Photos VC and pass the pin location                               *
     ********************************************************************************************************/
    func mapView(mapView: MKMapView,
        didSelectAnnotationView view: MKAnnotationView) {
        
        selectedLocation = view.annotation!.coordinate
        print("selected location = \(selectedLocation)")
        
        switch editButton.title! {
        
        case "Edit":
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumVC")
                as! PhotoAlbumVC
            if let pin = getPinFromCoordinate(selectedLocation!, frc: self.onePinFetchedResultsController) {
                controller.selectedPin = pin
            }
            print("calling photoalbumVC")
            self.navigationController!.pushViewController(controller, animated: true)
            mapView.deselectAnnotation(view.annotation, animated: false)
            break
            
        case "Done":    // case: "Done"
            if let pin = getPinFromCoordinate(selectedLocation!, frc: self.onePinFetchedResultsController) {
                print("pin to delete from Core Data = \(pin.latitude), \(pin.longitude)")
                SharedMethod.sharedContext.deleteObject(pin)
                CoreDataStackManager.sharedInstance.saveContext()
                mapView.removeAnnotation(view.annotation!)
                break
            }
        default:
            return
        
        }
        
        
    }
    /********************************************************************************************************
     * Return the pin of a location. Complicated because don't want to == a Double as precision may be off  *
     ********************************************************************************************************/
    func getPinFromCoordinate(coordinate: CLLocationCoordinate2D, frc: NSFetchedResultsController) -> Pin? {
        
        // predicates inspired by: http://stackoverflow.com/questions/2026649/nspredicate-dont-work-with-double-values-f
        let epsilon:Double = DBL_EPSILON
        let firstPredicate = NSPredicate(format: "latitude <= %lf and latitude => %lf",coordinate.latitude as Double + epsilon, coordinate.latitude as Double - epsilon)
        let secondPredicate = NSPredicate(format: "longitude <= %lf and longitude => %lf",coordinate.longitude as Double + epsilon, coordinate.longitude as Double - epsilon)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
        onePinFetchedResultsController.fetchRequest.predicate = predicate
        
        do {
            try frc.performFetch()
            let fetchedObjects = frc.fetchedObjects
            if (fetchedObjects!.count == 1) {
                for pin in fetchedObjects as! [Pin] {
                    return pin
                }
            } else {
                print("\(fetchedObjects!.count) not 1 pin(s) returned")
            }
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
        return nil
    }
    
    
    
    func getPins() {
        do {
            try self.allPinsFetchedResultsController.performFetch()
            let fetchedObjects = allPinsFetchedResultsController.fetchedObjects
            if (fetchedObjects!.count > 0) {
                var annotations = [MKPointAnnotation]()
                for pin in fetchedObjects as! [Pin] {
                    let annotation = MKPointAnnotation()
                    let coordinate  = CLLocationCoordinate2D(latitude: pin.latitude as Double, longitude: pin.longitude as Double)
                    annotation.coordinate = coordinate
                    annotations.append(annotation)
                }
                mapView.addAnnotations(annotations)
            } else {
                print("No Pins")
            }
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
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
    
    /********************************************************************************************************
     * Dequeue deleted pins                                                                                 *
     ********************************************************************************************************/
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

