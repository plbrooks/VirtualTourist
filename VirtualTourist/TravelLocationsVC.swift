
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
    
    
    // MARK: Lazy fetched results controllers
    
    // Use two frcs rather than change predicates in code
    
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
    
    
    // MARK: Init functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapViewBottomStartPosition = mapViewBottom.constant     // store initial value of the mapView bottom margin constraint
        mapViewBottom.constant = self.mapViewBottomStartPosition
        SharedMethod.setActivityIndicator("START", mapView: mapView, activityIndicator: activityIndicator)
        tapPinsLabel.hidden = true                              // hide the "Tap Pins to Delete" label
        
        do {
            try getPins()   // get pins to populate map. If no data returned it is all good. If data is returned data is the NSError
            return          // all good
        } catch {
            SharedMethod.showAlert(error, title: "Error")
        }
    }
    
    // MARK: UI Processing functions
    
    // Process the "Edit / Done" button - change the map view and show the button at the bottom of the view

    @IBAction func edit(sender: AnyObject) {
        
        switch editButton.title! {

        case "Edit":
            editButton.title = "Done"
            view.layoutIfNeeded()
            tapPinsLabel.hidden = false // show the "Tap Pins to Delete" button

            // Move up the map view
            UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.mapViewBottom.constant -= self.tapPinsLabel.frame.height
                self.view.layoutIfNeeded()
                }, completion: nil)
            
        default :   // button has to be "Done"
            editButton.title = "Edit"
            mapViewBottom.constant = self.mapViewBottomStartPosition   // reset the map position
            tapPinsLabel.hidden = true                                      // hide the "Tap Pins to Delete" button
        }
    }
    
    
    // Add a pin after a long touch
    
    func handleLongPressGesture(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .Began && editButton.title == "Edit" {
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
            SharedNetworkServices.sharedInstance.savePhotos(selectedPin!, completionHandler: {(error) in
                switch error {
                case Status.codeIs.noError:
                    break
                default:
                    SharedMethod.showAlert(error, title: "Error")
                    break
                }
            })
        }
    }
   
    
    // A pin has been selected. Either delete the pin or go to the PhotoAlbumVC
    
    func mapView(mapView: MKMapView,
        didSelectAnnotationView view: MKAnnotationView) {
        
        selectedLocation = view.annotation!.coordinate
        
        do {
            let pin = try getPinFromCoordinate(selectedLocation!, frc: onePinFetchedResultsController)
                switch editButton.title! {
                case "Edit":    // got to PhotoAlbumVC
                    let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumVC")
                        as! PhotoAlbumVC
                    controller.selectedPin = pin
                    navigationController!.pushViewController(controller, animated: true)
                    mapView.deselectAnnotation(view.annotation, animated: false)
                    break
                default:    // case: "Done"  - delete the pin
                    SharedMethod.sharedContext.deleteObject(pin!)
                    CoreDataStackManager.sharedInstance.saveContext()
                    mapView.removeAnnotation(view.annotation!)
                    break
                }
        } catch Status.codeIs.pinNotFound {
            SharedMethod.showAlert(Status.codeIs.pinNotFound, title: "Error")
        } catch {
            SharedMethod.showAlert(error, title: "Error")
        }
    }
    
    // MARK: Core Data functions
    
    // Get all pins on the map

    func getPins() throws {
        
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
            throw Status.codeIs.nserror(type: Status.ErrorTypeIs.pinError , error: error)
        }
    
    }
    
    
    // Return the pin of a location.
    
    func getPinFromCoordinate(coordinate: CLLocationCoordinate2D, frc: NSFetchedResultsController) throws -> Pin? {
        // Saving and retrieving of coordinates can mismatch due to double precision processing (e.g. may drop least significant decimal digit)
        // Use a bounding approach to get the pin using a map coordinate
        // Approach inspired by: http://stackoverflow.com/questions/2026649/nspredicate-dont-work-with-double-values-f
        
        let epsilon:Double = DBL_EPSILON
        let firstPredicate = NSPredicate(format: "latitude <= %lf and latitude => %lf",coordinate.latitude as Double + epsilon, coordinate.latitude as Double - epsilon)
        let secondPredicate = NSPredicate(format: "longitude <= %lf and longitude => %lf",coordinate.longitude as Double + epsilon, coordinate.longitude as Double - epsilon)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
        onePinFetchedResultsController.fetchRequest.predicate = predicate
        
        do {            // fetch the pin
            try frc.performFetch()
            if (frc.fetchedObjects!.count == 1) {
                for pin in frc.fetchedObjects as! [Pin] {
                    return pin
                }
            } else {    // if here, pin count != 1 so pin not set, error
                throw Status.codeIs.pinNotFound
            }
        } catch let error as NSError {
            throw Status.codeIs.nserror(type: Status.ErrorTypeIs.pinError , error: error)
        }
        return nil
    
    }
  
    
    // MARK: Map functions
    
    func mapViewDidStartRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        
        SharedMethod.setActivityIndicator("START", mapView: mapView, activityIndicator: activityIndicator)
        
    }
    
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        
        SharedMethod.setActivityIndicator("FINISH", mapView: mapView, activityIndicator: activityIndicator)
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

