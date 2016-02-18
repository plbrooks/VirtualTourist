//
//  CoreDataStackManager.swift
//  VirtualTourist
//
//  Created by Peter Brooks on 2/2/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/********************************************************************************************************************
 * The CoreDataStackManager contains the the fundamental CoreData code                                              *
 *******************************************************************************************************************/

private let SQLITE_FILE_NAME = Constants.databaseName           // database name

class CoreDataStackManager: NSObject {
    static let sharedInstance = CoreDataStackManager()          // set up shared instance class
    private override init() {}                                  // ensure noone will init
    
    // MARK: - Managed Object Model Processing
    
    /****************************************************************************************************************
     *  Instantiate the applicationDocumentsDirectory property                                                      *
     ****************************************************************************************************************/
    lazy var applicationDocumentsDirectory: NSURL = {
        print("Instantiating the applicationDocumentsDirectory property")
        //let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        //return urls[urls.count-1]
        return urls
    }()
    
    /****************************************************************************************************************
     * The managed object model for the application. This property is not optional.                                 *
     * It is a fatal error for the application not to be able to find and load its model.                           *
     ****************************************************************************************************************/
    lazy var managedObjectModel: NSManagedObjectModel = {
        print("Instantiating the managedObjectModel property")
        let modelURL = NSBundle.mainBundle().URLForResource(Constants.modelURL.name, withExtension: Constants.modelURL.ext)!
        //let modelURL = NSURL(string:"file:///Users/Peter/Desktop/Model.momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    /********************************************************************************************************************************
     * The Persistent Store Coordinator is an object that the Context uses to interact with the underlying file system. Usually     *
     * the persistent store coordinator object uses an SQLite database file to save the managed objects. But it is possible to      *
     * configure it to use XML or other formats.                                                                                    *
     *                                                                                                                              *
     * Typically you will construct your persistent store manager exactly like this. It needs two pieces of information in order    *
     * to be set up:                                                                                                                *
     *                                                                                                                              *
     * - The path to the sqlite file that will be used. Usually in the documents directory                                          *
     * - A configured Managed Object Model. See the next property for details.                                                      *
     ********************************************************************************************************************************/
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        print("Instantiating the persistentStoreCoordinator property")
        
        let coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        //let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
        let url = NSURL(string: "file:///Users/Peter/Desktop/VirtualTourist.sqlite")!
        print("sqlite path: \(url.path!)")
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch let error as NSError {
            SharedMethod.showAlert(Status.codeIs.accessSavedData(code: error.code, text:error.localizedDescription), title: "Error", viewController: SharedMethod.presentingVC()!)
        }
        return coordinator
    }()
    // MARK: - Managed Object Context Processing
    
    /****************************************************************************************************************
     * Returns the managed object context for the application (which is already bound to the persistent             *
     * store coordinator for the application.) This property is optional since there are legitimate error           *
     * conditions that could cause the creation of the context to fail.                                             *
     ****************************************************************************************************************/
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    /****************************************************************************************************************
    * Save the managed object context for the application                                                           *
    ****************************************************************************************************************/
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch let error as NSError{
                SharedMethod.showAlert(Status.codeIs.accessSavedData(code: error.code, text:error.localizedDescription), title: "Error", viewController: SharedMethod.presentingVC()!)
            }
        }
    }

}



