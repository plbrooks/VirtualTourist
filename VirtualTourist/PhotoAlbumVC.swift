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
    @IBOutlet weak var collectionView: UICollectionView!
    
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
    
    override func viewWillLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let space: CGFloat = 7
        layout.minimumLineSpacing = space
        layout.minimumInteritemSpacing = space
        //let width = floor(self.collectionView.frame.size.width/3 - 2*space)
        //print("viewDidLayoutSubviews frame size width = \(self.collectionView.frame.size.width), cell width = \(width)")
        //layout.itemSize = CGSize(width: width, height: width)
        layout.invalidateLayout()
        collectionView.collectionViewLayout = layout
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return photoFetchedResultsController.sections?.count ?? 0
    }
    
    // tell the collection view how many cells to make
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // number of photos in photoList
        //print("photo count = \(photoFetchedResultsController.sections![section].numberOfObjects)")
        return photoFetchedResultsController.sections![section].numberOfObjects
    }
    
    // make a cell for each cell index path
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let photo = photoFetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // get a reference to our storyboard cell
        let reuseID = "photoCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseID, forIndexPath: indexPath) as! PhotoCollectionViewCell
        cell.backgroundColor = UIColor.greenColor() // make cell more visible in our example project
        cell.image.image = UIImage(data: photo.imageData)
        //print("cellforitematindexpath framewidth = \(self.view.frame.size.width), cell width = \(cell.frame.width)")
        cell.contentView.layoutIfNeeded()
        cell.contentView.layoutSubviews()
        return cell
    }
  
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let numberOfCellsPerRow: CGFloat = 3.0
        let space:CGFloat = 7.0
        let cellwidth: CGFloat = self.view.frame.size.width/numberOfCellsPerRow - space*(numberOfCellsPerRow*2)
        //print("sizeforitematindexpath  framesizewidth = \(width), cell width = \(cellwidth)")
        return CGSizeMake(cellwidth, cellwidth)
    }
    
    /*func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        //let leftRightInset = self.view.frame.size.width / 14.0
        //return UIEdgeInsetsMake(0, leftRightInset, 0, leftRightInset)
    }*/
  
    
    
    
    
    
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