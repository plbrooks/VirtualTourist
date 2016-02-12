//
//  SavedPhoto.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/7/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import Foundation
import UIKit

class SavedPhoto: NSObject, NSCoding {
    
    var photo: UIImage?
    
    struct PropertyKey {
        static let savedPhotoKey = "savedPhotoKey"
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(photo, forKey: PropertyKey.savedPhotoKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let photo = aDecoder.decodeObjectForKey(PropertyKey.savedPhotoKey) as? UIImage
        
        // Must call designated initilizer.
        self.init(photo: photo)
    }
    
    init?(photo: UIImage?) {
        // Initialize stored properties.
        self.photo = photo
        super.init()
    }
    
    // MARK: Archiving Paths
    
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent("Photo") // NEED TO CHANGE
    
}