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
    static let notificationKey = "PhotoCount"
    // make sure flickr will return less than 4000 photos else will get duplicate photos for different pages
    static let maxPageNumFromFlickr = Int(4000/21)
    
    struct modelURL {
        static let name = "Model"
        static let ext = "momd"
    }
    
    struct FlickrAPI {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        // Bounding Box parameters
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
        
        
        // PAGE processing:
        //  Initial flickr request for a pin - use page # 1. Save into the Pin entity the "pages" quantity
        //  After the initial request - use "pages" previously stored in "Pin". Update the Pin entity "pages" quantity from the new response.
        
        static let methodArguments: [String: AnyObject!] = [
            "method": "flickr.photos.search",
            "api_key": "91fa377fa025f51690767e7a17734e7d",
            "safe_search": "1",
            "extras": "url_m",
            "format": "json",
            "nojsoncallback": "1",
            "bbox": "1.0,2.0,3.0,4.4",  // string of the lat / longitude of the 2 bottom-left and top-right corners
            "page": 1,                  // page to be returned
            "per_page": 21
        ]
    }
    
}
