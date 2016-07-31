//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/2/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit

class ImageCache: NSObject {
    
    static let sharedInstance = ImageCache()    // set up shared instance class
        private override init() {}                      // ensure noone will init*/
    
    private var inMemoryCache = NSCache()
    
    // MARK: - Retreiving images
    
    func imageWithKey(key: String?) -> UIImage? {
        
        // If the identifier is nil, or empty, return nil
        if key != "" {
            if let image = inMemoryCache.objectForKey(key!) as? UIImage {
                return image
            }
        }
        return nil
    }
    
    // MARK: - Saving images
    
    func storeImage(image: UIImage, withKey: String, forPin: Pin) {
        
        // Otherwise, keep the image in memory
        inMemoryCache.setObject(image, forKey: withKey)
        
    }
    
    // MARK: - Helper
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }
}