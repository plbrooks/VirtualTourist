import UIKit

/**
 * Person.swift
 *
 * Person is a subclass of NSManagedObject. You will be modifying the Person class in the
 * "Plain Favorite Actors" Project so that it matches this file.
 *
 * There are 5 changes to be made. They are listed below, and called out in comments in the
 * code.
 *
 * 1. Import Core Data
 * 2. Make Person a subclass of NSManagedObject
 * 3. Add @NSManaged in front of each of the properties/attributes
 * 4. Include the standard Core Data init method, which inserts the object into a context
 * 5. Write an init method that takes a dictionary and a context. This is the biggest change to the class
 */
 
 // 1. Import CoreData
import CoreData

// 2. Make Person a subclass of NSManagedObject
class Photo : NSManagedObject {
    
    struct Keys {
        static let Imagepath = "imagepath"
        static let Pin = "pin"
    }
    
   var photoPath = ""
    
    // 3. We are promoting these four from simple properties, to Core Data attributes
     @NSManaged var imagepath: String
     //@NSManaged var pin: Pin?
     @NSManaged var pin: NSManagedObject
    
    // 4. Include this standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /**
     * 5. The two argument init method
     *
     * The Two argument Init method. The method has two goals:
     *  - insert the new Person into a Core Data Managed Object Context
     *  - initialze the Person's properties from a dictionary
     */
    
    init(usingPhotoPath: String) {
        self.photoPath = usingPhotoPath
    }

    
    var photoImage: UIImage? {
        
        get {
            return Caches.imageCache.imageWithIdentifier(photoPath)
        }
        
        set {
            Caches.imageCache.storeImage(newValue, withIdentifier: photoPath)
        }
        
    }
    
    
    struct Caches {
        static let imageCache = ImageCache()
    }

    
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Person" type.  This is an object that contains
        // the information from the Model.xcdatamodeld file. We will talk about this file in
        // Lesson 4.
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Person class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the
        // dictionary. This works in the same way that it did before we started on Core Data
    
        imagepath = dictionary[Keys.Imagepath] as! String
        pin = dictionary[Keys.Pin] as! Pin
    }
    func save(imageAtURL: NSURL, named: String) {
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        /*if let image = UIImage(data: imageData) {
            let fileURL = documentsURL.URLByAppendingPathComponent(named+".png")
            if let pngImageData = UIImagePNGRepresentation(image) {
                pngImageData.writeToURL(fileURL, atomically: false)
            }
        }*/
    }
    
    // MARK: - Helper
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }

}
