//
//  SharedNetworkServices.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/7/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import Foundation
import UIKit



class SharedNetworkServices: NSObject {
    static let sharedInstance = SharedNetworkServices()    // set up shared instance class
    private override init() {}                      // ensure noone will init
    
    
    var photoURLDict = [String:NSURL]()
    
    /* Function makes first request to get a random page, then it makes a request to get an image with the random page */
    func getImagesFromFlickr(maxNumOfPhotos:Int, completionHandler: (inner: () throws -> Bool) -> Void) {
        
        let methodArguments: [String: String!] = [
            "method": Constants.FlickrAPI.METHOD_NAME,
            "api_key": Constants.FlickrAPI.API_KEY,
            "bbox": createBoundingBoxString(0.0, longitude: 0.0),
            "safe_search": Constants.FlickrAPI.SAFE_SEARCH,
            "extras": Constants.FlickrAPI.EXTRAS,
            "format": Constants.FlickrAPI.DATA_FORMAT,
            "nojsoncallback": Constants.FlickrAPI.NO_JSON_CALLBACK
        ]
        
        let session = NSURLSession.sharedSession()
        let urlString = Constants.FlickrAPI.BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            var taskError = Status.codeIs.noError // error that is passed backed to login VC if error is found. Default to "no error"
 
            /* GUARD: Was there an error? */
            guard (error == nil)  else {    // an error was returned
                switch(error!.code){
                default:
                    taskError = Status.codeIs.flickrError(code: error!.code, text: error!.localizedDescription)
                }
                dispatch_async(dispatch_get_main_queue(), {
                    completionHandler(inner: {throw taskError})
                })
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
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                taskError = Status.codeIs.flickrError(code: parsedResult["code"] as! Int, text: parsedResult["message"] as! String)
                dispatch_async(dispatch_get_main_queue(), {
                    completionHandler(inner: {throw taskError})
                })
                //print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary["pages"] as? Int else {
                print("Cannot find key 'pages' in \(photosDictionary)")
                return
            }
           
            //print("photo dict = \(photosDictionary)")
            
            /* Pick a random page */
            let pageLimit = min(totalPages, 200)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getURLsFromFlickrPage(methodArguments, pageNumber: randomPage)
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(inner: {true})
            })
        }
        task.resume()
    }
    
    func getURLsFromFlickrPage(methodArguments: [String : AnyObject], pageNumber: Int) {
        
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
            
            let URLCount = min(Constants.maxNumOfPhotos,photosDictionary.count)
            print("URL count = \(URLCount)")
            for var i = 1; i <= URLCount; ++i {
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosDictionary.count)))
                let randomPhoto = photosDictionary[randomPhotoIndex] as [String: AnyObject]
                /* GUARD: Does our photo have a key for 'url_m'? */
                guard let imageUrlString = randomPhoto["url_m"] as? String else {
                    print("Cannot find key 'url_m' in \(randomPhoto)")
                    return
                }
                let imageURL = NSURL(string: imageUrlString)
                let photoName = "Photo" + String(i)
                self.photoURLDict[photoName] = imageURL
                print("photodict in sharedservcies = \(self.photoURLDict)")
            }
            return
        }
        task.resume()
    }
    
    // MARK: Lat/Lon Manipulation
    
    
    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
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
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }


}