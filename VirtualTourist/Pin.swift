import UIKit
import CoreData
import Foundation

class Pin : NSManagedObject {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let numOfPages = "numOfPages"
    }
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var numOfPages: NSNumber
    @NSManaged var photos: [Photo]
   
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        latitude = dictionary[Keys.Latitude] as! NSNumber
        longitude = dictionary[Keys.Longitude] as! NSNumber
        if (dictionary[Keys.numOfPages] == nil) || (dictionary[Keys.numOfPages] as! NSNumber == 0) {
            numOfPages = 1
        } else {
            numOfPages = dictionary[Keys.numOfPages] as! NSNumber
        }
    
    }
    
}


