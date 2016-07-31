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
    @IBOutlet weak var tapPinsToDeleteButton: UIButton!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    @IBOutlet weak var mapViewTop: NSLayoutConstraint!
    @IBOutlet weak var mapViewBottom: NSLayoutConstraint!
    @IBOutlet weak var tapPinsToDeleteButtonBottom: NSLayoutConstraint!
    
    var mapViewTopStartPosition: CGFloat = 0
    var mapViewBottomStartPosition: CGFloat = 0
    
    var newPin: Pin?
    
    lazy var allPinsFetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Pin")
        request.sortDescriptors = []
        let pinFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.sharedContext,sectionNameKeyPath: nil,cacheName: nil)
        pinFetchedResultsController.delegate = self
        return pinFetchedResultsController
    }()
    
    lazy var onePinFetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Pin")
        request.sortDescriptors = []
        let pinFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.sharedContext,sectionNameKeyPath: nil,cacheName: nil)
        pinFetchedResultsController.delegate = self
        return pinFetchedResultsController
    }()
    
    lazy var photoFetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Photo")
        request.sortDescriptors = [NSSortDescriptor(key: "imagepath", ascending: true)]
        request.predicate = nil
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapViewTopStartPosition = mapViewTop.constant       // store initial value of the mapView top margin constraint
        mapViewBottomStartPosition = mapViewBottom.constant // store initial value of the mapView bottom margin constraint
        
        // DO THE FOLLOWING OR NOT?
        
        //fetchedResultsController.delegate = self
        
        getPins()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tapPinsToDeleteButton.hidden = true
        tapPinsToDeleteButtonBottom.constant = tapPinsToDeleteButton.frame.height   // set just outside view
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
               
                
                self.mapViewTop.constant -= self.tapPinsToDeleteButton.frame.height
                self.mapViewBottom.constant -= self.tapPinsToDeleteButton.frame.height
                
                self.tapPinsToDeleteButton.hidden = true
                self.tapPinsToDeleteButtonBottom.constant -= self.tapPinsToDeleteButton.frame.height
                
                self.view.layoutIfNeeded()
                }, completion: nil)

            
            tapPinsToDeleteButton.hidden = false
        case "Done":
            editButton.title = "Edit"
            
            self.mapViewTop.constant = self.mapViewTopStartPosition
            self.mapViewBottom.constant = self.mapViewBottomStartPosition
            
            tapPinsToDeleteButtonBottom.constant = tapPinsToDeleteButton.frame.height   // set just outside view
            tapPinsToDeleteButton.hidden = true
        default:
            print("error")
        }
    }
    
    /********************************************************************************************************
     * Process the "Delete" button                                                                          *
     ********************************************************************************************************/
    @IBAction func deletePins(sender: AnyObject) {
        editButton.title = "Done"
    }
    
    /********************************************************************************************************
     * Add a pin after a long touch                                                                         *
     ********************************************************************************************************/
    @IBAction func handleLongPressGesture(sender: AnyObject) {
        if sender.state == UIGestureRecognizerState.Began {
            let touchLocation = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Latitude   : coordinate.latitude as NSNumber,
                Pin.Keys.Longitude  : coordinate.longitude as NSNumber
            ]
            
            print ("pin lat,long to store = \(dictionary["latitude"]), \(dictionary["longitude"])")
            
            newPin = Pin(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance.saveContext()
            var annotations = [MKPointAnnotation]()
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
            mapView.addAnnotations(annotations)
            
            // start to add photos
            
            SharedNetworkServices.sharedInstance.savePhotos(Constants.maxNumOfPhotos, pin: newPin!) {(inner: () throws -> Bool) -> Void in
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
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumVC")
            as! PhotoAlbumVC
        
        //http://stackoverflow.com/questions/2026649/nspredicate-dont-work-with-double-values-f
        
        //let firstPredicate = NSPredicate(format: "latitude == 0")
        let epsilon:Double = DBL_EPSILON
        print("lats = \(view.annotation!.coordinate.latitude + epsilon), \(view.annotation!.coordinate.latitude + epsilon)")
        let firstPredicate = NSPredicate(format: "latitude <= %lf and latitude => %lf",view.annotation!.coordinate.latitude + epsilon, view.annotation!.coordinate.latitude - epsilon)
        //let firstPredicate = NSPredicate(format: "latitude == %d", view.annotation!.coordinate.latitude)
        //let secondPredicate = NSPredicate(format: "longitude == %d", view.annotation!.coordinate.longitude)
        //let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
        //onePinFetchedResultsController.fetchRequest.predicate = NSPredicate(format:"latitude == %lf and longitude == %lf", view.annotation!.coordinate.latitude, view.annotation!.coordinate.longitude)
        
        onePinFetchedResultsController.fetchRequest.predicate = firstPredicate
        do {
            try self.onePinFetchedResultsController.performFetch()
            let fetchedObjects = onePinFetchedResultsController.fetchedObjects
            if (fetchedObjects!.count == 1) {
                for pin in fetchedObjects as! [Pin] {
                    controller.pin = pin
                }
            } else {
                print("\(fetchedObjects!.count) not 1 pin(s) returned")
            }
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
  
        /*controller.mapCenterPosition = CLLocationCoordinate2D(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)*/
        self.navigationController!.pushViewController(controller, animated: true)

    
            // START TO FETCH PHOTOS - IN PROCESS
            /*SharedNetworkServices.sharedInstance.getPhotos(Constants.maxNumOfPhotos, coordinate: (view.annotation?.coordinate)!) {(inner: () throws -> Bool) -> Void in
                do {
                    //print("in test inner")
                    try inner() // if successful continue else catch the error code
                    let controller =
                    self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumVC")
                        as! PhotoAlbumVC
                    controller.mapCenterPosition = CLLocationCoordinate2D(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
                    self.navigationController!.pushViewController(controller, animated: true)
                } catch let error {
                    SharedMethod.showAlert(error, title: "Error", viewController: self)
                }
            }*/
    }
    
    func getPins() {
        //let request = NSFetchRequest(entityName: "Pin")
        //request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        //let context = self.sharedContext
        
        do {
            //let pins = try context.executeFetchRequest(request) as! [Pin]
            try self.allPinsFetchedResultsController.performFetch()
            let fetchedObjects = allPinsFetchedResultsController.fetchedObjects
            if (fetchedObjects!.count > 0) {
                var annotations = [MKPointAnnotation]()
                for pin in fetchedObjects as! [Pin] {
                    let annotation = MKPointAnnotation()
                    let coordinate  = CLLocationCoordinate2D(latitude: pin.latitude as Double, longitude: pin.longitude as Double)
                    annotation.coordinate = coordinate
                    //print("pin in VC lat and long = \(pin.latitude), \(pin.longitude)")
                    annotations.append(annotation)
                }
                mapView.addAnnotations(annotations)
            } else {
                print("No Pins")
            }
        } catch let error as NSError {
            // failure
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

// MARK: - Core Data Stuff
    // MARK: - Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }
    
}

