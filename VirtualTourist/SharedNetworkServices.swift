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
    private override init() {}                              // ensure noone will init
    
    /*public let FGSingleton = FGSingletonClass()

    public class FGSingletonClass {
    private init() {}*/

    var randomPageNumber = 0
    var URLDictionary = [String: String]()
    
    func savePhotos(maxNumOfPhotos:Int, pin: Pin, completionHandler: (inner: () throws -> Bool) -> Void) {
        
        randomPageNumber = 0
        URLDictionary = [:]
        
        getPageFromFlickr(Constants.maxNumOfPhotos, pin: pin) {(inner2: () throws -> Bool) -> Void in
            do {
                try inner2() // if successful continue else catch the error code
                self.getURLsFromFlickrPage(self.randomPageNumber, pin: pin) {(inner3: () throws -> Bool) -> Void in
                    do {
                        //print("after get URLs from FlickrPage")
                        try inner3() // if successful continue else catch the error code
                        self.storePhotos(pin) {(inner4: () throws -> Bool) -> Void in
                            do {
                                try inner4() // if successful continue else catch the error code
                                // NUMBER OF PHOTOS
                                completionHandler(inner: {true})
                            } catch let error {
                                completionHandler(inner: {throw error})
                            }
                        }
                    } catch let error {
                        completionHandler(inner: {throw error})
                    }
                }
            } catch let error {
                completionHandler(inner: {throw error})
            }
        completionHandler(inner: {true})
        }
        /*print("urldict 1 = \(URLDictionary)")
      
        getURLsFromFlickrPage(randomPageNumber, coordinate: coordinate) {(inner2: () throws -> Bool) -> Void in
            do {
                try inner2() // if successful continue else catch the error code
            } catch let error {
                completionHandler(inner: {throw error})
            }
        }
        print("urldict 2 = \(URLDictionary)")

        storePhotos() {(inner2: () throws -> Bool) -> Void in
            do {
                try inner2() // if successful continue else catch the error code
            } catch let error {
                completionHandler(inner: {throw error})
            }
        }
        
        completionHandler(inner: {true})*/
}

    func checkForFlickrErrors(data: NSData?, response: NSURLResponse?, error: NSError?) throws -> Void {
        guard (error == nil)  else {    // was there an error returned?
            print("Flickr error")
            throw Status.codeIs.flickrError(type: "Flickr error", code: error!.code, text: error!.localizedDescription)
        }
        
        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else { // Did we get a successful 2XX response?
            if let response = response as? NSHTTPURLResponse {
                print("Your request returned an invalid response! Status code: \(response.statusCode)!")
            } else if let response = response {
                print("Your request returned an invalid response! Response: \(response)!")
            } else {
                print("Your request returned an invalid response!")
            }
            throw Status.codeIs.noError
        }
        
        guard let data = data else {    // Was there any data returned?
            print("No data was returned by the request!")
            throw Status.codeIs.noError
        }
        
        let parsedResult: AnyObject!    //  Parse the data!
        
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            parsedResult = nil
            print("Could not parse the data as JSON: '\(data)'")
            throw Status.codeIs.noError
        }
        
        guard let stat = parsedResult["stat"] as? String where stat == "ok" else {  // GUARD: Did Flickr return an error?
            //print("Flickr API returned an error. See error code and message in \(parsedResult)")
            throw Status.codeIs.flickrError(type: "Flickr error", code: parsedResult["code"] as! Int, text: parsedResult["message"] as! String)
        }
        
        guard let photosDictionary = parsedResult["photos"] as? NSDictionary else { // Is "photos" key in our result?
            print("Cannot find keys 'photos' in \(parsedResult)")
            throw Status.codeIs.noError
        }
        
        if photosDictionary["pages"] == nil { // Is "pages" key in the photosDictionary?
            print("Cannot find key 'pages' in \(photosDictionary)")
            throw Status.codeIs.noError
        }
        
    }

    func checkForFlickrDataReturned(data: NSData?, response: NSURLResponse?, error: NSError?) throws -> Void {
        guard (error == nil)  else {    // was there an error returned?
            print("Flickr error")
            throw Status.codeIs.flickrError(type: "Flickr error", code: error!.code, text: error!.localizedDescription)
        }

        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else { // Did we get a successful 2XX response?
            if let response = response as? NSHTTPURLResponse {
                print("Your request returned an invalid response! Status code: \(response.statusCode)!")
            } else if let response = response {
                print("Your request returned an invalid response! Response: \(response)!")
            } else {
                print("Your request returned an invalid response!")
            }
            throw Status.codeIs.noError
        }
    }

    /* Store photos*/
    
    func storePhotos(pin: Pin, completionHandler: (inner: () throws -> Bool) -> Void) {
        //print("urldict to be stored = \(self.URLDictionary)")
        let session = NSURLSession.sharedSession()
        for (key, photoURL) in URLDictionary {
            let URLString = NSURL(string: photoURL)
            let request = NSMutableURLRequest(URL: URLString!)
            request.HTTPMethod = "GET"
            let task = session.dataTaskWithRequest(request) { (data,response, error) in
                do {
                    try self.checkForFlickrDataReturned(data, response: response, error: error)   // Any Flickr errors?
                    /* if here no errors */
                    print("starting to save photo key \(key) stored in DB")
                    if let data = data {
                        // save in DB
                        let dictionary : [String : AnyObject] = [
                            Photo.Keys.Key : key as String,
                            Photo.Keys.ImageData : data as NSData,
                            Photo.Keys.Pin : pin as Pin
                        ]
                        let _ = Photo(dictionary: dictionary, context: self.sharedContext)
                        print("saved photo key \(key) stored in DB")
                    }
                CoreDataStackManager.sharedInstance.saveContext()
                } catch let error as NSError {
                    Status.codeIs.flickrError(type: "saving Photos", code: error.code, text: error.localizedDescription)
                    completionHandler(inner: {throw error})
                }
            }
            task.resume()
        }
    }

    //struct Cache {
    //    static let imageCache = ImageCache()
    //}
    
    /* Function makes first request to get a random page, then it makes a request to get an image with the random page */
    
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
                /* if here no errors */
                
                let parsedResult: AnyObject!    //  Parse the data!
                do {
                    parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    let photosDictionary = parsedResult["photos"] as? NSDictionary
                    let totalPages = (photosDictionary!["pages"] as? Int)!
                    let pageLimit = min(totalPages, 200)        // Pick a random page
                    self.randomPageNumber = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    //self.getURLsFromFlickrPage(methodArguments, pageNumber: randomPage, coordinate: coordinate)
                    dispatch_async(dispatch_get_main_queue(), {
                        completionHandler(inner: {true})
                    })
                } catch {
                    return
                }
                
            } catch let error {
                completionHandler(inner: {throw error})
            }
        }
        task.resume()
    }
    
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
                      // Use SERVER and ID to get unique name
            do {
                try self.checkForFlickrErrors(data, response: response, error: error)   // Any Flickr errors?
                /* if here no errors */
                
                let parsedResult: AnyObject!    //  Parse the data!
                do {
                    parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    let photosContainer = parsedResult["photos"] as? NSDictionary
                    let photosDictionary = photosContainer!["photo"] as? [[String: AnyObject]]
                    let URLCount = min(Constants.maxNumOfPhotos,photosDictionary!.count)
                    print("URL count = \(URLCount)")
                    
                    // get pin
                    /*let request = NSFetchRequest(entityName: "Pin")
                    let testLat = coordinate.latitude as NSNumber
                    let testLong = coordinate.longitude as NSNumber
                    let firstPredicate = NSPredicate(format: "latitude == %@", testLat)
                    let secondPredicate = NSPredicate(format: "longitude == %@", testLong)
                    let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
                    request.predicate = predicate
                    request.sortDescriptors = []
                    let context = self.sharedContext*/
                    //do {
                        //let pins = try context.executeFetchRequest(request) as! [Pin]
                        //print("pins.count = \(pins.count)")
                        //if (pins.count == 1) {
                            //for pin: Pin in pins {
                                //print("pin retrieved from Network Services lat and long = \(pin.latitude), \(pin.longitude)")
                                for _ in 0...URLCount {
                                    let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosDictionary!.count)))
                                    let randomPhoto = photosDictionary![randomPhotoIndex]
                                    /* GUARD: Does our photo have a key for 'url_m'? */
                                    guard let imageURLString = randomPhoto["url_m"] as? String else {
                                        print("Cannot find key 'url_m' in \(randomPhoto)")
                                        return
                                    }
                                    let key = (randomPhoto["server"] as! String) + (randomPhoto["id"] as! String)
                                    self.URLDictionary[key] = imageURLString
                                    print("URLdict key, value created = \(key), \(imageURLString)")
                            
                                    // CHECK EACH ITEM IS NOT NIL
                                    
                                    
                                }
                                //CoreDataStackManager.sharedInstance.saveContext()
                                //print("URLdict after core data store  = \(self.URLDictionary)")

                                //CHECK FOR ERROR
                            
                            //}
                        //} else {
                        //    print("No Users")
                        //}
                    //} catch let error as NSError {
                        // failure
                      //  print("Fetch failed: \(error.localizedDescription)")
                    //}
                    
                } catch {
                    // NEVER CALLED?
                    completionHandler(inner: {true})
                }
                
            } catch let error {
                completionHandler(inner: {throw error})
            }
            completionHandler(inner: {true})
        }
        task.resume()
    }
    
    // MARK: Lat/Lon Manipulation
    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        let bottom_left_lon = max(longitude - Constants.FlickrAPI.BOUNDING_BOX_HALF_WIDTH, Constants.FlickrAPI.LON_MIN)
        let bottom_left_lat = max(latitude - Constants.FlickrAPI.BOUNDING_BOX_HALF_HEIGHT, Constants.FlickrAPI.LAT_MIN)
        let top_right_lon = min(longitude + Constants.FlickrAPI.BOUNDING_BOX_HALF_HEIGHT, Constants.FlickrAPI.LON_MAX)
        let top_right_lat = min(latitude + Constants.FlickrAPI.BOUNDING_BOX_HALF_HEIGHT, Constants.FlickrAPI.LAT_MAX)
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }


    // MARK: Escape HTML Parameters
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        for (key, value) in parameters {
            let stringValue = "\(value)"                            // Make sure that it is a string value
            
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())                     // Escape it
            urlVars += [key + "=" + "\(escapedValue!)"]             // Append it

        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    func imageDirectoryName(usingKey: String) -> String {
        return SharedMethod.applicationDocumentsDirectory.URLByAppendingPathComponent(usingKey).path!
    }
    
    
}