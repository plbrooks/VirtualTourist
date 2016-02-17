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
    private override init() {}                      // ensure noone will init
    
    
    func test(maxNumOfPhotos:Int, coordinate: CLLocationCoordinate2D, completionHandler: (inner: () throws -> Bool) -> Void) {

        getImagesFromFlickr(maxNumOfPhotos, coordinate: coordinate) {(inner: () throws -> Bool) -> Void in
            do {
                try inner() // if successful continue else catch the error code
            } catch let error {
                dispatch_async(dispatch_get_main_queue(), {
                    completionHandler(inner: {throw error})
                })
            }
        }
        
        
        
}

    func checkForFlickrErrors(data: NSData?, response: NSURLResponse?, error: NSError?) throws -> Void {
        guard (error == nil)  else {    // was there an error returned?
            print("Flickr error")
            throw Status.codeIs.flickrError(code: error!.code, text: error!.localizedDescription)
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
            throw Status.codeIs.flickrError(code: parsedResult["code"] as! Int, text: parsedResult["message"] as! String)
        }
        
        guard let photosDictionary = parsedResult["photos"] as? NSDictionary else { // Is "photos" key in our result?
            print("Cannot find keys 'photos' in \(parsedResult)")
            throw Status.codeIs.noError
        }
        
        if photosDictionary["pages"] != nil { // Is "pages" key in the photosDictionary?
            print("Cannot find key 'pages' in \(photosDictionary)")
            throw Status.codeIs.noError
        }
        
    }



    /* Function makes first request to get a random page, then it makes a request to get an image with the random page */
    func getImagesFromFlickr(maxNumOfPhotos:Int, coordinate: CLLocationCoordinate2D, completionHandler: (inner: () throws -> Bool) -> Void) {
        
        var methodArguments = Constants.FlickrAPI.methodArguments
        methodArguments["bbox"] = createBoundingBoxString(coordinate.latitude, longitude: coordinate.longitude)
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
                    let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    self.getURLsFromFlickrPage(methodArguments, pageNumber: randomPage, coordinate: coordinate)
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
    
    func getURLsFromFlickrPage(methodArguments: [String : AnyObject], pageNumber: Int, coordinate: CLLocationCoordinate2D) {
        
        var withPageDictionary = methodArguments    // start with prior arguments
        withPageDictionary["page"] = pageNumber     // add in a specific page #
        withPageDictionary["per_page"] = Constants.FlickrAPI.PER_PAGE   // get a lot of photos per page
        
        let session = NSURLSession.sharedSession()
        let urlString = Constants.FlickrAPI.BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosContainer = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let numOfPhotos = (photosContainer["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in \(photosContainer)")
                return
            }
            
            /* GUARD: Photos found? */
            guard numOfPhotos > 0 else {
                print("No photos found")    // BUT THAT IS OK
                return
            }
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosDictionary = photosContainer["photo"] as? [[String: AnyObject]] else {
                print("Cannot find key 'photo' in \(photosContainer)")
                return
            }
            
            /* GUARD: Are there photos in the "photo" key in photosDictionary? */
            guard photosDictionary.count > 0 else  {
                print("No photos found")
                return
            }
            //print("photo directory = \(photosDictionary)")
            
            // Use SERVER and ID to get unique name
            
            let URLCount = min(Constants.maxNumOfPhotos,photosDictionary.count)
            print("URL count = \(URLCount)")
            
            // get pin
            let request = NSFetchRequest(entityName: "Pin")
            let testLat = coordinate.latitude as NSNumber
            let testLong = coordinate.longitude as NSNumber
            let firstPredicate = NSPredicate(format: "latitude == %@", testLat)
            let secondPredicate = NSPredicate(format: "longitude == %@", testLong)
            let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
            request.predicate = predicate
            request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
            let context = self.sharedContext
            
            do {
                let pins = try context.executeFetchRequest(request) as! [Pin]
                if (pins.count == 1) {
                    for pin: Pin in pins {
                        print("pin retrieved from Network Services lat and long = \(pin.latitude), \(pin.longitude)")
                        for var i = 1; i <= URLCount; ++i {
                            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosDictionary.count)))
                            let randomPhoto = photosDictionary[randomPhotoIndex] as [String: AnyObject]
                            
                            /* GUARD: Does our photo have a key for 'url_m'? */
                            guard let imageURLString = randomPhoto["url_m"] as? String else {
                                print("Cannot find key 'url_m' in \(randomPhoto)")
                                return
                            }
                            let dictionary: [String : AnyObject] = [
                                Photo.Keys.Imagepath   : imageURLString,
                                Photo.Keys.Pin : pin
                            ]
                            let _ = Photo(dictionary: dictionary, context: self.sharedContext)
                            print("photo imagepath and pin added - \(imageURLString), pin = \(pin.latitude), \(pin.longitude)")
                        }
                        CoreDataStackManager.sharedInstance.saveContext()
                    }
                } else {
                    print("No Users")
                }
            } catch let error as NSError {
                // failure
                print("Fetch failed: \(error.localizedDescription)")
            }
            return
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

}