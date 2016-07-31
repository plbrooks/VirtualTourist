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
      
    
    
    var pin: Pin?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        print("photo album pin = \(pin)")
        setMap(pin!)       // set up the map view of the selected annotation
        //photoList
    }
    
    
    // tell the collection view how many cells to make
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // number of photos in photoList
        print("count = \(SharedNetworkServices.sharedInstance.URLDictionary.keys.count)")
        return SharedNetworkServices.sharedInstance.URLDictionary.keys.count
    }
    
    // make a cell for each cell index path
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let reuseID = "photoCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseID, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        //cell.myLabel.text = self.items[indexPath.item]
        //print("I am in collectionview")
        //cell.PhotoCollectionViewCellImage = nil
        cell.backgroundColor = UIColor.whiteColor() // make cell more visible in our example project
        //cell.image.image = AlbumPhoto
        
        return cell
    }
    
    
    @IBAction func addNewCollection(sender: AnyObject) {
    }

    
    func setMap(center: Pin) {
        // add the one annotation to the map view
        let myAnnotation = MKPointAnnotation()
        
        let location = CLLocationCoordinate2D(latitude: pin!.latitude as Double, longitude:pin!.longitude as Double)
        
        myAnnotation.coordinate = location
        self.mapView.addAnnotation(myAnnotation)
        
        // do some map housekeeping - set span, center, etc.
        let span = MKCoordinateSpanMake(1.0,1.0)        // set reasonable granularity
        let region = MKCoordinateRegion(center: location , span: span ) // center map
        self.mapView.setRegion(region, animated: true)  // show the map
    }
    
    
    
}