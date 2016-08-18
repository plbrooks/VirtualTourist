//
//  SharedNetworkServices.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/7/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class SharedNetworkServices: NSObject, NSFetchedResultsControllerDelegate {
    static let sharedInstance = SharedNetworkServices()    // set up shared instance class
    private override init() {}                              // ensure no one will init
    
    
    // view did load   photoFetchedResultsController.delegate = self ?
   
    // MARK: Vars
    
    //var randomPageNumber = 0
    //var URLDictionary = [String: String]()

       // MARK: Lazy frc
    /*var selectedPin: Pin?
    lazy var photoFetchedResultsController: NSFetchedResultsController = {
        
        let request = NSFetchRequest(entityName: "Photo")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "pin == %@",self.selectedPin!)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: SharedMethod.sharedContext,sectionNameKeyPath: nil,cacheName: nil)
        return fetchedResultsController
        
    }()*/
    

    
    
    // MARK: Processing funcs
    
    // Key funcs are: 
    //   1. Get a page with photos from flickr.
    //   2. get the URLs from the page, store in a list
    //   3. Get photos of the URLs and store in Core Data.
    //
    // Error processing is handled in completion handlers that throw either true or the error code
    //
    // A var GlobalVar.sharedInstance.photosDownloadIsInProcess is set here, used by PhotoAlbumVC to determine
    //      if pin has no photos because it has no photos or if pin has no photos because photos are being downloaded
    //      and not yet available in Core Data

    func savePhotos(pin: Pin, completionHandler:(status: ErrorType) -> Void)  {

        GlobalVar.sharedInstance.photosDownloadIsInProcess = true   // photo downloads are in process
        self.getURLsFromFlickr(pin, completionHandler: { (status) in
            self.storePhotos(pin, completionHandler: { (status) in
                GlobalVar.sharedInstance.photosDownloadIsInProcess = false
                completionHandler(status: status)
            })
            completionHandler(status: status)
        })
    }

    func getURLsFromFlickr(pin: Pin, completionHandler:(status: ErrorType) -> Void) {
        let request = setUpRequest(pin)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { (data,response, error) in
            do {                        // Any Flickr errors?
                try self.checkForNetworkErrors(data, error: error)
                do {                    // Any parse errrors?
                    
                    let parsedResult: AnyObject!  = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    do {
                        
                        let totalPages = try self.checkForParseErrors(parsedResult)
                        pin.numOfPages = totalPages
                        do {
                            
                            let photoURLArray = try self.createArrayOfPhotoURLsFromParsedResult(parsedResult)
                                for item in photoURLArray! {
                                    let dictionary : [String : AnyObject] = [
                                        Photo.Keys.Key : item,
                                        Photo.Keys.Pin : pin as Pin
                                    ]
                                    let _ = Photo(dictionary: dictionary, context: SharedMethod.sharedContext)
                            }
                        } catch {
                            completionHandler(status:error)
                            /*storePhotos(pin, completionHandler: {(status) {
                                
                            })*/
                        }
                    
                        SharedMethod.saveContext()
                    
                        // MAKE SURE HANDLED
                        
                        completionHandler(status:Status.codeIs.noError)
                        
                    } catch {                               // parse error
                       completionHandler(status:error)
                    }
                    
                }  catch {                                  // NSJSON Serialization error
                    completionHandler(status:error)
                }
 
            }  catch {                                      // flickr error
                completionHandler(status:error)
            }
            
            // WHY CALLED
            
            /*if (error != nil) {
                completionHandler(status:Status.codeIs.nserror(type: "NSURLSession", error: error!))
            }*/
            
        }   // end of let task
        task.resume()
        
    }
    
    func createArrayOfPhotoURLsFromParsedResult (parsedResult: AnyObject!) throws -> NSArray? {
        
        let photosContainer = parsedResult["photos"] as? NSDictionary
        let photosDictionary = photosContainer!["photo"] as? [[String: AnyObject]]
        //let URLCount = photosDictionary!.count        // number of photos returned, which is constrained in flickr request
        var photoURLArray:[String] = []
        print("photosDictionary!.count = \(photosDictionary!.count)")
        
            for item in photosDictionary! {             // Get the URL strings
                guard let imageURLString = item["url_m"] as? String else {
                    return nil                          // no url_m found this iteration
                }
                photoURLArray.append(imageURLString)    // store URL string at the key
            }
        
        return photoURLArray
    
    }
    
    
    func checkForNetworkErrors(data: NSData?, error: NSError?) throws {
        
        guard error == nil else {
            switch error!.code {
            case -1009:
                throw Status.codeIs.network(type: Status.ErrorTypeIs.flickr, error: error!)
            default:
                throw Status.codeIs.nserror(type: Status.ErrorTypeIs.flickr, error: error!)
            }
        }
        
        guard data != nil else {    // Was there any data returned?
            throw Status.codeIs.noFlickrDataReturned
        }
        
    }
    
    
    func checkForParseErrors(parsedResult: AnyObject?) throws -> Int {
        
        guard parsedResult != nil else {
            throw Status.codeIs.couldNotParseData
        }
        
        guard let stat = parsedResult!["stat"] as? String where stat == "ok" else {  // GUARD: Did Flickr return an error?
            throw Status.codeIs.couldNotFindKey(type: "Stat")        }
        
        guard let photosDictionary = parsedResult!["photos"] as? NSDictionary else { // Is "photos" key in our result?
            throw Status.codeIs.couldNotFindKey(type: "Photos")
        }
        
        guard let totalPages = (photosDictionary["pages"] as? Int) else { // Is "pages" key in the photosDictionary?
            throw Status.codeIs.couldNotFindKey(type: "Pages")
        }
        
        print("photosDict = \(photosDictionary)")
        
        return totalPages
    
    }

    func setUpRequest (pin: Pin) -> NSURLRequest {
        
        var methodArguments = Constants.FlickrAPI.methodArguments
        
        methodArguments["page"] = pin.numOfPages as NSNumber
        methodArguments["bbox"] = createBoundingBoxString(pin.latitude as Double, longitude: pin.longitude as Double)
        
        let urlString = Constants.FlickrAPI.BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        return NSURLRequest(URL: url)
 
    }

    
    
    // Store photos in Core Data. Cycle through URLDictionary created in calling fund. For each URL, get the photo and store in Core Data
    
    func storePhotos(pin: Pin, completionHandler:(status: ErrorType) -> Void) {
        do {
            
            let request = NSFetchRequest(entityName: "Photo")
            request.sortDescriptors = []
            request.predicate = NSPredicate(format: "pin == %@",pin)
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: SharedMethod.sharedContext,sectionNameKeyPath: nil,cacheName: nil)

            
            try fetchedResultsController.performFetch()
            let fetchedObjects = fetchedResultsController.fetchedObjects
            if fetchedObjects!.count > 0 {
                for photo in fetchedObjects as! [Photo] {
                    if photo.imageData == nil {
                        let session = NSURLSession.sharedSession()
                        let URLString = NSURL(string: photo.key)
                        let request = NSMutableURLRequest(URL: URLString!)
                        request.HTTPMethod = "GET"
                        let task = session.dataTaskWithRequest(request) { (data,response, error) in
                            do {
                                
                                do {
                                    
                                    try self.checkForNetworkErrors(data, error: error)
                                    photo.imageData = data
                                    SharedMethod.saveContext()
                                    completionHandler(status: Status.codeIs.noError)
                
                                } catch {   // Network error
                                   
                                    completionHandler(status: error)
                                    
                                }
                        
    
                            } //end of do
                        }   // end of completion handler
                        task.resume()
                        
                    }   // end of photo.imageData == nil

                    
                }
                
            }
        } catch let error as NSError {
            completionHandler(status:Status.codeIs.accessSavedData(code: error.code, text: Status.ErrorTypeIs.photoError))
        }
        
        // CHECK THIS
        
        GlobalVar.sharedInstance.photosDownloadIsInProcess = false  // photo download completed
    }
    
    
    /*func storePhotos(pin: Pin, completionHandler: (inner: () throws -> Bool) -> Void) {
        let session = NSURLSession.sharedSession()
        for (key, photoURL) in URLDictionary {
            let URLString = NSURL(string: photoURL)
            let request = NSMutableURLRequest(URL: URLString!)
            request.HTTPMethod = "GET"
            let task = session.dataTaskWithRequest(request) { (data,response, error) in
                do {
                    //try self.checkForFlickrDataReturned(data, response: response, error: error)   // Any Flickr errors?
                    if let data = data {
                        // save in DB
                        let dictionary : [String : AnyObject] = [
                            Photo.Keys.Key : key as String,
                            Photo.Keys.ImageData : data as NSData,
                            Photo.Keys.Pin : pin as Pin
                        ]
                        let _ = Photo(dictionary: dictionary, context: SharedMethod.sharedContext)
                    }
                    CoreDataStackManager.sharedInstance.saveContext()
                } catch let error as NSError {
                    let throwError = Status.codeIs.nserror(type: Status.ErrorTypeIs.flickr, error: error)
                    completionHandler(inner: { throw throwError})
                }
                completionHandler(inner: {true})
                
            }
            task.resume()
        }
        GlobalVar.sharedInstance.photosDownloadIsInProcess = false  // photo download completed
    }*/
    

    // MARK: Helper functions
    
    // Check if flickr data is returned by checking various status codes
    
    /*func checkForFlickrDataReturned(data: NSData?, response: NSURLResponse?, error: NSError?) throws -> Void {
        
        guard error?.code != -1009 else {
            throw Status.codeIs.network(type: Status.ErrorTypeIs.flickr, error: error!)
        }
        
        guard (error == nil)  else {    // was there an error returned?
            throw Status.codeIs.nserror(type: Status.ErrorTypeIs.flickr, error: error!)
        }
        
        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else { // Did we get a successful 2XX response?
            let flickrStatus = (response as? NSHTTPURLResponse)?.statusCode
            throw Status.codeIs.flickrStatus(statusCode: flickrStatus!)
        }
    
    }*/
    
    
    // Lat/Lon Manipulation
    
    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        
        let bottom_left_lon = max(longitude - Constants.FlickrAPI.BOUNDING_BOX_HALF_WIDTH, Constants.FlickrAPI.LON_MIN)
        let bottom_left_lat = max(latitude - Constants.FlickrAPI.BOUNDING_BOX_HALF_HEIGHT, Constants.FlickrAPI.LAT_MIN)
        let top_right_lon = min(longitude + Constants.FlickrAPI.BOUNDING_BOX_HALF_HEIGHT, Constants.FlickrAPI.LON_MAX)
        let top_right_lat = min(latitude + Constants.FlickrAPI.BOUNDING_BOX_HALF_HEIGHT, Constants.FlickrAPI.LAT_MAX)
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    
    }


    // Escape HTML Parameters
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        for (key, value) in parameters {
            let stringValue = "\(value)"                            // Make sure that it is a string value
            
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())                     // Escape it
            urlVars += [key + "=" + "\(escapedValue!)"]             // Append it

        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

}