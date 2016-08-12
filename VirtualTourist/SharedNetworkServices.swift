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
    
    // MARK: Vars
    var randomPageNumber = 0
    var URLDictionary = [String: String]()
    
    
    // MARK: Processing funcs
    
    // Key funcs are: 1. Get a page with photos from flickr.   2. get the URLs from the page, store in a list
    //            3. Get photos of the URLs and store in Core Data.
    //
    // Error processing is handled in completion handlers that throw either true or the error code
    //
    // A var GlobalVar.sharedInstance.photosDownloadIsInProcess is set here, used by PhotoAlbumVC to determine
    //      if pin has no photos because it has no photos or if pin has no photos because photos are being downloaded
    //      and not yet available in Core Data

    func savePhotos(maxNumOfPhotos:Int, pin: Pin, completionHandler: (inner: () throws -> Bool) -> Void) {
                
        randomPageNumber = 0
        URLDictionary = [:]
        GlobalVar.sharedInstance.photosDownloadIsInProcess = true   // photo downloads are in process.
        getPageFromFlickr(Constants.maxNumOfPhotos, pin: pin) {(inner2: () throws -> Bool) -> Void in
            do {
                try inner2() // check the completion handler
                self.getURLsFromFlickrPage(self.randomPageNumber, pin: pin) {(inner3: () throws -> Bool) -> Void in
                    do {
                        try inner3() // check the completion handler
                        self.storePhotos(pin) {(inner4: () throws -> Bool) -> Void in
                            do {
                                try inner4() /// check the completion handler
                                completionHandler(inner: {true})
                            } catch {
                                completionHandler(inner: {throw error})
                            }
                        }
                    } catch {
                        completionHandler(inner: {throw error})
                    }
                }
            } catch {
                completionHandler(inner: {throw error})
            }
        completionHandler(inner: {true})
        }
    
    }

    
    // Store photos in Core Data. Cycle through URLDictionary created in calling fund. For each URL, get the photo and store in Core Data
    
    func storePhotos(pin: Pin, completionHandler: (inner: () throws -> Bool) -> Void) {
        let session = NSURLSession.sharedSession()
        for (key, photoURL) in URLDictionary {
            let URLString = NSURL(string: photoURL)
            let request = NSMutableURLRequest(URL: URLString!)
            request.HTTPMethod = "GET"
            let task = session.dataTaskWithRequest(request) { (data,response, error) in
                do {
                    try self.checkForFlickrDataReturned(data, response: response, error: error)   // Any Flickr errors?
                    if let data = data {
                        // save in DB
                        let dictionary : [String : AnyObject] = [
                            Photo.Keys.Key : key as String,
                            Photo.Keys.ImageData : data as NSData,
                            Photo.Keys.Pin : pin as Pin
                        ]
                        let _ = Photo(dictionary: dictionary, context: SharedMethod.sharedContext)
                    }
                } catch let error as NSError {
                    let throwError = Status.codeIs.nserror(type: Status.ErrorTypeIs.flickr, error: error)
                    completionHandler(inner: { throw throwError})
                }
            }
            task.resume()
        }
        CoreDataStackManager.sharedInstance.saveContext()
        GlobalVar.sharedInstance.photosDownloadIsInProcess = false  // photo download completed
        completionHandler(inner: {true})
    
    }

    
    // Get the random page from flickr and store in self.randomPageNumber, that is used in the next called func
    
    func getPageFromFlickr(maxNumOfPhotos:Int, pin: Pin, completionHandler: (inner: () throws -> Bool) -> Void) {
        
        var methodArguments = Constants.FlickrAPI.methodArguments
        methodArguments["bbox"] = createBoundingBoxString(pin.latitude as Double, longitude: pin.longitude as Double)
        let session = NSURLSession.sharedSession()
        let urlString = Constants.FlickrAPI.BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data,response, error) in
            do {
                try self.checkForFlickrErrors(data, response: response, error: error)   // Any Flickr errors?
                let parsedResult: AnyObject!    //  Parse the data!
                do {
                    parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    let photosDictionary = parsedResult["photos"] as? NSDictionary
                    let totalPages = (photosDictionary!["pages"] as? Int)!
                    let pageLimit = min(totalPages, 200)        // Pick a random page
                    self.randomPageNumber = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    dispatch_async(dispatch_get_main_queue(), {
                        completionHandler(inner: {true})
                    })
                } catch let error as NSError {
                    let throwError = Status.codeIs.nserror(type: Status.ErrorTypeIs.flickr, error: error)
                    completionHandler(inner: { throw throwError})
                    return
                }
                
            } catch {
                completionHandler(inner: { throw error})    // error set in checkForFlickrErrors validation func
            }
        }
        task.resume()
    
    }
    
    
    // Get URLs from a random page from flickr, using the page number stored in self.randomPageNumber.
    
    func getURLsFromFlickrPage(pageNumber: Int, pin: Pin, completionHandler: (inner: () throws -> Bool) -> Void) {
        
        var methodArguments = Constants.FlickrAPI.methodArguments    // start with prior arguments
        methodArguments["bbox"] = createBoundingBoxString(pin.latitude as Double, longitude: pin.longitude as Double)
        methodArguments["page"] = pageNumber     // add in a specific page #
        methodArguments["per_page"] = Constants.FlickrAPI.PER_PAGE   // get a lot of photos per page
        
        let session = NSURLSession.sharedSession()
        let urlString = Constants.FlickrAPI.BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            do {
                try self.checkForFlickrErrors(data, response: response, error: error)   // Any Flickr errors?
                let parsedResult: AnyObject!                //  Parse the data!
                
                do {
                    parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    let photosContainer = parsedResult["photos"] as? NSDictionary
                    let photosDictionary = photosContainer!["photo"] as? [[String: AnyObject]]
                    let URLCount = min(Constants.maxNumOfPhotos,photosDictionary!.count)
                    switch URLCount {
                    case 0:
                        completionHandler(inner: {true})    // no photos that is OK
                    default:
                        
                        for _ in 1...URLCount {
                            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosDictionary!.count)))
                            let randomPhoto = photosDictionary![randomPhotoIndex]
                            // Get the URL string
                            guard let imageURLString = randomPhoto["url_m"] as? String else {
                                print("Cannot find key 'url_m' in \(randomPhoto)")
                                return
                            }
                            // Use SERVER and ID to create a unique key name
                            let key = (randomPhoto["server"] as! String) + (randomPhoto["id"] as! String)
                            self.URLDictionary[key] = imageURLString    // store URL string at the key
                        }
                    
                    }
                } catch {
                    let throwError = Status.codeIs.couldNotParseData
                    completionHandler(inner: { throw throwError})
                }
                
            } catch {
                completionHandler(inner: {throw error}) // error set in checkForFlickrErrors validation rountine
            }
            
            completionHandler(inner: {true})    // if here all is OK
        }
        
        task.resume()
    
    }
    
    
    // Rather than check for specific flickr errors in all funcs, have the funcs call this func
    
    func checkForFlickrErrors(data: NSData?, response: NSURLResponse?, error: NSError?) throws -> Void {
        
        
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
        
        guard let data = data else {    // Was there any data returned?
            throw Status.codeIs.noFlickrDataReturned
        }
        
        let parsedResult: AnyObject!    //  Parse the data!
        
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            parsedResult = nil
            throw Status.codeIs.couldNotParseData
        }
        
        guard let stat = parsedResult["stat"] as? String where stat == "ok" else {  // GUARD: Did Flickr return an error?
            throw Status.codeIs.nserror(type: Status.ErrorTypeIs.flickr, error: error!)
        }
        
        guard let photosDictionary = parsedResult["photos"] as? NSDictionary else { // Is "photos" key in our result?
            throw Status.codeIs.couldNotFindKey(type: "Photos")
        }
        
        if photosDictionary["pages"] == nil { // Is "pages" key in the photosDictionary?
            throw Status.codeIs.couldNotFindKey(type: "Pages")
        }
        
    }

    // MARK: Helper functions
    
    // Check if flickr data is returned by checking various status codes
    
    func checkForFlickrDataReturned(data: NSData?, response: NSURLResponse?, error: NSError?) throws -> Void {
        
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