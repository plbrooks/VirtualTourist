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
    //var photosDownloadIsInProcess: Bool = false     // set in SharedMethod
    var numberOfFetchedObjects = 0
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths:  [NSIndexPath]!
    var updatedIndexPaths:  [NSIndexPath]!
    
    lazy var photoFetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Photo")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "pin == %@",self.selectedPin)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: SharedMethod.sharedContext,sectionNameKeyPath: nil,cacheName: nil)
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        print("inviewdidLoad")
        super.viewDidLoad()
        mapView.delegate = self
        setMap(selectedPin!)       // set up the map view of the selected annotation
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        photoFetchedResultsController.delegate = self
        numberOfFetchedObjects = 0
        do {
            try photoFetchedResultsController.performFetch()
            let numberOfFetchedObjects = (photoFetchedResultsController.fetchedObjects?.count)!
            print("numberOfFetchedObjects = \(numberOfFetchedObjects)")
            /*if numberOfFetchedObjects == 0 && photosDownloadIsInProcess == true {    // either no photos or not ready
             NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(fetchPhotos), name: Constants.notificationKey, object: nil)
             NSNotificationCenter.defaultCenter().removeObserver(self)
             photosDownloadIsInProcess = false
             }*/
            print("viewWillLoadLayoutSubviews # of fetched objects = \(numberOfFetchedObjects)")
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
            if selectedPin.photos.isEmpty &&  GlobalVar.sharedInstance.photosDownloadIsInProcess == false {
                        SharedNetworkServices.sharedInstance.savePhotos(Constants.maxNumOfPhotos, pin: selectedPin!) {(inner: () throws -> Bool) -> Void in
                do {
                    //print("in test inner")
                    try inner() // if successful continue else catch the error code
                } catch let error {
                    SharedMethod.showAlert(error, title: "Error", viewController: self)
                }
            }
        }
        //let timer = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: #selector(self.reloadData), userInfo: nil, repeats: true)
       //self.collectionView.reloadData()
       //print("reload data")
    }
    
    /*func reloadData() {
       self.collectionView.reloadData()
    }*/
    
    /*override func viewWillLayoutSubviews() {
        do {
            try photoFetchedResultsController.performFetch()
            let numberOfFetchedObjects = (photoFetchedResultsController.fetchedObjects?.count)!
            print("numberOfFetchedObjects = \(numberOfFetchedObjects), photosDownloadIsInProcess = \(photosDownloadIsInProcess)")
            /*if numberOfFetchedObjects == 0 && photosDownloadIsInProcess == true {    // either no photos or not ready
                 NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(fetchPhotos), name: Constants.notificationKey, object: nil)
                NSNotificationCenter.defaultCenter().removeObserver(self)
                photosDownloadIsInProcess = false
            }*/
            print("viewWillLoadLayoutSubviews # of fetched objects = \(numberOfFetchedObjects)")
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }

    }*/
    
    func fetchPhotos() {
        do {
            try photoFetchedResultsController.performFetch()
            let numberOfFetchedObjects = (photoFetchedResultsController.fetchedObjects?.count)!
            print("fetchPhotos # of fetched objects = \(numberOfFetchedObjects)")
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if (numberOfFetchedObjects > 0) {
            let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            let space: CGFloat = 5
            layout.sectionInset = UIEdgeInsets(top: 0, left: space, bottom: 0, right: space)
            layout.minimumLineSpacing = space
            layout.minimumInteritemSpacing = space
            //let width = floor(self.collectionView.frame.size.width/3 - 2*space)
            //print("viewDidLayoutSubviews frame size width = \(self.collectionView.frame.size.width), cell width = \(width)")
            //layout.itemSize = CGSize(width: width, height: width)
            //layout.invalidateLayout()
            print("setting collectionview")
            collectionView.backgroundColor = UIColor.whiteColor()
            collectionView.collectionViewLayout = layout
        }
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
        cell.backgroundColor = UIColor.whiteColor() // make cell more visible in our example project
        //cell.image.contentMode = .ScaleAspectFill
       
        if photo.imageData != nil {
            cell.image.image = UIImage(data: photo.imageData!)
        }
        
        //print("cellforitematindexpath framewidth = \(self.view.frame.width), cell  width = \(cell.frame.width)")
        //print("cellforitematindexpath cellframeheight = \(cell.frame.height), image  height = \(cell.image.frame.height)")
        cell.contentView.layoutIfNeeded()
        cell.contentView.layoutSubviews()
        return cell
    }
  
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let numberOfCellsPerRow: CGFloat = 3.0
        let space:CGFloat = 5.0
        let numberOfPaddingColumns: CGFloat = 5
        let cellwidth: CGFloat = (self.view.frame.size.width - space*numberOfPaddingColumns) / numberOfCellsPerRow
        //print("sizeforitematindexpath  framesizewidth = \(width), cell width = \(cellwidth)")
        return CGSizeMake(cellwidth, cellwidth)
    }
    
    /*func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        //let leftRightInset = self.view.frame.size.width / 14.0
        //return UIEdgeInsetsMake(0, leftRightInset, 0, leftRightInset)
    }*/
    
    /*func collectionView(tableView: UICollectionView,
                            commitEditingStyle editingStyle: UITableViewCellEditingStyle,
                                               forRowAtIndexPath indexPath: NSIndexPath) {
        
        switch (editingStyle) {
        case .Delete:
            
            // Here we get the actor, then delete it from core data
            let photo = photoFetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            SharedMethod.sharedContext.deleteObject(photo)
            CoreDataStackManager.sharedInstance.saveContext()
            
        default:
            break
        }
    }*/
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = photoFetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell!.opaque = true // make cell more visible in our example project
        SharedMethod.sharedContext.deleteObject(photo)
        CoreDataStackManager.sharedInstance.saveContext()
    }
    
    // MARK: - Fetched Results Controller Delegate
    
    // Step 4: This would be a great place to add the delegate methods
    //func controllerWillChangeContent(controller: NSFetchedResultsController) {
    //    self.tableView.beginUpdates()
    //}
    
  // inspired by https://discussions.udacity.com/t/integrating-a-collectionview-with-coredata/182241/2
    
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?,
                                    forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
            
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            
            let photo = anObject as! Photo
            SharedMethod.sharedContext.deleteObject(photo)
            break
            
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
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