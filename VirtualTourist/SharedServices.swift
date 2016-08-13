//
//  SharedServices.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/5/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//


import Foundation
import UIKit
import MapKit


    // MARK: All non-network shared services

class SharedServices: NSObject {
    static let sharedInstance = SharedServices()    // set up shared instance class
    private override init() {}                      // ensure noone will init

    
    // MARK: Error Processing
    // Convert error codes to error messages. Add in variable text as needed.
    
    func errorMessage(err: ErrorType) -> String {
        
        var errMessage = ""
        
        switch err {
        
        case Status.codeIs.accessSavedData (let code, let text):
            errMessage = Status.textIs.accessSavedData
            errMessage = substituteKeyInString(errMessage, key: "STATUSCODE", value: String(code))!
            errMessage = substituteKeyInString(errMessage, key: "TEXT", value: text)!
        
        case Status.codeIs.noFlickrDataReturned:
            errMessage = Status.textIs.noFlickrDataReturned
            
        case Status.codeIs.couldNotParseData:
            errMessage = Status.textIs.couldNotParseData
        case Status.codeIs.pinNotFound:
            errMessage = Status.textIs.pinNotFound
            
        case Status.codeIs.flickrStatus(let statusCode):
            errMessage = Status.textIs.flickrStatus
            errMessage = substituteKeyInString(errMessage, key: "STATUSCODE", value: String(statusCode))!

        case Status.codeIs.network(let type, let error):
            errMessage = Status.textIs.network
            errMessage = substituteKeyInString(errMessage, key: "TYPE", value: type)!
            errMessage = substituteKeyInString(errMessage, key: "STATUSCODE", value: String(error.code))!
            errMessage = substituteKeyInString(errMessage, key: "TEXT", value: error.localizedDescription)!
            
        case Status.codeIs.nserror(let type, let error):
            errMessage = Status.textIs.nserror
            errMessage = substituteKeyInString(errMessage, key: "TYPE", value: type)!
            errMessage = substituteKeyInString(errMessage, key: "STATUSCODE", value: String(error.code))!
            errMessage = substituteKeyInString(errMessage, key: "TEXT", value: error.localizedDescription)!
      
        default:    // no error
            errMessage = Status.textIs.noError
        }
        return errMessage
    
    }
    

    //  Update a string STRING by replacing contents KEY that is found in the string with the contents VALUE
    
    func substituteKeyInString(string: String, key: String, value: String) -> String? {
        if (string.rangeOfString(key) != nil) {
            return string.stringByReplacingOccurrencesOfString(key, withString: value)
        } else {
            return string
        }
    }
    
    
    // Show an alert. Message is from mesasge list in the common "Status" file  
    
    func showAlert (error: ErrorType, title: String) {
        let vc = presentingVC()
        let message = SharedMethod.errorMessage(error)
        let alertView = UIAlertController(title: title,
            message: message, preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertView.addAction(OKAction)
        if vc!.presentedViewController == nil {
            dispatch_async(dispatch_get_main_queue(), {
                vc!.presentViewController(alertView, animated: true, completion: nil)
            })
        }
    }

    // MARK: Map activity indicator setup

   func setActivityIndicator(option: String, mapView: MKMapView, activityIndicator: UIActivityIndicatorView ) {
        switch(option) {
        case "START":
            mapView.alpha = 0.25
            activityIndicator.startAnimating()
            activityIndicator.hidden = false
        default:    // FINISH
            mapView.alpha = 1.0
            activityIndicator.stopAnimating()
            activityIndicator.hidden = true
            
        }
    }
    
    // MARK: Find current VC
    // Used in func ShowAlert to get the present VC
    
    func  presentingVC() -> UIViewController? {
        var topController = UIApplication.sharedApplication().keyWindow?.rootViewController
        if topController != nil {
            while let presentedViewController = topController!.presentedViewController {
                topController = presentedViewController
            }
        }
        return topController
    }
    
    

}