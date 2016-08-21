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
                        
                        let totalPages = try self.getTotalPagesAvail(parsedResult)
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
            
        }   // end of let task
        task.resume()
        
    }
    
    func createArrayOfPhotoURLsFromParsedResult (parsedResult: AnyObject!) throws -> NSArray? {
        
        let photosContainer = parsedResult["photos"] as? NSDictionary
        let photosDictionary = photosContainer!["photo"] as? [[String: AnyObject]]
        var photoURLArray:[String] = []
        
            for item in photosDictionary! {             // Get the URL strings
                guard let imageURLString = item["url_m"] as? String else {
                    return nil                          // no url_m found this iteration
                }
                photoURLArray.append(imageURLString)    // store URL string at the key
            }
        
        
        return photoURLArray
    
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
        
        GlobalVar.sharedInstance.photosDownloadIsInProcess = false  // photo download completed
    }
    
    
    func setUpRequest (pin: Pin) -> NSURLRequest {
        
        var methodArguments = Constants.FlickrAPI.methodArguments
        
        methodArguments["page"] = Int(arc4random_uniform(UInt32(NSInteger(pin.numOfPages))) + 1)
        
        methodArguments["bbox"] = createBoundingBoxString(pin.latitude as Double, longitude: pin.longitude as Double)
        
        let urlString = Constants.FlickrAPI.BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        return NSURLRequest(URL: url)
        
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
    
    
    func getTotalPagesAvail(parsedResult: AnyObject?) throws -> Int {
        
        guard parsedResult != nil else {
            throw Status.codeIs.couldNotParseData
        }
        
        guard let stat = parsedResult!["stat"] as? String where stat == "ok" else {  // GUARD: Did Flickr return an error?
            throw Status.codeIs.couldNotFindKey(type: "Stat")        }
        
        guard let photosDictionary = parsedResult!["photos"] as? NSDictionary else { // Is "photos" key in our result?
            throw Status.codeIs.couldNotFindKey(type: "Photos")
        }
        
        guard var totalPages = (photosDictionary["pages"] as? Int) else { // Is "pages" key in the photosDictionary?
            throw Status.codeIs.couldNotFindKey(type: "Pages")
        }
        // make sure flickr will return less than 4000 photos else will get duplicate photos for different pages
        if totalPages > Constants.maxPageNumFromFlickr {totalPages = Constants.maxPageNumFromFlickr}
        
        return totalPages
        
    }


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