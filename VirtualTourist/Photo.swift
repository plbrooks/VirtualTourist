import UIKit

import CoreData

class Photo : NSManagedObject {
    
    struct Keys {
        static let Key = "key"
        static let ImageData = "imagedata"
        static let Pin = "pin"
    }
    
     @NSManaged var key: String
     @NSManaged var imageData: NSData?
     @NSManaged var pin: Pin
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        key = dictionary[Keys.Key] as! String
        if dictionary[Keys.ImageData] != nil {
            imageData = dictionary[Keys.ImageData] as? NSData
        }
        pin = dictionary[Keys.Pin] as! Pin
        
    }
    
}
