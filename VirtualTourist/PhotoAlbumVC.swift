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

    
    //  MARK: IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollection: UIButton!
    
    
    //  MARK: Vars
    
    var selectedPin: Pin!
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths:  [NSIndexPath]!
    var updatedIndexPaths:  [NSIndexPath]!
    
    
    // MARK: Lazy frc
    
    lazy var photoFetchedResultsController: NSFetchedResultsController = {
        
        let request = NSFetchRequest(entityName: "Photo")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "pin == %@",self.selectedPin)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: SharedMethod.sharedContext,sectionNameKeyPath: nil,cacheName: nil)
        return fetchedResultsController
        
    }()
    
    
     // MARK: Init override functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        mapView.delegate = self
        setMap(selectedPin!)       // set up the map view of the selected annotation
        SharedMethod.setActivityIndicator("START", mapView: mapView, activityIndicator: activityIndicator)
        collectionView.delegate = self;
        collectionView.dataSource = self;
        photoFetchedResultsController.delegate = self
        do {
            try photoFetchedResultsController.performFetch()
        } catch let error as NSError {
             SharedMethod.showAlert(error, title: "Error")
        }
        
    }
    
    
    // Start downloading photos for the pin if no photos exist and there is no download in process
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        // If no photos for pin AND there is no download in process then there are truly no photos for the pin in Core Data
        //      so try again
        // If no photos for pin AND there IS a download in process, don't try to download again. 
        //      (Just continue and download will complete)
        if selectedPin.photos.isEmpty &&  GlobalVar.sharedInstance.photosDownloadIsInProcess == false {
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
        newCollection.enabled = true
    }
    
    
    // Set up collection layout parameters
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let space: CGFloat = 5
        layout.sectionInset = UIEdgeInsets(top: 0, left: space, bottom: 0, right: space)
        layout.minimumLineSpacing = space
        layout.minimumInteritemSpacing = space
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.collectionViewLayout = layout
    }
    
    
    // MARK: Refresh photo collection
    
    @IBAction func addNewCollection(sender: UIButton) {
        newCollection.enabled = false
        
        let photosToDelete = photoFetchedResultsController.fetchedObjects
        
        for item in photosToDelete! {   // delete photos
            let photo = item as! Photo
            SharedMethod.sharedContext.deleteObject(photo)
        }
        
        CoreDataStackManager.sharedInstance.saveContext()
        
        // start to add photos
        SharedNetworkServices.sharedInstance.savePhotos(selectedPin!, completionHandler: {(error) in
            switch error {
            case Status.codeIs.noError:
                break
            default:
                SharedMethod.showAlert(error, title: "Error")
                break
            }
            self.newCollection.enabled = true

        })
    }
    
    
    // MARK: Collectionview Delegate funcs
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return photoFetchedResultsController.sections?.count ?? 0   // Always only 1 section
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoFetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let photo = photoFetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let reuseID = "photoCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseID, forIndexPath: indexPath) as! PhotoCollectionViewCell
        cell.backgroundColor = UIColor.whiteColor() // make cell more visible
        if (photo.imageData != nil) {
            cell.image.image = UIImage(data: photo.imageData!)
            cell.activityIndicator.hidden = true
            cell.activityIndicator.stopAnimating()

        } else {
            cell.image.image = UIImage(named: "downloading.png")
            cell.activityIndicator.hidden = false
            cell.activityIndicator.startAnimating()
        }
        cell.contentView.layoutIfNeeded()
        cell.contentView.layoutSubviews()
        newCollection.enabled = true
        return cell
    }
  
    
    // Set collection view flowlayout parameters
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let numberOfCellsPerRow: CGFloat = 3.0
        let space:CGFloat = 5.0
        let numberOfPaddingColumns: CGFloat = 5
        let cellwidth: CGFloat = (self.view.frame.size.width - space*numberOfPaddingColumns) / numberOfCellsPerRow
        return CGSizeMake(cellwidth, cellwidth)
    
    }
    
    
    // Delete the cell if it is selected
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let photo = photoFetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell!.opaque = true
        SharedMethod.sharedContext.deleteObject(photo)
        CoreDataStackManager.sharedInstance.saveContext()
    
    }
    
    // MARK: - Fetched Results Controller Delegate funcs
    // inspired by https://discussions.udacity.com/t/integrating-a-collectionview-with-coredata/182241/2
    
    
    // Create indexPath arrays
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    
    // Handle changes to the indexPath
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
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
    
    
    // Handle changes to the collection view
    
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
        },
        completion: nil)
    }

    
    // MARK: Set the map
    
    func setMap(center: Pin) {
        
        // Add the one annotation to the map view
        let myAnnotation = MKPointAnnotation()
        let location = CLLocationCoordinate2D(latitude: selectedPin!.latitude as Double, longitude:selectedPin!.longitude as Double)
        myAnnotation.coordinate = location
        mapView.addAnnotation(myAnnotation)
        
        // Do some map housekeeping - set span, center, etc.
        let span = MKCoordinateSpanMake(1.0,1.0)                        // set reasonable granularity
        let region = MKCoordinateRegion(center: location , span: span ) // center map
        mapView.setRegion(region, animated: true)                  // show the map
    }
    
    func mapViewDidStartRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        
        SharedMethod.setActivityIndicator("START", mapView: mapView, activityIndicator: activityIndicator)
        
    }
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        
        SharedMethod.setActivityIndicator("FINISH", mapView: mapView, activityIndicator: activityIndicator)
    }
 
}