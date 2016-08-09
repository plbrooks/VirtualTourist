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
 * 2. Make Phont a subclass of NSManagedObject
 * 3. Add @NSManaged in front of each of the properties/attributes
 * 4. Include the standard Core Data init method, which inserts the object into a context
 * 5. Write an init method that takes a dictionary and a context. This is the biggest change to the class
 */
 
 // 1. Import CoreData
import CoreData

// 2. Make Person a subclass of NSManagedObject
class Photo : NSManagedObject {
    
    struct Keys {
        static let Key = "key"
        static let ImageData = "imagedata"
        static let Pin = "pin"
    }
    
    // 3. We are promoting these four from simple properties, to Core Data attributes
     @NSManaged var key: String
     @NSManaged var imageData: NSData?
     @NSManaged var pin: Pin
     //@NSManaged var pin: NSManagedObject
    
    // 4. Include this standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /**
     * 5. The two argument init method
     *
     * The Two argument Init method. The method has two goals:
     *  - insert the new Photo into a Core Data Managed Object Context
     *  - initialze the Photo's properties from a dictionary
     */
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        key = dictionary[Keys.Key] as! String
        //let image = dictionary[Keys.Image] as! UIImage
        //imageData = UIImagePNGRepresentation(image!)!
        if dictionary[Keys.ImageData] != nil {
            imageData = dictionary[Keys.ImageData] as? NSData
        }
        pin = dictionary[Keys.Pin] as! Pin
        
    }
    
    /*var image: UIImage? {
        
        get {
            return UIImage(data:imageData)
        }
        
        /*set {
            imageData = UIImagePNGRepresentation(image!)!*/
        }
    }*/
    
   
}
