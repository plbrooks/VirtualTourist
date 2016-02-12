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
                Pin.Keys.Latitude   : coordinate.latitude,
                Pin.Keys.Longitude  : coordinate.longitude
            ]
            let _ = Pin(dictionary: dictionary, context: sharedContext)
            print("Creating pin at location \(coordinate)")
            CoreDataStackManager.sharedInstance.saveContext()
            
            var annotations = [MKPointAnnotation]()
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
            mapView.addAnnotations(annotations)
            
            
            // START TO ADD OR FETCH PHOTOS
            
            

            
            
            
        }
    }
    
    /********************************************************************************************************
     * A pin has been selected, go to the Photos VC and pass the pin location                               *
     ********************************************************************************************************/
    func mapView(mapView: MKMapView,
        didSelectAnnotationView view: MKAnnotationView) {
        let controller =
        storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumVC")
            as! PhotoAlbumVC
            controller.mapCenterPosition = CLLocationCoordinate2D(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        self.navigationController!.pushViewController(controller, animated: true)
            
        // START TO ADD OR FETCH PHOTOS
            var photoLocations = [""]           // array of document locations
            SharedMethod.getImagesFromFlickr(Constants.maxNumOfPhotos) {(inner: () throws -> Bool) -> Void in
                do {
                    try inner() // if successful continue else catch the error code
                } catch let error {
                    SharedMethod.showAlert(error, title: "Error", viewController: self)
                }
            }
            
            
            
            
    }
    
    func getPins() {
        
        let request = NSFetchRequest(entityName: "Pin")
        request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        let context = self.sharedContext
        
        do {
            let pins = try context.executeFetchRequest(request) as! [Pin]
            if (pins.count > 0) {
                var annotations = [MKPointAnnotation]()
                for pin: Pin in pins {
                    let annotation = MKPointAnnotation()
                    let coordinate  = CLLocationCoordinate2D(latitude: pin.latitude as Double, longitude: pin.longitude as Double)
                    annotation.coordinate = coordinate
                    annotations.append(annotation)
                }
                mapView.addAnnotations(annotations)
            } else {
                print("No Users")
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
    
    // Step 1 - Add the lazy fetchedResultsController property. See the reference sheet in the lesson if you
    // want additional help creating this property.
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    



}

