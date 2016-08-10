//
//  SharedServices.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/5/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import Foundation
import UIKit


/********************************************************************************************************
 * Common general methods used across VCs                                                               *
 ********************************************************************************************************/
class SharedServices: NSObject {
    static let sharedInstance = SharedServices()    // set up shared instance class
    private override init() {}                      // ensure noone will init

    
    /********************************************************************************************************
    * Find the current VC. Used in classes such as CoreDataStackManager to send Alert to the presenting VC  *
    ********************************************************************************************************/
    func  presentingVC() -> UIViewController? {
        var topController = UIApplication.sharedApplication().keyWindow?.rootViewController
        if topController != nil {
            while let presentedViewController = topController!.presentedViewController {
                topController = presentedViewController
            }
        }
    return topController
    }
    
    /********************************************************************************************************
    * Convert error codes to error messages. Add in variable text as needed.                               *
    ********************************************************************************************************/
    func errorMessage(err: ErrorType) -> String {
        var errMessage = ""
        switch err {
        case Status.codeIs.accessSavedData (let code, let text):
            errMessage = substituteKeyInString(Status.textIs.accessSavedData, key: "STATUSCODE", value: String(code))!
            errMessage = substituteKeyInString(errMessage, key: "TEXT", value: text)!
        case Status.codeIs.saveContext (let code, let text):
            errMessage = substituteKeyInString(Status.textIs.saveContext, key: "STATUSCODE", value: String(code))!
            errMessage = substituteKeyInString(errMessage, key: "TEXT", value: text)!
        case Status.codeIs.flickrError(let type, let code, let text):
            errMessage = substituteKeyInString(Status.textIs.flickrError, key: "TYPE", value: String(type))!
            errMessage = substituteKeyInString(errMessage, key: "STATUSCODE", value: String(code))!
            errMessage = substituteKeyInString(errMessage, key: "TEXT", value: text)!
        case Status.codeIs.fetchError(let error):
            errMessage = substituteKeyInString(Status.textIs.fetchError, key: "STATUSCODE", value: String(error.code))!
            errMessage = substituteKeyInString(Status.textIs.fetchError, key: "TEXT", value: error.localizedDescription)!
        default:    // no error
            errMessage = Status.textIs.noError
        }
        return errMessage
    }
    
    /********************************************************************************************************
     * Update a string STRING by replacing contents KEY that is found in the string with the contents VALUE *
     ********************************************************************************************************/
    func substituteKeyInString(string: String, key: String, value: String) -> String? {
        if (string.rangeOfString(key) != nil) {
            return string.stringByReplacingOccurrencesOfString(key, withString: value)
        } else {
            return string
        }
    }
    
    /********************************************************************************************************
     * Show an alert. Message is from mesasge list in the common "Status" file                           *
     ********************************************************************************************************/
    func showAlert (error: ErrorType, title: String, viewController: UIViewController) {
        let message = SharedMethod.errorMessage(error)
        let alertView = UIAlertController(title: title,
            message: message, preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertView.addAction(OKAction)
        dispatch_async(dispatch_get_main_queue(), {
            viewController.presentViewController(alertView, animated: true, completion: nil)
        })
    }



}