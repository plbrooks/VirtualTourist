//
//  GlobalVar.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 8/9/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import Foundation

class GlobalVar: NSObject {
    static let sharedInstance = GlobalVar()    // set up shared instance class
    private override init() {}
    
    var photosDownloadIsInProcess = false
    
    
}