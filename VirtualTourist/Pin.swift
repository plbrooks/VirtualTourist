import CoreData

class Pin : NSManagedObject {
    
    // Keys of dict used to create new Pin
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let numOfPages = "numOfPages"
    }
    
    // Pin vars
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var numOfPages: NSNumber
    @NSManaged var photos: [Photo]
   
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    
    }
    
    // create Pin processing
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        latitude = dictionary[Keys.Latitude] as! NSNumber
        longitude = dictionary[Keys.Longitude] as! NSNumber
        if (dictionary[Keys.numOfPages] == nil) || (dictionary[Keys.numOfPages] as! NSNumber == 0) {
            numOfPages = 1  // default to page 1
        } else {
            numOfPages = dictionary[Keys.numOfPages] as! NSNumber   // use value from dictionary
        }
    
    }
    
}


