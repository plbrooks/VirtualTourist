//
//  Status.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/5/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//
import Foundation

class Status: NSObject {
    
    /****************************************************************************************************************
     * Various statuses (good and bad) that can occur plus variable fields used to create the totals status msgs    *
     ****************************************************************************************************************/
    enum codeIs: ErrorType {
        case noError
        case accessSavedData        (code: Int, text: String)
        case saveContext            (code: Int, text: String)
        case flickrError             (code: Int, text: String)
    }
    
    /****************************************************************************************************************
     * Text for various statuses plus variable fields (CAPS) used to create the total status msg                    *
     ****************************************************************************************************************/
    struct textIs {
        static let noError          =       ""
        static let accessSavedData  =       "Oops - error loading or accessing saved data. Status code = STATUSCODE description = TEXT"
        static let saveContext      =       "Oops - error saving context. Status code = STATUSCODE description = TEXT"
        static let flickrError      =        "Oops - error acessing Flickr photos. Status code = STATUSCODE description = TEXT"
        
    }
}
