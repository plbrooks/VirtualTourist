//
//  SharedMethod.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/5/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

class SharedMethod {
    
    /********************************************************************************************************
     * Shared instance constants used to improve readability in methods                                     *
     ********************************************************************************************************/
    
    static let  applicationDocumentsDirectory    = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
    static let  errorMessage                    =   SharedServices.sharedInstance.errorMessage
    static let  getPageNumberFlickr             =   SharedNetworkServices.sharedInstance.getPageFromFlickr
    static let  presentingVC                    =   SharedServices.sharedInstance.presentingVC
    static let  imageCache                      =   ImageCache.sharedInstance
    static let  showAlert                       =   SharedServices.sharedInstance.showAlert
    
}