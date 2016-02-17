//
//  Constants.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/5/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import Foundation

class Constants: NSObject {
    
    static let databaseName = "VirtualTourist.sqlite"
    static let maxNumOfPhotos = 10
    
    static let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let fileURL: NSURL = documentsDirectoryURL.URLByAppendingPathComponent("VirtualTourist")

    
    struct modelURL {
        static let name = "Model"
        static let ext = "momd"
    }
    
    struct FlickrAPI {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "91fa377fa025f51690767e7a17734e7d"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let PER_PAGE = "500"
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
        static let methodArguments: [String: AnyObject!] = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
    }
 
    
    
    
    
}
