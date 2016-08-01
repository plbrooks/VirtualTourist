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

class PhotoAlbumVC: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {

    
    @IBOutlet weak var mapView: MKMapView!
    
    var selectedPin: Pin!
    
    lazy var photoFetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Photo")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "pin == %@",self.selectedPin)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: SharedMethod.sharedContext,sectionNameKeyPath: nil,cacheName: nil)
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        do {
            try photoFetchedResultsController.performFetch()
            //let fetchedObjects = photoFetchedResultsController.fetchedObjects
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
        photoFetchedResultsController.delegate = self
        setMap(selectedPin!)       // set up the map view of the selected annotation
        //photoList
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        let a = photoFetchedResultsController.sections?.count ?? 0
        print("number of sections = \(a)")
        return photoFetchedResultsController.sections?.count ?? 0
    }
    
    // tell the collection view how many cells to make
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // number of photos in photoList
        print("photo count = \(photoFetchedResultsController.sections![section].numberOfObjects)")
        return photoFetchedResultsController.sections![section].numberOfObjects
    }
    
    // make a cell for each cell index path
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let photo = photoFetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // get a reference to our storyboard cell
        let reuseID = "photoCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseID, forIndexPath: indexPath) as! PhotoCollectionViewCell
        cell.backgroundColor = UIColor.whiteColor() // make cell more visible in our example project
        cell.image.image = UIImage(data: photo.imageData)
        return cell
    }
    
    
    @IBAction func addNewCollection(sender: AnyObject) {
    }

    
    func setMap(center: Pin) {
        // add the one annotation to the map view
        let myAnnotation = MKPointAnnotation()
        
        let location = CLLocationCoordinate2D(latitude: selectedPin!.latitude as Double, longitude:selectedPin!.longitude as Double)
        
        myAnnotation.coordinate = location
        self.mapView.addAnnotation(myAnnotation)
        
        // do some map housekeeping - set span, center, etc.
        let span = MKCoordinateSpanMake(1.0,1.0)        // set reasonable granularity
        let region = MKCoordinateRegion(center: location , span: span ) // center map
        self.mapView.setRegion(region, animated: true)  // show the map
    }
    
    
    
}