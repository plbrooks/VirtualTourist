//
//  Status.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/5/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//
import Foundation

class Status: NSObject {
    
    
    // Various statuses (good and bad) that can occur plus variable fields used to create the totals status msgs 
    
    enum codeIs: ErrorType {
        case noError
        case accessSavedData            (code: Int, text: String)
        case nserror                    (type: String, error: NSError)
        case noFlickrDataReturned
        case couldNotParseData
        case couldNotFindKey            (type: String)
        case network                    (type: String, error: NSError)
        case flickrStatus               (statusCode: Int)
        case pinNotFound
    
    }
    
    
    // Text for various statuses plus variable fields (CAPS) used to create the total status msg
    
    struct textIs {
        static let noError                  =   ""
        
        static let accessSavedData      =   "Oops - error loading or accessing saved data. Status code = STATUSCODE description = TEXT. Database may need to be updated?"
        static let  nserror                 =   "Oops - TYPE. Error code = STATUSCODE description = TEXT."
        static let  noFlickrDataReturned    =   "Oops - No Flickr data returned. Please try again later."
        static let  couldNotParseData       =   "Oops - Flickr data can not be parsed. Please try again later."
        static let  couldNotFindKey         =   "Oops - Could not find TYPE key. Please try again later."
        static let  network             =   "Oops - Please check your network connection. TYPE Code = STATUSCODE, description = TEXT."
        static let flickrStatus             =   "Oops - flickr error, flickr statuscode = STATUSCODE. Please try again later."
        static let pinNotFound              =   "Oops - Pin can not be retrieved. Please try again later."
        
    }

    
    // Text for various "types" of NSErrors
    
    struct ErrorTypeIs {
        static let savingPhotos         =   "error saving photos."
        static let flickr               =   "Flickr error."
        static let pinError             =   "error getting pin(s) from database."
        static let photoError           =   "error getting photo(s) from database."
        
    }
    
}
