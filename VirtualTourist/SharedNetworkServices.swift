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
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
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
           
            print("photo dict = \(photosDictionary)")
            
            /* Pick a random page!, get page */
            let pageLimit = min(totalPages, 40)
            for  var i = 1; i <= maxNumOfPhotos; i++ {
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage, photoNum: i)
                i++
            }
        }
        task.resume()
    }
    
    
    
    /*{
        
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
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
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
            
            /* Pick a random page! */
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage)
        }
        
        task.resume()
    }*/
    
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, photoNum: Int) {
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = Constants.FlickrAPI.BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString + "Photo" + String(photoNum))!
        let request = NSURLRequest(URL: url)
        
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
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in \(photosDictionary)")
                return
            }
            
            
            /* GUARD: Photos found? */
            guard totalPhotosVal > 0 else {
                print("No photos found")    // BUT THAT IS OK
                return
            }
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                print("Cannot find key 'photo' in \(photosDictionary)")
                return
            }
            print("photo array = \(photosArray)")
            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
            let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
            //let photoTitle = photoDictionary["title"] as? String /* non-fatal */
            
            
            /* GUARD: Does our photo have a key for 'url_m'? */
            guard let imageUrlString = photoDictionary["url_m"] as? String else {
                print("Cannot find key 'url_m' in \(photoDictionary)")
                return
            }
            
            let imageURL = NSURL(string: imageUrlString)
            if let imageData = NSData(contentsOfURL: imageURL!) {
                dispatch_async(dispatch_get_main_queue(), {
                   // save the image
                    print("I am here")
                    
                    // let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(imageData, toFile: Photos.ArchiveURL.path!)
                    
                    
                    /*
                    self.defaultLabel.alpha = 0.0
                    self.photoImageView.image = UIImage(data: imageData)
                    
                    if methodArguments["bbox"] != nil {
                        if let photoTitle = photoTitle {
                            self.photoTitleLabel.text = "\(self.getLatLonString()) \(photoTitle)"
                        } else {
                            self.photoTitleLabel.text = "\(self.getLatLonString()) (Untitled)"
                        }
                    } else {
                        self.photoTitleLabel.text = photoTitle ?? "(Untitled)"
                    }*/
                })
            } else {
                print("Image does not exist at \(imageURL)")
            }
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