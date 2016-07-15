//
//  AlbumPhoto.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/7/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import Foundation
import UIKit

class AlbumPhoto: NSObject {
    static let sharedInstance = AlbumPhoto()    // set up shared instance class
    private override init() {}                      // ensure noone will init
    
    var usingFilename = ""
    var image: UIImage? {
        
        // FIX GET
        
        get {
            //return Caches.imageCache.imageWithIdentifier(photoPath)
            print("in get")
            var imageData: NSData? = nil
            if (usingFilename != "") {
                do {
                    let fileManager = NSFileManager.defaultManager()
                    let documentsURL = try fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
                    //let folderURL = documentsURL
                    if documentsURL.checkPromisedItemIsReachableAndReturnError(nil) {   // file found
                        imageData = NSData(contentsOfURL: documentsURL)
                    }
                    //let fileURL = documentsURL.URLByAppendingPathComponent(usingFilename)
                    print("getting documentsURL = \(documentsURL)")
                } catch let error as NSError {
                    Status.codeIs.flickrError(type: "writing Photos to disk", code: error.code, text: error.localizedDescription)
                    print("Error - \(error.localizedDescription)")
                }
            }
            return (UIImage(data: imageData!))
        }
        
        set {
            //http://stackoverflow.com/questions/27042875/ios-uiimagepngrepresentation-writetofile-not-writing-to-intended-directory
            
            if (newValue) != nil {
                let imageData = UIImagePNGRepresentation(newValue!)
                //let subfolder = "SubDirectory"
                
                do {
                    let fileManager = NSFileManager.defaultManager()
                    let documentsURL = try fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
                    //let folderURL = documentsURL
                    if !documentsURL.checkPromisedItemIsReachableAndReturnError(nil) {
                        try fileManager.createDirectoryAtURL(documentsURL, withIntermediateDirectories: true, attributes: nil)
                    }
                    let fileURL = documentsURL.URLByAppendingPathComponent(usingFilename)
                    print("saving documentsURL = \(documentsURL)")
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