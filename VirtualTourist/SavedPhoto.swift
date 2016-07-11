//
//  SavedPhoto.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/7/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import Foundation
import UIKit

class SavedPhoto: NSObject {
    static let sharedInstance = SavedPhoto()    // set up shared instance class
    private override init() {}                      // ensure noone will init
    
    var usingPath = ""
    var image: UIImage? {
        
        // FIX GET
        
        get {
            let a: UIImage? = nil
            //return Caches.imageCache.imageWithIdentifier(photoPath)
            print("in get")
            return (a)
        }
        
        set {
            //http://stackoverflow.com/questions/27042875/ios-uiimagepngrepresentation-writetofile-not-writing-to-intended-directory
            
            if (newValue) != nil {
                let imageData = UIImagePNGRepresentation(newValue!)
                let filename = usingPath
                //let subfolder = "SubDirectory"
                
                do {
                    let fileManager = NSFileManager.defaultManager()
                    let documentsURL = try fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
                    let folderURL = documentsURL
                    if !folderURL.checkPromisedItemIsReachableAndReturnError(nil) {
                        try fileManager.createDirectoryAtURL(folderURL, withIntermediateDirectories: true, attributes: nil)
                    }
                    let fileURL = folderURL.URLByAppendingPathComponent(filename)
                    print("fileURL = \(fileURL)")
                    try imageData!.writeToURL(fileURL, options: .AtomicWrite)
                } catch let error as NSError {
                    Status.codeIs.flickrError(type: "writing Photos to disk", code: error.code, text: error.localizedDescription)
                    print("Error - \(error.localizedDescription)")
                }
                
 
                /*let data = UIImagePNGRepresentation(newValue!)
                let path = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory.URLByAppendingPathComponent(usingPath)
                let pathString = String(path)
                do {
                    print("pathString = \(pathString)")
                    print("usingPath = \(usingPath)")
                    let _ = try Bool(data!.writeToFile(pathString, options: NSDataWritingOptions.DataWritingAtomic))
                    print("file saved")
                } catch let error as NSError {
                    Status.codeIs.flickrError(type: "writing Photos to disk", code: error.code, text: error.localizedDescription)
                    print("Error - \(error.localizedDescription)")
                }*/
            }
        }
    }






}